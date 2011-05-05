require 'spec_helper'

class TestException < Exception; end
class OtherTestException < Exception; end
class BigDeal < TestException; end
class NoBigDeal < TestException; end

class MockResourceNotFound < Exception
  def http_code
    404
  end
end

describe RightSupport::Net::RequestBalancer do
  def test_raise(fatal, do_raise, expect)
    rb = RightSupport::Net::RequestBalancer.new([1,2,3], :fatal=>fatal)
    tries = 0
    l = lambda do
      rb.request do |_|
        tries += 1
        raise do_raise if do_raise
      end
    end

    if expect.first
      l.should raise_error(expect.first)
    else
      l.should_not raise_error
    end

    tries.should == expect.last
  end

  context :initialize do
    it 'requires a list of endpoint URLs' do
      lambda do
        RightSupport::Net::RequestBalancer.new(nil)
      end.should raise_exception(ArgumentError)
    end

    context 'without :fatal option' do
      it 're-raises reasonable default fatal errors' do
        test_raise(nil, StandardError, [StandardError, 1])
        test_raise(nil, MockResourceNotFound, [MockResourceNotFound, 1])
      end
    end

    context 'with :fatal option' do
      it 're-raises fatal errors' do
        test_raise(BigDeal, BigDeal, [BigDeal, 1])
        test_raise([BigDeal, NoBigDeal], NoBigDeal, [NoBigDeal, 1])
        test_raise(true, NoBigDeal, [NoBigDeal, 1])
        test_raise(lambda {|e| e.is_a? BigDeal }, BigDeal, [BigDeal, 1])
      end

      it 'swallows nonfatal errors' do
        test_raise(nil, BigDeal, [RightSupport::Net::NoResponse, 3])
        test_raise(BigDeal, NoBigDeal, [RightSupport::Net::NoResponse, 3])
        test_raise([BigDeal], NoBigDeal, [RightSupport::Net::NoResponse, 3])
        test_raise(false, NoBigDeal, [RightSupport::Net::NoResponse, 3])
        test_raise(lambda {|e| e.is_a? BigDeal }, NoBigDeal, [RightSupport::Net::NoResponse, 3])
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
          raise NoBigDeal, "Fall down go boom!" unless x >= 9
          l
        end

        seen << random
      end

      seen.size.should >= 50
    end

    context 'with default :fatal option' do
      it 'retries SystemCallError' do
        list = [1,2,3,4,5,6,7,8,9,10]
        x = RightSupport::Net::RequestBalancer.new(list).request do |l|
          raise SystemCallError, 'moo' unless l == 5
          l
        end

        x.should == 5
      end

      it 'does not retry StandardError' do
        list = [1,2,3,4,5,6,7,8,9,10]
        rb = RightSupport::Net::RequestBalancer.new(list)

        lambda do
          rb.request do |l|
            raise ArgumentError, 'bah'
            l
          end
        end.should raise_error(ArgumentError)
      end

      it 'retries HTTP timeouts'

      it 'does not retry HTTP 4xx other than timeout'
    end

    it 'retries when an exception is raised' do
      list = [1,2,3,4,5,6,7,8,9,10]

      10.times do
        x = RightSupport::Net::RequestBalancer.new(list).request do |l|
          raise NoBigDeal, "Fall down go boom!" unless l == 5
          l
        end

        x.should == 5
      end
    end

    it 'raises if every endpoint in the list also raises' do
      lambda do
        RightSupport::Net::RequestBalancer.request([1,2,3]) do |l|
          raise NoBigDeal, "Fall down go boom!"
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
