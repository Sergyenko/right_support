module RightSupport::Net
  if_require_succeeds('restclient') do
    HAS_REST_CLIENT = true
  end

  class NoProvider < Exception; end

  #
  # A wrapper for the rest-client gem that provides timeouts and other
  # useful features while preserving the simplicity and ease of use of
  # RestClient's simple, static (module-level) interface.
  #
  module REST
    DEFAULT_TIMEOUT = 5
    
    def self.get(url, headers={}, timeout=DEFAULT_TIMEOUT, &block)
      request(:method=>:get, :url=>url, :timeout=>timeout, :headers=>headers, &block)
    end

    def self.post(url, payload, headers={}, timeout=DEFAULT_TIMEOUT, &block)
      request(:method=>:post, :url=>url, :payload=>payload,
              :timeout=>timeout, :headers=>headers, &block)
    end

    def self.put(url, payload, headers={}, timeout=DEFAULT_TIMEOUT, &block)
      request(:method=>:put, :url=>url, :payload=>payload,
              :timeout=>timeout, :headers=>headers, &block)
    end

    def self.delete(url, headers={}, timeout=DEFAULT_TIMEOUT, &block)
      request(:method=>:delete, :url=>url, :timeout=>timeout, :headers=>headers, &block)
    end

    def self.request(options, &block)
      if HAS_REST_CLIENT
        RestClient::Request.execute(options, &block)
      else
        raise NoProvider, "Cannot find a suitable HTTP client library"
      end
    end

  end
end