require 'openssl'
require 'net/ssh'

module RightSupport::Validation
  module Crypto
    def pem_private_key?(key_material)
      return false if key_material.nil? || key_material.empty?
      key = OpenSSL::PKey::RSA.new(key_material, 'foobario')
      return key.private?
    rescue OpenSSL::PKey::PKeyError, NotImplementedError
      return false
    end

    def pem_public_key?(key_material)
      return false if key_material.nil? || key_material.empty?
      key = OpenSSL::PKey::RSA.new(key_material)
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