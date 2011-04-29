require 'spec_helper'

class TestException < Exception; end
class OtherTestException < Exception; end
class BigDeal < TestException; end
class NoBigDeal < BigDeal; end

describe RightSupport::Net::RequestBalancer do
  context :initialize do
    it 'requires a list of endpoint URLs' do
      lambda do
        RightSupport::Net::RequestBalancer.new(nil)
      end.should raise_exception(ArgumentError)
    end

    context 'with :fatal option' do
      it 're-raises exceptions of the fatal class' do
        rb = RightSupport::Net::RequestBalancer.new([1,2,3], :fatal=>BigDeal)
        tries = 0
        lambda do
          rb.request do |l|
            tries += 1
            raise BigDeal
          end
        end.should raise_error(BigDeal)

        tries.should == 1
      end
    end

    context 'with :fatal and :safe options' do
      it 'does not re-raise exceptions of the safe class' do
        rb = RightSupport::Net::RequestBalancer.new([1,2,3], :fatal=>BigDeal, :safe=>NoBigDeal)
        tries = 0
        lambda do
          rb.request do |l|
            tries += 1
            raise NoBigDeal
          end
        end.should raise_error(RightSupport::Net::NoResponse, /NoBigDeal/)

        tries.should == 3
      end
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

    it 'retries when an exception is raised' do
      list = [1,2,3,4,5,6,7,8,9,10]

      10.times do
        x = RightSupport::Net::RequestBalancer.new(list).request do |l|
          raise StandardError, "Fall down go boom!" unless l == 5
          l
        end

        x.should == 5
      end
    end

    it 'raises if every endpoint in the list also raises' do
      lambda do
        RightSupport::Net::RequestBalancer.request([1,2,3]) do |l|
          raise StandardError, "Fall down go boom!"
        end
      end.should raise_exception(RightSupport::Net::NoResponse)
    end

    it 'raises rescued exception if all endpoints fail to provide a result but some raise an exception' do
      lambda do
        RightSupport::Net::RequestBalancer.request([1,2,3]) do |l|
          case l
            when 1,2 then raise TestException
            when 3 then raise OtherTestException
          end
        end
      end.should raise_exception(RightSupport::Net::NoResponse, /TestException/)
    end
  end
end
