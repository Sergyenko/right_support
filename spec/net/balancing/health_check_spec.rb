require 'spec_helper'

describe RightSupport::Net::Balancing::HealthCheck do
  context :initialize do

  end

  context :good do
    context 'given a red server' do
      it 'does nothing' do
        pending
      end
    end

    context 'given a yellow-N server' do
      it 'decreases the yellow level to N-1' do
        pending
      end

      it 'changes to green if N == 0' do
        pending
      end
    end
  end

  context :bad do
    context 'given a green server' do
      it 'changes to yellow-1'
    end

    context 'given a yellow-N server' do
      it 'increases the yellow level to N+1' do
        pending
      end

      it 'changes to red if N >= @max_failures' do
        pending
      end
    end

    context 'given a red server' do
      it 'does nothing' do
        pending
      end
    end
  end

  context :next do
    before(:each) do
      @endpoints = [1,2,3,4,5]
      @policy = RightSupport::Net::Balancing::HealthCheck.new(@endpoints)
      @trials = 2500
    end

    context 'given all green servers' do
      it 'chooses fairly' do
        test_random_distribution do 
          @policy.next
        end
      end
    end

    context 'given all red servers' do
      it 'returns nil to indicate no servers are available' do
        #@endpoints.each {|e| @policy.bad(e,0,Time.now + 1000)}
        #@policy.next(@endpoints).should be_nil
        pending
      end
    end

    context 'given a mixture of servers' do
      it 'never chooses red servers' do
        pending
      end

      it 'chooses fairly from the green and yellow servers' do
        pending
      end

      it 'demands a health check for yellow servers' do
        pending
      end
    end

    context 'when @reset_time has passed since a server became red' do
      it 'resets the server to yellow' do
        pending
      end
    end
  end
end
