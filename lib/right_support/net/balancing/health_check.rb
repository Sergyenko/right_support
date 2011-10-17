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
    DEFAULT_YELLOW_STATES = 4
    DEFAULT_RESET_TIME    = 300
    
    def initialize(endpoints, yellow_states=nil, reset_time=nil)
      @endpoints = Hash.new
      @yellow_states = yellow_states || DEFAULT_YELLOW_STATES
      @reset_time = reset_time || DEFAULT_RESET_TIME
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

    # Returns a hash of endpoints and their colored health status
    # Useful for logging and debugging
    def get_stats
      stats = {}
      @endpoints.each do |k, v|
        stats[k] = 'green' if v[:n_level] == 0
        stats[k] = 'red' if v[:n_level] == @yellow_states
        stats[k] = "yellow-#{v[:n_level]}" if v[:n_level] > 0 && v[:n_level] < @yellow_states
      end
      stats
    end
    
  end
  
  # Implementation concepts: endpoints have three states, red, yellow and green.  Yellow
  # has several levels (@yellow_states) to determine the health of the endpoint. The
  # balancer works by avoiding "red" endpoints and retrying them after awhile.  Here is a
  # brief description of the state transitions:
  # * green: last request was successful.
  #    * on success: remain green
  #    * on failure: change state to yellow and set it's health to healthiest (1)
  # * red: skip this server
  #    * after @reset_time passes change state to yellow and set it's health to
  #      sickest (@yellow_states)
  # * yellow: last request was either successful or failed
  #    * on success: change state to green if it's health was healthiest (1), else
  #      retain yellow state and improve it's health
  #    * on failure: change state to red if it's health was sickest (@yellow_states), else
  #      retain yellow state and decrease it's health

  class HealthCheck
    
    def initialize(endpoints,options = {})
      yellow_states = options[:yellow_states]
      reset_time = options[:reset_time]

      @health_check = options.delete(:health_check)

      @stack = EndpointsStack.new(endpoints,yellow_states,reset_time)
      @counter = rand(0xffff) % endpoints.size
      @last_size = endpoints.size
    end

    def next
      # Returns the array of hashes which consists of yellow and green endpoints with the 
      # following structure: [ [EP1, {:n_level => ..., :timestamp => ... }], [EP2, ... ] ]
      endpoints = @stack.sweep_and_return_yellow_and_green
      return nil if endpoints.empty?
      
      # Selection of the next endpoint using RoundRobin
      @counter += 1 unless endpoints.size < @last_size
      @counter = 0 if @counter == endpoints.size
      @last_size = endpoints.size
      
      # Returns false or true, depending on whether EP is yellow or not
      [ endpoints[@counter][0], endpoints[@counter][1][:n_level] != 0 ]
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

    # Proxy to EndpointStack
    def get_stats
      @stack.get_stats
    end
    
  end
end
