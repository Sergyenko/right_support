require 'spec_helper'

describe RightSupport::Net::Balancing::HealthCheck do
  context :initialize do

  end
  
  before(:each) do
    @endpoints = [1,2,3,4,5]
    @yellow_states = 4
    @reset_time = 300
    @policy = RightSupport::Net::Balancing::HealthCheck.new(@endpoints, @yellow_states, @reset_time)
    @trials = 2500
  end

  context :good do
    
    context 'given a red server' do
      it "changes to yellow-N" do
        @red = @endpoints.first
        @yellow_states.times { @policy.bad(@red, 0, Time.now) }
        @policy.should have_red_endpoint(@red)
        
        @policy.good(@red, 0, Time.now)
        @policy.should have_yellow_endpoint(@red, @yellow_states-1)
      end
    end

    context 'given a yellow-N server' do
      before(:each) do
        @yellow = @endpoints.first
      end
      
      it 'decreases the yellow level to N-1' do
        2.times { @policy.bad(@yellow, 0, Time.now) }
        @policy.should have_yellow_endpoint(@yellow, 2)

        @policy.good(@yellow, 0, Time.now)
        @policy.should have_yellow_endpoint(@yellow, 1)
      end

      it 'changes to green if N == 0' do
        @policy.bad(@yellow, 0, Time.now)
        @policy.should have_yellow_endpoint(@yellow, 1)
        @policy.good(@yellow, 0, Time.now)
        @policy.should have_green_endpoint(@yellow)
      end
      
      it 'performs a health check' do
        pending
      end
    end
  end

  context :bad do
    context 'given a green server' do
      it 'changes to yellow-1' do
        @green = @endpoints.first
        @policy.should have_green_endpoint(@green)
        @policy.bad(@green, 0, Time.now)
        @policy.should have_yellow_endpoint(@green, 1)
      end
    end

    context 'given a yellow-N server' do
      before(:each) do
        @yellow = @endpoints.first
      end
      
      it 'increases the yellow level to N+1' do
        n = 2
        n.times {@policy.bad(@yellow, 0, Time.now)}
        @policy.should have_yellow_endpoint(@yellow, n)

        @policy.bad(@yellow, 0, Time.now)
        @policy.should have_yellow_endpoint(@yellow, n+1)
      end

      it 'changes to red if N >= @yellow_states' do
        n = @yellow_states - 1
        n.times { @policy.bad(@yellow, 0, Time.now) }
        @policy.should have_yellow_endpoint(@yellow, n)

        @policy.bad(@yellow, 0, Time.now)
        @policy.should have_red_endpoint(@yellow)
      end
    end

    context 'given a red server' do
      it 'does nothing' do
        @red = @endpoints.first
        @yellow_states.times { @policy.bad(@red, 0, Time.now) }
        @policy.should have_red_endpoint(@red)
        
        @policy.bad(@red, 0, Time.now)
        @policy.should have_red_endpoint(@red)
      end
    end
  end

  context :next do

    context 'given all green servers' do
      it 'chooses fairly' do
        test_random_distribution do 
          @policy.next
        end
      end
    end

    context 'given all red servers' do
      it 'returns nil to indicate no servers are available' do
        @endpoints.each do |endpoint|
          @yellow_states.times { @policy.bad(endpoint, 0, Time.now) }
          @policy.should have_red_endpoint(endpoint)
        end
        @policy.next.should be_nil
      end
    end

    context 'given a mixture of servers' do
      it 'never chooses red servers' do
        @red = @endpoints.first
        @yellow_states.times { @policy.bad(@red, 0, Time.now) }
        @policy.should have_red_endpoint(@red)
        
        seen = find_empirical_distribution(@trials,@endpoints) do 
          @policy.next
        end

        seen.include?(@red).should be_false
      end

      it 'chooses fairly from the green and yellow servers' do
        @red = @endpoints.first
        @yellow_states.times { @policy.bad(@red, 0, Time.now) }
        @policy.should have_red_endpoint(@red)
        
        seen = find_empirical_distribution(@trials,@endpoints) do
          @policy.next
        end

        seen.include?(@red).should be_false
        should_be_chosen_fairly(seen, @trials, @endpoints.size - 1)
      end

      it 'demands a health check for yellow servers' do
        pending
      end
    end

    context 'when @reset_time has passed since a server became red' do
      it 'resets the server to yellow' do
        @red = @endpoints.first
        @yellow_states.times { @policy.bad(@red, 0, Time.now - 300) }
        @policy.should have_red_endpoint(@red)
        @policy.next
        @policy.should have_yellow_endpoint(@red, @yellow_states-1)
      end
    end
    
    context 'when @reset_time has passed since a server became yellow' do
      it 'decreases the yellow level to N-1' do
        @yellow = @endpoints.first
        n = 2
        n.times { @policy.bad(@yellow, 0, Time.now - 300) }
        @policy.should have_yellow_endpoint(@yellow,n)
        @policy.next
        @policy.should have_yellow_endpoint(@yellow, n-1)
      end
      
      it 'changes to green if N == 0' do
        @yellow = @endpoints.first
        @policy.bad(@yellow, 0, Time.now - 300)
        @policy.should have_yellow_endpoint(@yellow, 1)
        @policy.next
        @policy.should have_green_endpoint(@yellow)
      end
      
    end
  end
end
