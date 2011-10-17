require 'spec_helper'

describe RightSupport::Crypto::SignedHash do
  before(:all) do
    @data = random_value(Hash)
    @rsa_key = OpenSSL::PKey::RSA.generate(1024)
    @expires_at = Time.at(Time.now.to_i + 60*60) #one hour from now
  end

  context :sign do
    it 'computes a signature' do
      signature = RightSupport::Crypto::SignedHash.new(@data, :private_key=>@rsa_key).sign(@expires_at)
      signature.should_not be_nil
      RightSupport::Crypto::SignedHash.new(@data, :public_key=>@rsa_key).verify(signature, @expires_at).should be_true
    end
  end

  context :verify do
    before(:each) do
      @signature = RightSupport::Crypto::SignedHash.new(@data, :private_key=>@rsa_key).sign(@expires_at)
      @hash = RightSupport::Crypto::SignedHash.new(@data, :public_key=>@rsa_key)
    end

    context 'when the signature and data are good' do
      it 'returns true' do
        @hash.verify(@signature, @expires_at).should be_true
      end
    end

    context 'when expires_at is in the past' do
      it 'returns false'
    end

    context 'when expires_at has been tampered with' do
      it 'returns false'
    end

    context 'when the data is bad' do
      before(:each) do
        modified_data = @data.dup
        modified_data[modified_data.keys.first] = 'gabba gabba hey!'
        @modified_hash = RightSupport::Crypto::SignedHash.new(modified_data, :public_key=>@rsa_key)
      end
      it 'returns false' do
        @modified_hash.verify(@signature, @expires_at).should be_false
      end
    end

    context 'when the signature is bad' do
      it 'returns false' do
        @signature << 'xyzzy'
        @hash.verify(@signature, @expires_at).should be_false
      end
    end
  end
end