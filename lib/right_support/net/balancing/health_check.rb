#
# Copyright (c) 2011 RightScale Inc
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'set'

module RightSupport::Net::Balancing
  # TODO docs
  #
  # Implementation concepts: endpoints have two states, red and green. The balancer works
  # by avoiding "red" endpoints and retrying them after awhile. Here is a brief description
  # of the state transitions:
  # * green: last request was successful.
  #    * on success: remain green
  #    * on failure: change state to red
  # * red: skip this server
  #    * after @reset_time passes,
  class HealthCheck
    def initialize(max_failures=0, reset_time=300)
      @max_failures = max_failures
      @reset_time = reset_time
      @red = Hash.new # endpoint -> time it became red
      @counter = rand(0xffff)
    end

    def next(endpoints)
      @counter += 1
      green = endpoints - sweep_and_return_endpoints_from_hash(@red)
      
      #When all endpoints are red, the balancer should raise NoResult immediately, 
      #before trying any endpoint
      if green.size == 0
        @red.clear
        green = endpoints
      end
      
      green[@counter % green.size]
    end

    def good(endpoint, t0, t1)
    end

    def bad(endpoint, t0, t1)
      @red[endpoint] = {:t0 => t0, :t1 => t1}
    end
    
    protected
    
    def sweep(endpoints_hash)
      endpoints_hash.each do |endpoint,timestamps|
        endpoints_hash.delete(endpoint) if Time.now - timestamps[:t1] > @reset_time
      end
      endpoints_hash
    end
    
    def return_endpoints_from_hash(endpoints_hash)
      endpoints_hash.keys
    end
    
    def sweep_and_return_endpoints_from_hash(endpoints_hash)
      return_endpoints_from_hash sweep(endpoints_hash)
    end
  end
end
