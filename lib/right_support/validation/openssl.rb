#
# Copyright (c) 2011 RightScale Inc
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'openssl'

module RightSupport::Validation
  # Validation methods pertaining to OpenSSL cryptography, e.g. various
  # widely-used key formats and encoding/envelope formats.
  module OpenSSL
    # Determine whether a string is a PEM-encoded public or private key.
    # Does not determine whether the key is valid, only that it is well-formed.
    #
    # === Parameters
    # key_material(String):: the putative key material
    #
    # === Return
    # If the key is well-formed, return the OpenSSL class that can be used
    # to process the key material (e.g. OpenSSL::PKey::RSA). Otherwise, return
    # false.
    def pem_key?(key_material)
      return false if key_material.nil? || key_material.empty?
      m = /BEGIN ([A-Z]+) (PUBLIC|PRIVATE) KEY/.match(key_material)
      return false unless m
      case m[1]
        when 'DSA' then return ::OpenSSL::PKey::DSA
        when 'RSA' then return ::OpenSSL::PKey::RSA
        else return false
      end

    end

    # Determine whether a string is a valid PEM-encoded private key.
    # Actually parses the key to prove validity as well as well-formedness.
    # If the key is passphrase-protected, the passphrase is required in
    # order to decrypt it; am incorrect passphrase will result in the key
    # being recognized as not a valid key!
    #
    # === Parameters
    # key_material(String):: the putative key material
    # passphrase(String):: the encryption passphrase, if needed
    #
    # === Return
    # If the key is well-formed and valid, return true. Otherwise, return false.
    #
    def pem_private_key?(key_material, passphrase=nil)
      alg = pem_key?(key_material)
      return false unless alg
      key = alg.new(key_material, passphrase || 'dummy passphrase, should never work')
      return key.private?
    rescue ::OpenSSL::PKey::PKeyError, NotImplementedError
      return false
    end

    # Determine whether a string is a valid PEM-encoded public key.
    # Actually parses the key to prove validity as well as well-formedness.
    #
    # === Parameters
    # key_material(String):: the putative key material
    #
    # === Return
    # If the key is well-formed and valid, return true. Otherwise, return false.
    def pem_public_key?(key_material)
      alg = pem_key?(key_material)
      return false unless alg
      key = alg.new(key_material)
      return key.public?
    rescue ::OpenSSL::PKey::PKeyError, NotImplementedError
      return false
    end
  end
end