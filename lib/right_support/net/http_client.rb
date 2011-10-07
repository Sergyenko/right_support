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
  # A wrapper for the rest-client gem that provides timeouts that make it harder to misuse RestClient.
  #
  # Even though this code relies on RestClient, the right_support gem does not depend on the rest-client
  # gem because not all users of right_support will want to make use of this interface. If one of HTTPClient
  # instance's method is called and RestClient is not available, an exception will be raised.
  #
  #
  # HTTPClient is a thin wrapper around the RestClient::Request class, with a few minor changes to its
  # interface:
  #  * initializer accepts some default request options that can be overridden per-request
  #  * it has discrete methods for get/put/post/delete, instead of a single "request" method
  #
  #   # create an instance ot HTTPClient with some default request options
  #   @client = HTTPClient.new()
  #
  #   # GET
  #   xml = @client.get 'http://example.com/resource'
  #   # and, with timeout of 5 seconds...
  #   jpg = @client.get 'http://example.com/resource', {:accept => 'image/jpg', :timeout => 5}
  #
  #   # authentication and SSL
  #   @client.get 'https://user:password@example.com/private/resource'
  #
  #   # POST or PUT with a hash sends parameters as a urlencoded form body
  #   @client.post 'http://example.com/resource', {:param1 => 'one'}
  #
  #   # nest hash parameters, add a timeout of 10 seconds (and specify "no extra headers")
  #   @client.post 'http://example.com/resource', {:payload => {:nested => {:param1 => 'one'}}, :timeout => 10}
  #
  #   # POST and PUT with raw payloads
  #   @client.post 'http://example.com/resource', {:payload => 'the post body', :headers => {:content_type => 'text/plain'}}
  #   @client.post 'http://example.com/resource.xml', {:payload => xml_doc}
  #   @client.put 'http://example.com/resource.pdf', {:payload => File.read('my.pdf'), :headers => {:content_type => 'application/pdf'}}
  #
  #   # DELETE
  #   @client.delete 'http://example.com/resource'
  #
  #   # retrieve the response http code and headers
  #   res = @client.get 'http://example.com/some.jpg'
  #   res.code                    # => 200
  #   res.headers[:content_type]  # => 'image/jpg'
  class HTTPClient
    
    DEFAULT_TIMEOUT       = 5
    DEFAULT_OPEN_TIMEOUT  = 2
    
    def initialize(defaults = {})
      @defaults = defaults.clone
      @defaults[:timeout]      ||= DEFAULT_TIMEOUT
      @defaults[:open_timeout] ||= DEFAULT_OPEN_TIMEOUT
      @defaults[:headers]      ||= {}
    end

    def get(*args)
      request(:get, *args)
    end

    def post(*args)
      request(:post, *args)
    end

    def put(*args)
      request(:put, *args)
    end

    def delete(*args)
      request(:delete, *args)
    end

  # A very thin wrapper around RestClient::Request.execute.
  #
  # === Parameters
  # type(Symbol):: an HTTP verb, e.g. :get, :post, :put or :delete
  # url(String):: the URL to request, including any query-string parameters
  #
  # === Options
  # This method can accept any of the options that RestClient::Request can accept, since
  # all options are proxied through after merging in defaults, etc. Interesting options:
  # * :payload - hash containing the request body (e.g. POST or PUT parameters)
  # * :headers - hash containing additional HTTP request headers
  # * :cookies - will replace possible cookies in the :headers
  # * :user and :password - for basic auth, will be replaced by a user/password available in the url
  # * :raw_response - return a low-level RawResponse instead of a Response
  # * :verify_ssl - enable ssl verification, possible values are constants from OpenSSL::SSL
  # * :timeout and :open_timeout - specify overall request timeout + socket connect timeout
  # * :ssl_client_cert, :ssl_client_key, :ssl_ca_file
  #
  # === Block
  # If the request succeeds, this method will yield the response body to its block.
  #
    def request(type, url, options={}, &block)
      options = @defaults.merge(options)
      options.merge!(:method => type, :url => url)

      request_internal(options, &block)
    end

    protected
    
    # Wrapper around RestClient::Request.execute -- see class documentation for details.
    def request_internal(options, &block)
      if HAS_REST_CLIENT
        RestClient::Request.execute(options, &block)
      else
        raise NoProvider, "Cannot find a suitable HTTP client library"
      end
    end
  end# HTTPClient
end
