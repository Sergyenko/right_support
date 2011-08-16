module RightSupport::Net
  # Raised to indicate the (uncommon) error condition where a RequestBalancer rotated
  # through EVERY URL in a list without getting a non-nil, non-timeout response. 
  class NoResult < Exception; end
  
  # Utility class that allows network requests to be randomly distributed across
  # a set of network endpoints. Generally used for REST requests by passing an
  # Array of HTTP service endpoint URLs.
  #
  # Note that this class also serves as a namespace for endpoint selection policies,
  # which are classes that actually choose the next endpoint based on some criterion
  # (round-robin, health of endpoint, response time, etc).
  #
  # The balancer does not actually perform requests by itself, which makes this
  # class usable for various network protocols, and potentially even for non-
  # networking purposes. The block does all the work; the balancer merely selects
  # a random request endpoint to pass to the block.
  #
  # PLEASE NOTE that the request balancer has a rather dumb notion of what is considered
  # a "fatal" error for purposes of being able to retry; by default, it will consider
  # any StandardError or any RestClient::Exception whose code is between 400-499. This
  # MAY NOT BE SUFFICIENT for some uses of the request balancer! Please use the :fatal
  # option if you need different behavior.
  class RequestBalancer
    
    
    ###!!! Remove it as unusable
    # Require all of the built-in balancer policies that live in our namespace.
    #Dir[File.expand_path('../request_balancer/*.rb', __FILE__)].each do |file|
    #  require file
    #end

    DEFAULT_RETRY_PROC = lambda do |ep, n|
      n < ep.size
    end

    DEFAULT_FATAL_EXCEPTIONS = [ScriptError, ArgumentError, IndexError, LocalJumpError, NameError]

    DEFAULT_FATAL_PROC = lambda do |e|
      if DEFAULT_FATAL_EXCEPTIONS.any? { |c| e.is_a?(c) }
        #Some Ruby builtin exceptions indicate program errors
        true
      elsif e.respond_to?(:http_code) && (e.http_code != nil)
        #RestClient's exceptions all respond to http_code, allowing us
        #to decide based on the HTTP response code.
        #Any HTTP 4xx code EXCEPT 408 (Request Timeout) counts as fatal.
        (e.http_code >= 400 && e.http_code < 500) && (e.http_code != 408)
      else
        #Anything else counts as non-fatal
        false
      end
    end

    DEFAULT_HEALTH_CHECK_PROC = Proc.new do |endpoint|
      true
    end

    DEFAULT_OPTIONS = {
        :policy       => nil,
        :retry        => DEFAULT_RETRY_PROC,
        :fatal        => DEFAULT_FATAL_PROC,
        :on_exception => nil,
        :health_check => DEFAULT_HEALTH_CHECK_PROC
    }

    def self.request(endpoints, options={}, &block)
      new(endpoints, options).request(&block)
    end

    # Constructor. Accepts a sequence of request endpoints which it shuffles randomly at
    # creation time; however, the ordering of the endpoints does not change thereafter
    # and the sequence is tried from the beginning for every request.
    #
    # === Parameters
    # endpoints(Array):: a set of network endpoints (e.g. HTTP URLs) to be load-balanced
    #
    # === Options
    # retry:: a Class, array of Class or decision Proc to determine whether to keep retrying; default is to try all endpoints
    # fatal:: a Class, array of Class, or decision Proc to determine whether an exception is fatal and should not be retried
    # on_exception(Proc):: notification hook that accepts three arguments: whether the exception is fatal, the exception itself, and the endpoint for which the exception happened
    # health_check(Proc):: callback that allows balancer to check an endpoint health; should raise an exception if the endpoint is not healthy
    #
    def initialize(endpoints, options={})
      
      @options = DEFAULT_OPTIONS.merge(options)

      unless endpoints && !endpoints.empty?
        raise ArgumentError, "Must specify at least one endpoint"
      end

      @options[:policy] ||= RightSupport::Net::Balancing::RoundRobin
      @policy = @options[:policy]
      @policy = @policy.new(endpoints) if @policy.is_a?(Class)
      unless test_policy_duck_type(@policy)
        raise ArgumentError, ":policy must be a class/object that responds to :next, :good and :bad"
      end

      unless test_callable_arity(options[:retry], 2)
        raise ArgumentError, ":retry callback must accept two parameters"
      end

      unless test_callable_arity(options[:fatal], 1)
        raise ArgumentError, ":fatal callback must accept one parameter"
      end

      unless test_callable_arity(options[:on_exception], 3, false)
        raise ArgumentError, ":on_exception callback must accept three parameters"
      end

      unless test_callable_arity(options[:health_check], 1, false)
        raise ArgumentError, ":health_check callback must accept one parameters"
      end

      @endpoints = endpoints.shuffle
    end

    # Perform a request.
    #
    # === Block
    # This method requires a block, to which it yields in order to perform the actual network
    # request. If the block raises an exception or provides nil, the balancer proceeds to try
    # the next URL in the list.
    #
    # === Raise
    # ArgumentError:: if a block isn't supplied
    # NoResult:: if *every* URL in the list times out or returns nil
    #
    # === Return
    # Return the first non-nil value provided by the block.
    def request
      raise ArgumentError, "Must call this method with a block" unless block_given?

      exceptions = []
      result     = nil
      complete   = false
      n          = 0

      retry_opt     = @options[:retry] || DEFAULT_RETRY_PROC
      health_check  = @options[:health_check]
      
      while !complete
        
        endpoint, need_health_check  = @policy.next

        raise NoResult, "No endpoints are available" unless endpoint
        n += 1
        t0 = Time.now
        
        
        # TO DISCUSS:
        # Maybe, it would be more useful to make the HealthCheck as a part of the balancing algorithm?
        # HeathCheck goes here
        if need_health_check
          begin
            health_check.call(endpoint) ? @policy.good(endpoint, t0, Time.now) : @policy.bad(endpoint, t0, Time.now)
          rescue Exception => e
            @policy.bad(endpoint, t0, Time.now)
            next
          end
        end

        begin
          result   = yield(endpoint)
          # TO DISCUSS:
          # Do we need to send "good" at this place? Because, if we're using "green" 
          # we no need to make it more greener. As for "yellow" EP, we've already 
          # sent "good" after the health_check.
          #
          #@policy.good(endpoint, t0, Time.now)
          complete = true
          break
        rescue Exception => e
          @policy.bad(endpoint, t0, Time.now)
          if to_raise = handle_exception(endpoint, e)
            raise(to_raise)
          else
            exceptions << e
          end
        end

        unless complete
          max_n = retry_opt
          max_n = max_n.call(@endpoints, n) if max_n.respond_to?(:call)
          break if (max_n.is_a?(Integer) && n >= max_n) || !(max_n)
        end
      end

      return result if complete

      exceptions = exceptions.map { |e| e.class.name }.uniq.join(', ')
      raise NoResult, "No available endpoints from #{@endpoints.inspect}! Exceptions: #{exceptions}"
    end

    protected

    # Decide what to do with an exception. The decision is influenced by the :fatal
    # option passed to the constructor.
    def handle_exception(endpoint, e)
      fatal = @options[:fatal] || DEFAULT_FATAL_PROC

      #The option may be a proc or lambda; call it to get input
      fatal = fatal.call(e) if fatal.respond_to?(:call)

      #The options may be single exception classes, in which case we want to expand
      #it out into a list
      fatal = [fatal] if fatal.is_a?(Class)

      #The option may be a list of exception classes, in which case we want to evaluate
      #whether the exception we're handling is an instance of any mentioned exception
      #class
      fatal = fatal.any?{ |c| e.is_a?(c) } if fatal.respond_to?(:any?)

      @options[:on_exception].call(fatal, e, endpoint) if @options[:on_exception]

      if fatal
        #Final decision: did we identify it as fatal?
        return e
      else
        return nil
      end
    end

    def test_policy_duck_type(object)
      [:next, :good, :bad].all? { |m| object.respond_to?(m) }
    end

    # Test that something is a callable (Proc, Lambda or similar) with the expected arity.
    # Used mainly by the initializer to test for correct options.
    def test_callable_arity(callable, arity, optional=true)
      return true if callable.nil?
      return true if optional && !callable.respond_to?(:call)
      return callable.respond_to?(:arity) && (callable.arity == arity)
    end
  end # RequestBalancer

end # RightScale
