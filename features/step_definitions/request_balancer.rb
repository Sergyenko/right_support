When /^a client makes a load-balanced request to '(.*)' with timeout (\d+)$/ do |path, timeout|
  @mock_servers.should_not be_nil
  @mock_servers.empty?.should be_false

  timeout = timeout.to_i
  urls = @mock_servers.map { |s| s.url }
  @request_balancer = RightSupport::Net::RequestBalancer.new(urls)
  @request_attempts = 0
  @request_t0 = Time.now
  begin
    @request_balancer.request do |url|
      @request_attempts += 1
      RightSupport::Net::REST.get("#{url}#{path}", {}, timeout)
    end
  rescue Exception => e
    @request_error = e
  end
  @request_t1 = Time.now
end

When /^a client makes a (buggy)? load-balanced request to '(.*)' with timeout (\d+)$/ do |buggy, path, timeout|
  buggy = !buggy.empty?

  @mock_servers.should_not be_nil
  @mock_servers.empty?.should be_false

  timeout = timeout.to_i
  urls = @mock_servers.map { |s| s.url }
  @request_balancer = RightSupport::Net::RequestBalancer.new(urls)
  @request_attempts = 0
  @request_t0 = Time.now
  begin
    @request_balancer.request do |url|
      @request_attempts += 1
      raise ArgumentError, "Fall down go boom!" if buggy
      RightSupport::Net::REST.get("#{url}#{path}", {}, timeout)
    end
  rescue Exception => e
    @request_error = e
  end
  @request_t1 = Time.now
end

Then /^the request should (\w+ ?\w*) in less than (\d+) seconds?$/ do |behavior, time|
  case behavior
    when 'complete'
      error_expected = false
    when 'raise'
      error_expected = true
    when /raise (\w+)/
      error_expected = true
      error_class_expected = /raise (\w+)/.match(behavior)[1]
    else
      raise ArgumentError, "Unknown request behavior #{behavior}"
  end

  #allow 5% margin of error due to Ruby/OS scheduler variance
  (@request_t1.to_f - @request_t0.to_f).should <= (time.to_f * 1.05)
  if !error_expected && @request_error
    puts '!' * 80
    puts @request_error.class.inspect
    puts @request_error.class.superclass.inspect
    puts '!' * 80
  end
  @request_error.should be_nil unless error_expected
  @request_error.should_not be_nil if error_expected
  @request_error.class.name.include?(error_class_expected).should be_true unless error_class_expected.nil?
  @request
end

Then /^the request should be attempted once$/ do
  @request_attempts.should == 1
end
