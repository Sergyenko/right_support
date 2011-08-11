require 'spec_helper'

describe RightSupport::Net::Balancing::RoundRobin do
  before(:each) do
    @policy = RightSupport::Net::Balancing::RoundRobin.new
  end

  it 'chooses fairly' do
    test_random_distribution do |list|
      @policy.next(list)
    end
  end
end