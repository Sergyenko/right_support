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

if_require_succeeds('net/ssh') do
  module RightSupport::Validation
    # Validation methods pertaining to the Secure Shell (SSH) protocol.
    module SSH
      # Determine whether a string is a valid PEM-encoded private key.
      # Actually parses the key to prove validity as well as well-formedness.
      # Relies on the OpenSSL Validation module to parse the private key
      # since PEM is a standard non-SSH-specific key format.
      #
      # === Parameters
      # key_material(String):: the putative key material
      # passphrase(String):: the encryption passphrase, if needed
      #
      # === Return
      # If the key is well-formed and valid, return true. Otherwise, return false.
      def ssh_private_key?(key_material, passphrase=nil)
        return RightSupport::Validation.pem_private_key?(key_material, passphrase)
      end

      # Determine whether a string is a valid public key in SSH public-key
      # notation as might be found in an SSH authorized_keys file.
      #
      # However, authorized-key options are not allowed as they would be in an
      # actual line of the authorized_keys file. The caller is responsible for
      # stripping out any options. The string can consist of the following three
      # whitespace-separated fields:
      #  * algorithm (e.g. "ssh-rsa")
      #  * key material (base64-encoded blob)
      #  * comments (e.g. "user@localhost"); optional
      #
      # This method actually parses the public key to prove validity as well as
      # well-formedness.
      #
      # === Parameters
      # key_material(String):: the putative key material
      #
      # === Return
      # If the key is well-formed and valid, return true. Otherwise, return false.
      def ssh_public_key?(key_material)
        return false if key_material.nil? || key_material.empty?
        ::Net::SSH::KeyFactory.load_data_public_key(key_material)
        return true
      rescue ::Net::SSH::Exception, ::OpenSSL::PKey::PKeyError, NotImplementedError
        return false
      end
    end
  end
end