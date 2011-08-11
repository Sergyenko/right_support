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
  # *  * on success: remain green
  #    * on failure: change state to red
  # * red: skip this server
  # *  * after @reset_time passes,
  class HealthCheck
    def initialize(max_failures=0, reset_time=300)
      @max_failures = max_failures
      @reset_time = reset_time
      @red = Hash.new # endpoint -> time it became red
    end

    def next(endpoints)
      endpoints.first #this is not very balanced!!
    end

    def good(endpoint, t0, t1)
    end

    def bad(endpoint, t0, t1)
    end
  end
end