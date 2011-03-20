require 'openssl'
require 'net/ssh'

module RightSupport::Validation
  module Crypto
    def pem_key?(key_material)
      return false if key_material.nil? || key_material.empty?
      m = /BEGIN ([A-Z]+) (PUBLIC|PRIVATE) KEY/.match(key_material)
      return false unless m
      case m[1]
        when 'DSA' then return OpenSSL::PKey::DSA
        when 'RSA' then return OpenSSL::PKey::RSA
        else return false
      end

    end

    def pem_private_key?(key_material)
      alg = pem_key?(key_material)
      return false unless alg
      key = alg.new(key_material, 'passphrase - should not be needed')
      return key.private?
    rescue OpenSSL::PKey::PKeyError, NotImplementedError
      return false
    end

    def pem_public_key?(key_material)
      alg = pem_key?(key_material)
      return false unless alg
      key = alg.new(key_material)
      return key.public?
    rescue OpenSSL::PKey::PKeyError, NotImplementedError
      return false
    end

    alias :ssh_private_key? :pem_private_key?

    def ssh_public_key?(key_material)
      return false if key_material.nil? || key_material.empty?
      Net::SSH::KeyFactory.load_data_public_key(key_material)
      return true
    rescue OpenSSL::PKey::PKeyError, NotImplementedError
      return false
    end
  end
end