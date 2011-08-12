require 'spec_helper'

describe RightSupport::Net::Balancing::HealthCheck do
  context :initialize do

  end

  context :next do
    before(:each) do
      @policy = RightSupport::Net::Balancing::HealthCheck.new
      @endpoints = [1,2,3,4,5]
      @trials = 2500
    end

    context 'with all servers up' do
      it 'chooses fairly' do
        test_random_distribution do |list|
          @policy.next(list)
        end
      end
    end

    context 'with some servers down' do
      it 'chooses only running servers' do
        bad_endpoint = @endpoints.first 
        @policy.bad(bad_endpoint,0,Time.now + 1000)
        
        seen = find_empirical_distribution(@trials,@endpoints) do |list|
          @policy.next(list)
        end
        seen.include?(bad_endpoint).should be_false
      end

      it 'chooses fairly from the running servers' do
        bad_endpoint = @endpoints.first 
        @policy.bad(bad_endpoint,0,Time.now + 1000)
        
        seen = find_empirical_distribution(@trials,@endpoints) do |list|
          @policy.next(list)
        end
        
        seen.include?(bad_endpoint).should be_false
        should_be_chosen_fairly(seen, @trials, @endpoints.size - 1)
      end
      
    end

    context 'with some servers marked as red' do
      context 'when @reset_time passes for one red server' do
        it 'resets that server to yellow-N' do
          pending
        end
      end
    end

    context 'with all servers down' do
      it 'returns nil to indicate no servers are available' do
        @endpoints.each {|e| @policy.bad(e,0,Time.now + 1000)}
        @policy.next(@endpoints).should be_nil
      end
    end
  end
end
