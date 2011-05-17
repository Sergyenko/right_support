require 'spec_helper'

class TestException < Exception; end
class OtherTestException < Exception; end
class BigDeal < TestException; end
class NoBigDeal < TestException; end

class MockHttpError < Exception
  attr_reader :http_code
  def initialize(message=nil, code=400)
    super(message)
    @http_code = code
  end
end

class MockResourceNotFound < MockHttpError
  def initialize(message=nil)
    super(message, 404)
  end
end

class MockRequestTimeout < MockHttpError
  def initialize(message=nil)
    super(message, 408)
  end
end

describe RightSupport::Net::RequestBalancer do
  def test_raise(fatal, do_raise, expect)
    expect = [expect] unless expect.respond_to?(:first)

    rb = RightSupport::Net::RequestBalancer.new([1,2,3], :fatal=>fatal)
    tries = 0
    l = lambda do
      rb.request do |_|
        tries += 1
        raise do_raise, 'bah' if do_raise
      end
    end

    if expect.first
      l.should raise_error(expect.first)
    else
      l.should_not raise_error
    end

    tries.should == expect.last
  end

  def test_randomness(trials=25000, list=[1,2,3])
    seen = {}

    trials.times do
      value = yield(list)
      seen[value] ||= 0
      seen[value] += 1
    end

    #Load should be evenly distributed
    chance = 1.0 / list.size
    seen.each_pair do |_, count|
      (Float(count) / Float(trials)).should be_close(chance, 0.025) #allow 5% margin of error
    end
  end

  context :initialize do
    it 'requires a list of endpoint URLs' do
      lambda do
        RightSupport::Net::RequestBalancer.new(nil)
      end.should raise_exception(ArgumentError)
    end

    context 'with :fatal option' do
      it 'validates the arity (if applicable)' do
        bad_lambda = lambda { |too, many, arguments| }
        lambda do
          RightSupport::Net::RequestBalancer.new([1,2], :fatal=>bad_lambda)
        end.should raise_error(ArgumentError)

        lambda do
          RightSupport::Net::RequestBalancer.new([1,2], :fatal=>BigDeal)
        end.should_not raise_error
      end
    end

    context 'with :on_exception option' do
      it 'validates the arity' do
        bad_lambda = lambda { |way, too, many, arguments| }
        lambda do
          RightSupport::Net::RequestBalancer.new([1,2], :on_exception=>bad_lambda)
        end.should raise_error(ArgumentError)
      end
    end
  end

  context :request do
    it 'requires a block' do
      lambda do
        RightSupport::Net::RequestBalancer.new([1]).request
      end.should raise_exception(ArgumentError)
    end

    context 'when called as a class method' do
      it 'shuffles randomly' do

        test_randomness do |list|
          RightSupport::Net::RequestBalancer.request(list) do |endpoint|
            endpoint
          end
        end
      end
    end

    context 'when called as an instance method' do
      it 'shuffles randomly' do

        test_randomness do |list|
          @balancer ||= RightSupport::Net::RequestBalancer.new(list)
          @balancer.request do |endpoint|
            endpoint
          end
        end
      end
    end

    it 'retries until a request completes' do
      list = [1,2,3,4,5,6,7,8,9,10]

      10.times do
        x = RightSupport::Net::RequestBalancer.new(list).request do |l|
          raise NoBigDeal, "Fall down go boom!" unless l == 5
          l
        end

        x.should == 5
      end
    end

    it 'raises if no request completes' do
      lambda do
        RightSupport::Net::RequestBalancer.request([1,2,3]) do |l|
          raise NoBigDeal, "Fall down go boom!"
        end
      end.should raise_exception(RightSupport::Net::NoResult, /NoBigDeal/)
    end

    context 'without :fatal option' do
      it 're-raises reasonable default fatal errors' do
        test_raise(nil, ArgumentError, [ArgumentError, 1])
        test_raise(nil, MockResourceNotFound, [MockResourceNotFound, 1])
      end

      it 'swallows StandardError and friends' do
        [SystemCallError, SocketError].each do |klass|
          test_raise(nil, klass, [RightSupport::Net::NoResult, 3])
        end
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
        test_raise(nil, BigDeal, [RightSupport::Net::NoResult, 3])
        test_raise(BigDeal, NoBigDeal, [RightSupport::Net::NoResult, 3])
        test_raise([BigDeal], NoBigDeal, [RightSupport::Net::NoResult, 3])
        test_raise(false, NoBigDeal, [RightSupport::Net::NoResult, 3])
        test_raise(lambda {|e| e.is_a? BigDeal }, NoBigDeal, [RightSupport::Net::NoResult, 3])
      end
    end

    context 'with default :fatal option' do
      it 'retries most Ruby builtin errors' do
        list = [1,2,3,4,5,6,7,8,9,10]
        rb = RightSupport::Net::RequestBalancer.new(list)

        [IOError, SystemCallError, SocketError].each do |klass|
          test_raise(nil, klass, [RightSupport::Net::NoResult, 3])
        end
      end

      it 'does not retry ArgumentError and other program errors' do

      end

      it 'retries HTTP timeouts' do
        test_raise(nil, MockRequestTimeout, [RightSupport::Net::NoResult, 3])
      end

      it 'does not retry HTTP 4xx other than timeout' do
        list = [1,2,3,4,5,6,7,8,9,10]
        rb = RightSupport::Net::RequestBalancer.new(list)

        codes = [401, 402, 403, 404, 405, 406, 407, 409]
        codes.each do |code|
          lambda do
            rb.request { |l| raise MockHttpError.new(code) }
          end.should raise_error(MockHttpError)
        end
      end
    end

    context 'with :on_exception option' do
      before(:each) do
        @list = [1,2,3,4,5,6,7,8,9,10]
        @callback = flexmock('Callback proc')
        @callback.should_receive(:respond_to?).with(:call).and_return(true)
        @callback.should_receive(:respond_to?).with(:arity).and_return(true)
        @callback.should_receive(:arity).and_return(3)
        @rb = RightSupport::Net::RequestBalancer.new(@list, :fatal=>BigDeal, :on_exception=>@callback)
      end

      it 'calls me back with fatal exceptions' do
        @callback.should_receive(:call).with(true, BigDeal, Integer)
        lambda {
          @rb.request { raise BigDeal }
        }.should raise_error(BigDeal)
      end

      it 'calls me back with nonfatal exceptions' do
        @callback.should_receive(:call).with(false, NoBigDeal, Integer)
        lambda {
          @rb.request { raise NoBigDeal }
        }.should raise_error(RightSupport::Net::NoResult)

      end
    end
  end
end
