module RightSupport::Net
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

    def initialize(endpoints, options={})
      raise ArgumentError, "Must specify at least one endpoint" unless endpoints && !endpoints.empty?
      @endpoints = endpoints.shuffle
      @options = options.dup
    end

    def request
      raise ArgumentError, "Must call this method with a block" unless block_given?

      exception = nil
      result    = nil

      @endpoints.each do |host|
        begin
          result = yield(host)
          break
        rescue Exception => e
          fatal     = @options[:fatal]
          raise e if fatal && e.kind_of?(fatal)
        end
      end

      return result if result
      raise exception if exception
      raise NoResponse, "Tried all URLs with neither result nor exception!"
    end
  end # RequestBalancer

end # RightScale
