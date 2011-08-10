module RightSupport::Net
  # Raised to indicate the (uncommon) error condition where a RequestBalancer rotated
  # through EVERY URL in a list without getting a non-nil, non-timeout response. 
  class NoResult < Exception; end
  
  #This module includes Load Balancing algorithms, which provides default set of functions
  #like a "next endpoint," "report good endpoint", "report bad endpoint" and etc
  module Policy
    #Every balancing algorithm should be wrapped by module with the same name
    module RoundRobin
      def next_endpoint
        @round_robin ||= 0
        result = @endpoints[ @round_robin % @endpoints.size ]
        @round_robin += 1
        return result
      end
    end
  end
  
  
  # Utility class that allows network requests to be randomly distributed across
  # a set of network endpoints. Generally used for REST requests by passing an
  # Array of HTTP service endpoint URLs.
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
    
    #You should include balancing algorithm
    include Policy::RoundRobin
    
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

    DEFAULT_OPTIONS = {
        :fatal        => DEFAULT_FATAL_PROC,
        :on_exception => nil
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
    # fatal(Class):: a class, list of classes or decision Proc to determine whether an exception is fatal and should not be retried
    # on_exception(Proc|Lambda):: notification hook that accepts three arguments: whether the exception is fatal, the exception itself, and the endpoint for which the exception happened
    #
    def initialize(endpoints, options={})
      @options = DEFAULT_OPTIONS.merge(options)

      unless endpoints && !endpoints.empty?
        raise ArgumentError, "Must specify at least one endpoint"
      end

      unless test_callable_arity(options[:fatal], 1, true)
        raise ArgumentError, ":fatal callback must accept one parameter"
      end

      unless test_callable_arity(options[:on_exception], 3, false)
        raise ArgumentError, ":on_exception callback must accept three parameters"
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

      while !complete && n < @endpoints.size
        endpoint = next_endpoint
        n += 1

        begin
          result   = yield(endpoint)
          complete = true
          break
        rescue Exception => e
          if to_raise = handle_exception(endpoint, e)
            raise(to_raise)
          else
            exceptions << e
          end
        end
      end

      return result if complete

      exceptions = exceptions.map { |e| e.class.name }.uniq.join(', ')
      raise NoResult, "All URLs in the rotation failed! Exceptions: #{exceptions}"
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

    # Test that something is a callable (Proc, Lambda or similar) with the expected arity.
    # Used mainly by the initializer to test for correct options.
    def test_callable_arity(callable, arity, optional)
      return true if callable.nil?
      return true if optional && !callable.respond_to?(:call)
      return callable.respond_to?(:arity) && (callable.arity == arity)
    end
  end # RequestBalancer

end # RightScale
