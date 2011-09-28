require 'spec_helper'

describe RightSupport::Net::Balancing::RoundRobin do
  before(:each) do
    @endpoints = [1,2,3,4,5]
    @policy = RightSupport::Net::Balancing::RoundRobin.new(@endpoints)
  end

  it 'chooses fairly' do
    test_random_distribution do 
      @policy.next
    end
  end
end
