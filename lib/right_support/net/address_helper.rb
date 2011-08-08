# Copyright (c) 2009-2011 RightScale, Inc, All Rights Reserved Worldwide.
#
# THIS PROGRAM IS CONFIDENTIAL AND PROPRIETARY TO RIGHTSCALE
# AND CONSTITUTES A VALUABLE TRADE SECRET.  Any unauthorized use,
# reproduction, modification, or disclosure of this program is
# strictly prohibited.  Any use of this program by an authorized
# licensee is strictly subject to the terms and conditions,
# including confidentiality obligations, set forth in the applicable
# License Agreement between RightScale.com, Inc. and the licensee.

require 'socket'

module RightSupport::Net
  # A helper module that provides some useful methods for querying the local machine about its network
  # addresses.
  #
  # This module is automatically included into the eigenclass of RightSupport::Net for convenience. Any
  # of the methods available in this module can be called as RightSupport::Net.foo without needing to
  # include this module.
  module AddressHelper
    class NoSuitableInterface < RuntimeError; end

    PRIVATE_IP_REGEX  = /^(10\.|192\.168\.|172\.(1[6789]|2[0-9]|3[01]))/
    LOOPBACK_IP_REGEX = /^(127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})/

    # Determine the network address of some local interface that has a route to the public Internet.
    #
    # On some systems, Socket.getaddrinfo(Socket.gethostname, ...) does not return any IP addresses,
    # for instance because the local hostname cannot be resolved by DNS. This method can be used to
    # detect "my IP address" in such cases.
    #
    # This code does NOT make a connection or send any packets (to 64.233.187.99 which is google).
    # Since UDP is a stateless protocol, connect() merely makes a system call which figures out how
    # to route the packets based on the address and what interface (and therefore IP address) it
    # should bind to. addr() returns an array containing the family (AF_INET), local port, and
    # local address (which is what we want) of the socket.
    #
    # === Parameters
    # address_family(Integer):: Socket::AF_INET or Socket::AF_INET6
    #
    # === Return
    # address(String):: a single IP address in dotted-quad notation
    def local_routable_address(address_family)
      case address_family
        when Socket::AF_INET
          remote_address = '64.233.187.99'
        when Socket::AF_INET6
          remote_address = '2607:f8b0:4003:c00::68'
        else
          raise ArgumentError, "Routable address discovery only works for AF_INET or AF_INET6"
      end

      # turn off reverse DNS resolution temporarily
      orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true
      UDPSocket.open(address_family) do |s|
        s.connect remote_address, 1
        s.addr.last
      end
    ensure
      Socket.do_not_reverse_lookup = orig
    end

    # Determine all network addresses of the local machine that are resolvable using either the machine's
    # hostname or "localhost". Typically this allows us to discover the local IP addresses of
    # "interesting" network interfaces without relying on OS-specific tools such as ifconfig/ipconfig.
    #
    # === Parameters
    # address_family(Integer):: Socket::AF_INET or Socket::AF_INET6
    #
    # === Return
    # addresses(Array):: a list of IP addresses in dotted-quad notation
    def local_hostname_addresses(address_family)
      loopback = Socket.getaddrinfo('localhost', 1,
                   address_family, Socket::SOCK_STREAM,
                   nil, nil).collect { |x| x[3] }

      real = Socket.getaddrinfo(Socket.gethostname, 1,
               address_family, Socket::SOCK_STREAM,
               nil, nil).collect { |x| x[3] }
      (loopback + real).uniq
    end

    # Determine all IPv4 addresses of the local machine that fall into the given range of IP address space
    # (public, private or loopback).
    #
    # === Parameters
    # flavor(Symbol):: One of :public, :private or :loopback
    #
    # === Return
    # addresses(Array):: a list of IP addresses in dotted-quad notation
    def my_ipv4_addresses(flavor=:private)
      all = local_hostname_addresses(Socket::AF_INET)
      all << local_routable_address(Socket::AF_INET)
      all.uniq!

      case flavor
        when :public
          return all.select { |ip| ip !~ PRIVATE_IP_REGEX && ip !~ LOOPBACK_IP_REGEX }
        when :private
          return all.select { |ip| ip =~ PRIVATE_IP_REGEX }
        when :loopback
          return all.select { |ip| ip =~ LOOPBACK_IP_REGEX }
        else
          raise ArgumentError, "flavor must be :public, :private or :loopback"
      end
    end

    # Determine an IPv4 address of the local machine that falls into the given range of IP address space
    # (public, private or loopback). If multiple suitable addresses are found, the same address will be
    # consistently returned but there is no way to influence _which_ address that will be.
    #
    # === Parameters
    # flavor(Symbol):: One of :public, :private or :loopback
    #
    # === Return
    # addresses(Array):: a list of IP addresses in dotted-quad notation
    def my_ipv4_address(flavor=:private)
      candidates = my_ipv4_addresses(flavor)
      raise NoSuitableInterface, "No interface had a #{flavor} IPv4 address" if candidates.empty?

      #Ensure we consistently the same interface by doing a lexical sort
      return candidates.sort.first
    end
  end
end
