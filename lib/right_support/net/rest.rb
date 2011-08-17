module RightSupport::Net
  if_require_succeeds('right_http_connection') do
    #nothing, nothing at all! just need to make sure
    #that RightHttpConnection gets loaded before
    #rest-client, so the Net::HTTP monkey patches
    #take effect.
  end

  if_require_succeeds('restclient') do
    HAS_REST_CLIENT = true
  end

  # Raised to indicate that no suitable provider of REST/HTTP services was found. Since RightSupport's
  # REST support is merely a wrapper around other libraries, it cannot work in isolation. See the REST
  # module for more information about supported providers.
  class NoProvider < Exception; end

  #
  # A wrapper for the rest-client gem that provides timeouts and other useful features while preserving
  # the simplicity and ease of use of RestClient's simple, static (module-level) interface.
  #
  # Even though this code relies on RestClient, the right_support gem does not depend on the rest-client
  # gem because not all users of right_support will want to make use of this interface. If one of REST's
  # method is called and RestClient is not available, an exception will be raised.
  #
  #
  # This module supports a subset of the module methods provided by RestClient and is interface-compatible
  # with those methods it replaces; the only difference is that the REST version of each method accepts an
  # additional, optional parameter which is a request timeout in seconds. The RestClient gem does not allow
  # timeouts without instantiating a "heavyweight" REST client object.
  #
  #   # GET
  #   xml = REST.get 'http://example.com/resource'
  #   # and, with timeout of 5 seconds...
  #   jpg = REST.get 'http://example.com/resource', :accept => 'image/jpg', 5
  #
  #   # authentication and SSL
  #   REST.get 'https://user:password@example.com/private/resource'
  #
  #   # POST or PUT with a hash sends parameters as a urlencoded form body
  #   REST.post 'http://example.com/resource', :param1 => 'one'
  #
  #   # nest hash parameters, add a timeout of 10 seconds (and specify "no extra headers")
  #   REST.post 'http://example.com/resource', :nested => { :param1 => 'one' }, {}, 10
  #
  #   # POST and PUT with raw payloads
  #   REST.post 'http://example.com/resource', 'the post body', :content_type => 'text/plain'
  #   REST.post 'http://example.com/resource.xml', xml_doc
  #   REST.put 'http://example.com/resource.pdf', File.read('my.pdf'), :content_type => 'application/pdf'
  #
  #   # DELETE
  #   REST.delete 'http://example.com/resource'
  #
  #   # retrieve the response http code and headers
  #   res = REST.get 'http://example.com/some.jpg'
  #   res.code                    # => 200
  #   res.headers[:content_type]  # => 'image/jpg'
  module REST
    DEFAULT_TIMEOUT = 5
    
    class << self
      # Wrapper around RestClient.get -- see class documentation for details.
      def get(url, options={}, &block)
        query(:get, url, options, &block)
      end
      
      # Wrapper around RestClient.get -- see class documentation for details.
      def post(url, payload, headers={}, timeout=DEFAULT_TIMEOUT, &block)
        request(:method=>:post, :url=>url, :payload=>payload,
                :timeout=>timeout, :headers=>headers, &block)
      end

      # Wrapper around RestClient.get -- see class documentation for details.
      def put(url, payload, headers={}, timeout=DEFAULT_TIMEOUT, &block)
        request(:method=>:put, :url=>url, :payload=>payload,
                :timeout=>timeout, :headers=>headers, &block)
      end

      # Wrapper around RestClient.get -- see class documentation for details.
      def delete(url, headers={}, timeout=DEFAULT_TIMEOUT, &block)
        request(:method=>:delete, :url=>url, :timeout=>timeout, :headers=>headers, &block)
      end
      
      protected 
      
      def query(type, url, options, &block)
        options[:timeout] ||= DEFAULT_TIMEOUT
        options[:headers] ||= {}
        options.merge!(:method => type, :url => url)
        request(options, &block)
      end

      # Wrapper around RestClient::Request.execute -- see class documentation for details.
      def request(options, &block)
        if HAS_REST_CLIENT
          RestClient::Request.execute(options, &block)
        else
          raise NoProvider, "Cannot find a suitable HTTP client library"
        end
      end
    end #class << self
  end
end
