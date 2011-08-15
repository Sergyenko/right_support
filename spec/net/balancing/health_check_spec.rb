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
        it 'turns that server green and chooses fairly' do
          bad_endpoint = @endpoints.first 
          @policy.bad(bad_endpoint,0,Time.now-300)
          
          sleep(1)
          
          seen = find_empirical_distribution(@trials,@endpoints) do |list|
            @policy.next(list)
          end
          
          seen.include?(bad_endpoint).should be_true
          should_be_chosen_fairly(seen, @trials, @endpoints.size)
        end
      end
      
      context 'when @reset_time passes for all red servers' do
        it 'resets all servers to green and chooses fairly' do
          good_endpoint = @endpoints.last
          
          (@endpoints - [good_endpoint]).each {|e| @policy.bad(e,0,Time.now-299)}  
          
          seen = find_empirical_distribution(@trials,@endpoints) do |list|
            @policy.next(list)
          end
          
          seen.size.should == 1
          seen[good_endpoint].should be_eql @trials
          
          @policy.bad(good_endpoint,0,Time.now-299)
          
          sleep(1)
          
          seen = find_empirical_distribution(@trials,@endpoints) do |list|
            @policy.next(list)
          end
          should_be_chosen_fairly(seen, @trials, @endpoints.size)
        end
      end
    end

    context 'with all servers down' do
      it 'chooses fairly' do
        @endpoints.each {|e| @policy.bad(e,0,Time.now + 1000)}
        
        seen = find_empirical_distribution(@trials,@endpoints) do |list|
          @policy.next(list)
        end
        should_be_chosen_fairly(seen, @trials, @endpoints.size)
      end
    end
  end
end
