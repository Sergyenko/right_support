require 'spec_helper'

describe RightSupport::Net::REST do
  it 'is interface-compatible with RestClient' do
    m = RightSupport::Net::REST
    m.should respond_to(:get)
    m.should respond_to(:post)
    m.should respond_to(:put)
    m.should respond_to(:delete)
  end

  context :request do
    before(:each) do
      r = 'this is a short mock REST response'
      flexmock(RestClient::Request).should_receive(:execute).and_return(r).by_default
    end

    context 'given just a URL' do
      it 'succeeds' do
        p = {:method=>:get, :timeout=>RightSupport::Net::REST::DEFAULT_TIMEOUT,
             :url=>'/moo', :headers=>{}}
        flexmock(RestClient::Request).should_receive(:execute).with(p)

        RightSupport::Net::REST.get('/moo')
      end
    end

    context 'given a URL and headers' do
      it 'succeeds' do
        p = {:method=>:get, :timeout=>RightSupport::Net::REST::DEFAULT_TIMEOUT,
             :url=>'/moo', :headers=>{:mrm=>1, :blah=>:foo}}
        flexmock(RestClient::Request).should_receive(:execute).with(p)

        RightSupport::Net::REST.get('/moo', {:headers => {:mrm=>1, :blah=>:foo}})
      end
    end


    context 'given a timeout, no headers, and a URL' do
      it 'succeeds' do
        p = {:method=>:get, :timeout=>42,
             :url=>'/moo', :headers=>{}}
        flexmock(RestClient::Request).should_receive(:execute).with(p)

        RightSupport::Net::REST.get('/moo', {:timeout => 42})
      end
    end
    
    context 'given a URL and any other parameters' do
      it 'succeeds' do
        p = {:method=>:get, :timeout=>RightSupport::Net::REST::DEFAULT_TIMEOUT,
             :url=>'/moo', :headers=>{},:open_timeout => 1, :foo => :bar}
        flexmock(RestClient::Request).should_receive(:execute).with(p)

        RightSupport::Net::REST.get('/moo', {:open_timeout => 1, :foo => :bar})
      end
    end
  end
end
