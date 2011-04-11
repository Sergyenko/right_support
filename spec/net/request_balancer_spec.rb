require 'spec_helper'

class TestException < Exception; end

describe RightSupport::Net::RequestBalancer do
  context :initialize do
    it 'requires a list of endpoint URLs' do
      lambda do
        RightSupport::Net::RequestBalancer.new(nil)
      end.should raise_exception(ArgumentError)
    end
  end

  context :request do
    it 'requires a block' do
      lambda do
        RightSupport::Net::RequestBalancer.new([1]).request
      end.should raise_exception(ArgumentError)
    end

    it 'shuffles endpoints randomly' do
      list = [1,2,3,4,5,6,7,8,9,10]

      seen = Set.new
      
      100.times do
        random = []
        x = 0
        RightSupport::Net::RequestBalancer.new(list).request do |l|
          random << l
          x += 1
          raise StandardError, "Fall down go boom!" unless x >= 9
          l
        end

        seen << random
      end

      seen.size.should >= 50
    end

    it 'returns the first successful result' do
      list = [1,2,3,4,5,6,7,8,9,10]

      10.times do
        x = RightSupport::Net::RequestBalancer.new(list).request do |l|
          raise StandardError, "Fall down go boom!" unless l == 5
          l
        end

        x.should == 5
      end
    end

    it 'raises if all endpoints fail to provide a result' do
      lambda do
        RightSupport::Net::RequestBalancer.request([1,2,3]) do |l|
          nil
        end
      end.should raise_exception(RightSupport::Net::NoResponse)
    end

    it 'raises rescued exception if all endpoints fail to provide a result but some raise an exception' do
      lambda do
        RightSupport::Net::RequestBalancer.request([1,2,3]) do |l|
          raise TestException, "Fall down go boom!" if l == 2
          nil
        end
      end.should raise_exception(TestException)
    end
  end
end
