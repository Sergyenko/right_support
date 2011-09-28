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
  # the simplicity and ease of use of RestClient's simple, static (class-level) interface.
  #
  # Even though this code relies on RestClient, the right_support gem does not depend on the rest-client
  # gem because not all users of right_support will want to make use of this interface. If one of HTTPClient
  # instance's method is called and RestClient is not available, an exception will be raised.
  #
  #
  # HTTPClient supports a subset of the module methods provided by RestClient and is interface-compatible
  # with those methods it replaces; the only difference is that the HTTPClient version of each method accepts an
  # additional, optional parameter which is a request timeout in seconds. The RestClient gem does not allow
  # timeouts without instantiating a "heavyweight" HTTPClient object.
  #
  #   # create an instance ot HTTPClient
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
    
    def initialize(options = {})
      [:get, :post, :put, :delete].each do |method|
         define_instance_method(method) {|*args| query(method, *args)}
      end
    end

    protected
    
    # Helps to add default methods to class
    def define_instance_method(method, &block)
      (class << self; self; end).module_eval do
        define_method(method, &block)
      end
    end
      
    def query(type, url, options={}, &block)
      options[:timeout]       ||= DEFAULT_TIMEOUT
      options[:open_timeout]  ||= DEFAULT_OPEN_TIMEOUT
      options[:headers]       ||= {}
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
  end# HTTPClient
end
