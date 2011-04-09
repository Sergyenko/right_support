#--  -*- mode: ruby; encoding: utf-8 -*-
# Copyright: Copyright (c) 2011 RightScale, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# 'Software'), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'webrick'
require 'webrick/httpservlet'

class MockServer < WEBrick::HTTPServer
  attr_accessor :thread, :port, :url

  def initialize(options={})
    @port = options[:port] || (4096 + rand(4096))
    @url = "http://localhost:#{@port}"

    logger = WEBrick::Log.new(STDERR, WEBrick::Log::ERROR)    
    super(options.merge(:Port => @port, :AccessLog => [], :Logger=>logger))

    # mount servlets via callback
    yield(self)

    #Start listening for HTTP in a separate thread
    @thread = Thread.new do
      self.start()
    end
  end
end

Before do
  @mock_servers = []
end

# Kill running reposes after test finishes.
After do
  @mock_servers.each do |server|
    server.thread.kill
  end
end

Given /^(an?|\d+)? ([\w-]+) servers?$/ do |number, behavior|
  number = 0 if number =~ /no/
  number = 1 if number =~ /an?/
  number = number.to_i
  
  case behavior
    when 'well-behaved'
      proc = Proc.new do
        'Hi there! I am well-behaved.'
      end
    when 'faulty'
      proc = Proc.new do
        sleep(10)
        'Hi there! I am faulty.'
      end
    else
      raise ArgumentError, "Unknown server behavior #{behavior}"
  end

  number.times do
    server = MockServer.new do |s|
      s.mount('/', WEBrick::HTTPServlet::ProcHandler.new(proc))
    end

    @mock_servers << server
  end
end

When /a client makes a load-balanced request to '(.*)' with timeout (\d+)/ do |path, timeout|
  timeout = timeout.to_i
  urls = @mock_servers.map { |s| s.url }
  @request_balancer = RightSupport::Net::RequestBalancer.new(urls, :fatal=>Exception, :safe=>RestClient::RequestTimeout)
  @request_t0 = Time.now
  begin
    @request_balancer.request do |url|
      RightSupport::Net::REST.get("#{url}#{path}", {}, timeout)
    end
  rescue Exception => e
    @request_error = e
  end
  @request_t1 = Time.now
end

Then /the request should (\w+) in less than (\d+) seconds?/ do |behavior, time|
  case behavior
    when 'complete'
      error_expected = false
    when 'raise'
      error_expected = true
    else
      raise ArgumentError, "Unknown request behavior #{behavior}"
  end

  #allow 5% margin of error due to Ruby/OS scheduler variance
  (@request_t1.to_f - @request_t0.to_f).should <= (time.to_f * 1.05)
  @request_error.should be_nil unless error_expected
  @request_error.should_not be_nil if error_expected
end