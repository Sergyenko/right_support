require 'spec_helper'

describe RightSupport::Net::Balancing::HealthCheck do
  context :initialize do

  end

  context :next do
    before(:each) do
      @policy = RightSupport::Net::Balancing::HealthCheck.new
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
        pending
      end

      it 'chooses fairly from the running servers' do
        pending
      end
    end

    context 'with some servers marked as red' do
      context 'when @reset_time passes for all red servers' do
        it 'resets all servers to green and chooses fairly' do
          pending
        end
      end
    end

    context 'with all servers down' do
      it 'chooses fairly' do
        pending
      end
    end
  end
end
