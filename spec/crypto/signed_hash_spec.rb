require 'spec_helper'

describe RightSupport::Crypto::SignedHash do
  before(:all) do
    @data = random_value(Hash)
    @rsa_key = OpenSSL::PKey::RSA.generate(1024)
  end

  context :sign do
    it 'computes a signature' do
      signature = RightSupport::Crypto::SignedHash.new(@data, :private_key=>@rsa_key).sign
      signature.should_not be_nil
      RightSupport::Crypto::SignedHash.new(@data, :public_key=>@rsa_key).verify(signature).should be_true
    end
  end

  context :verify do
    before(:each) do
      @signature = RightSupport::Crypto::SignedHash.new(@data, :private_key=>@rsa_key).sign
      @hash = RightSupport::Crypto::SignedHash.new(@data, :public_key=>@rsa_key)
    end

    context 'when the signature and data are good' do
      it 'returns true' do
        @hash.verify(@signature).should be_true
      end
    end

    context 'when the data is bad' do
      it 'returns false' do
        @hash[@hash.keys.first] = 'gabba gabba hey!'
        @hash.verify(@signature).should be_false
      end
    end

    context 'when the signature is bad' do
      it 'returns false' do
        @signature << 'xyzzy'
        @hash.verify(@signature).should be_false
      end
    end
  end
end