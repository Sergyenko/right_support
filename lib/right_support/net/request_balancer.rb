module RightSupport::Net
  # Raised to indicate the (uncommon) error condition where a RequestBalancer rotated
  # through EVERY URL in a list without getting a non-nil, non-timeout response. 
  class NoResponse < Exception; end

  # Utility class that allows network requests to be randomly distributed across
  # a set of network endpoints. Generally used for REST requests by passing an
  # Array of HTTP service endpoint URLs.
  #
  # The balancer does not actually perform requests by itself, which makes this
  # class usable for various network protocols, and potentially even for non-
  # networking purposes. The block does all the work; the balancer merely selects
  # a random request endpoint to pass to the block.
  class RequestBalancer
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
    # fatal(Class):: a subclass of Exception that is considered fatal and causes #request to re-raise immediately
    # safe(Class):: a subclass of :fatal that is considered "safe" even though its parent class is fatal
    def initialize(endpoints, options={})
      raise ArgumentError, "Must specify at least one endpoint" unless endpoints && !endpoints.empty?
      @endpoints = endpoints.shuffle
      @options = options.dup
    end

    # Perform a request
    #
    # === Block
    # This method requires a block, to which it yields in order to perform the actual network
    # request. If the block raises an exception or provides nil, the balancer proceeds to try
    # the next URL in the list.
    #
    # === Raise
    # ArgumentError:: if a block isn't supplied
    # NoResponse:: if *every* URL in the list times out or returns nil
    #
    # === Return
    # Return the first non-nil value provided by the block.
    def request
      raise ArgumentError, "Must call this method with a block" unless block_given?

      exception = nil
      result    = nil

      @endpoints.each do |host|
        begin
          result = yield(host)
          break unless result.nil?
        rescue Exception => e
          fatal = @options[:fatal]
          safe  = @options[:safe]
          raise e if (fatal && e.kind_of?(fatal)) && !(safe && e.kind_of?(safe))
          exception = e
        end
      end

      return result if result
      raise exception if exception
      raise NoResponse, "Tried all URLs with neither result nor exception!"
    end
  end # RequestBalancer

end # RightScale
