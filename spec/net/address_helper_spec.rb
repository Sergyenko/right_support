require 'spec_helper'

describe RightSupport::Net::AddressHelper do
  class AddressHelperTarget
    include RightSupport::Net::AddressHelper
  end

  before(:each) do
    @helper = AddressHelperTarget.new
  end

  describe :my_ipv4_addresses do

  end

  describe :my_ipv4_address do
    it 'should consistently choose the lowest-numbered address' do
      p = ['10.0.1.17', '192.168.7.5', '192.168.4.2', '127.0.0.1']
      flexmock(@helper).should_receive(:local_routable_address).with(Socket::AF_INET).and_return(p[0])
      flexmock(@helper).should_receive(:local_hostname_addresses).with(Socket::AF_INET).once.ordered.and_return([ p[3], p[2] ])
      flexmock(@helper).should_receive(:local_hostname_addresses).with(Socket::AF_INET).once.ordered.and_return([ p[1], p[2] ])

      one = @helper.my_ipv4_address(:private)
      two = @helper.my_ipv4_address(:private)
      one.should == p[0]
      two.should == p[0]
    end
  end

  describe :my_ipv4_addresses do
    before(:each) do
      routable_addr  = '67.2.204.5'
      hostname_addrs = ['127.0.0.1', '10.0.0.15', '67.2.204.5']
      flexmock(@helper).should_receive(:local_routable_address).with(Socket::AF_INET).and_return(routable_addr)
      flexmock(@helper).should_receive(:local_hostname_addresses).with(Socket::AF_INET).and_return(hostname_addrs)
      flexmock(@helper).should_receive(:local_hostname_addresses).with(Socket::AF_INET).and_return(hostname_addrs)
    end

    context 'with :loopback option' do
      it 'should return only loopback addresses' do
        @helper.my_ipv4_addresses(:loopback).should == ['127.0.0.1']
      end
    end

    context 'with :private option' do
      it 'should return only private addresses' do
        @helper.my_ipv4_addresses(:private).should == ['10.0.0.15']
      end
    end

    context 'with :public option' do
      it 'should return only public addresses' do
        @helper.my_ipv4_addresses(:public).should == ['67.2.204.5']
      end
    end
  end
end
