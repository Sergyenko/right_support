module RightSupport::Crypto
  class SignedHash
    DEFAULT_OPTIONS = {
      :digest   => Digest::SHA1,
      :encoding => YAML
    }

    def initialize(hash={}, options={})
      options = DEFAULT_OPTIONS.merge(options)
      @hash        = hash
      @digest      = options[:digest]
      @encoding    = options[:encoding]
      @public_key  = options[:public_key]
      @private_key = options[:private_key]
      duck_type_check
    end

    def sign
      raise ArgumentError, "Cannot sign; missing private_key" unless @private_key
      x = @private_key.private_encrypt( digest( encode( canonicalize(@hash) ) ) )
      x
    end

    def verify(signature)
      raise ArgumentError, "Cannot verify; missing public_key" unless @public_key
      expected = digest( encode( canonicalize(@hash) ) )
      actual = @public_key.public_decrypt(signature)
      actual == expected
    rescue OpenSSL::PKey::PKeyError
      false
    end

    def method_missing(meth, *args)
      @hash.__send__(meth, *args)
    end

    private

    def duck_type_check
      unless @digest.is_a?(Class) &&
             @digest.instance_methods.include?('update') &&
             @digest.instance_methods.include?('digest')
        raise ArgumentError, "Digest class must respond to #update and #digest instance methods"
      end
      unless @encoding.respond_to?(:dump)
        raise ArgumentError, "Encoding class/module/object must respond to .dump method"
      end
      if @public_key && !@public_key.respond_to?(:public_decrypt)
        raise ArgumentError, "Public key must respond to :public_decrypt (e.g. an OpenSSL::PKey instance)"
      end
      if @private_key && !@private_key.respond_to?(:private_encrypt)
        raise ArgumentError, "Private key must respond to :private_encrypt (e.g. an OpenSSL::PKey instance)"
      end
    end

    def digest(input) # :nodoc:
      @digest.new.update(input).digest
    end

    def encode(input)
      @encoding.dump(input)
    end

    def canonicalize(input) # :nodoc:
      case input
        when Hash
          output = Array.new
          ordered_keys = input.keys.sort
          ordered_keys.each do |key|
            output << [ canonicalize(key), canonicalize(input[key]) ]
          end
        when Array
          output = input.collect { |x| canonicalize(x) }
        else
          output = input
      end

      output
    rescue ArgumentError, NoMethodError => e
      if e.message =~ /comparison of|undefined method `<=>'/
        e2 = ArgumentError.new("SignedHash requires sortable hashes and arrays; cannot sort #{input.inspect}")
        e2.set_backtrace(e.backtrace)
        raise e2
      else
        raise e
      end
    end
  end
end