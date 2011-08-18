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
  
  class EndpointsStack
    
    def initialize(endpoints, yellow_states=4, reset_time=300)
      @endpoints = Hash.new
      @yellow_states = yellow_states
      @reset_time = reset_time
      endpoints.each { |ep| @endpoints[ep] = {:n_level => 0,:timestamp => 0 }}
    end
    
    def sweep
      @endpoints.each { |k,v| decrease_state(k,0,Time.now) if Float(Time.now - v[:timestamp]) > @reset_time }
    end
    
    def sweep_and_return_yellow_and_green
      sweep
      @endpoints.select { |k,v| v[:n_level] < @yellow_states }
    end
    
    def decrease_state(endpoint,t0,t1)
      unless @endpoints[endpoint][:n_level] == 0
        @endpoints[endpoint][:n_level]    -= 1
        @endpoints[endpoint][:timestamp]  = t1
      end
    end
    
    def increase_state(endpoint,t0,t1)
      unless @endpoints[endpoint][:n_level] == @yellow_states
        @endpoints[endpoint][:n_level]    += 1
        @endpoints[endpoint][:timestamp]  = t1
      end
    end
    
  end
  
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
    
    def initialize(endpoints,options = {})
      yellow_states,reset_time, @health_check = options.delete(:yellow_states),options.delete(:reset_time),options.delete(:health_check)
      @stack = EndpointsStack.new(endpoints,yellow_states,reset_time)
      @counter = rand(0xffff)
    end

    def next
      # Returns the array of hashes which consists of yellow and green endpoints with the 
      # following structure: [ [EP1, {:n_level => ..., :timestamp => ... }], [EP2, ... ] ]
      endpoints = @stack.sweep_and_return_yellow_and_green
      return nil if endpoints.empty?
      
      # Selection of the next endpoint using RoundRobin
      @counter += 1
      i = @counter % endpoints.size      
      
      # Returns false or true, depending on whether EP is yellow or not
      [ endpoints[i][0], endpoints[i][1][:n_level] != 0 ]
    end

    def good(endpoint, t0, t1)
      @stack.decrease_state(endpoint,t0,t1)
    end

    def bad(endpoint, t0, t1)
      @stack.increase_state(endpoint,t0,t1)
    end
    
    def health_check(endpoint)
      @stack.increase_state(endpoint,t0,Time.now) unless @health_check.call(endpoint)      
    end
    
  end
end
