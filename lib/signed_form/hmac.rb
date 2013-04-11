require "openssl"

module SignedForm
  class HMAC
    attr_accessor :secret_key
    attr_accessor :digest

    def self.secret_key=(key)
      SignedForm.secret_key = key
      warn "SignedForm::HMAC.secret_key is depreciated and will be removed in the next release. "\
           "Please use SignedForm.secret_key instead."
    end

    def initialize(options = {})
      self.secret_key = options[:secret_key]
      self.digest     = options.fetch(:digest, OpenSSL::Digest::SHA1.new)

      if secret_key.nil? || secret_key.empty?
        raise Errors::NoSecretKey, "Please consult the README for instructions on creating a secret key"
      end
    end

    def create(data)
      OpenSSL::HMAC.hexdigest digest, secret_key, data
    end

    def verify(signature, data)
      secure_compare OpenSSL::HMAC.hexdigest(digest, secret_key, data), signature
    end

    private

    # After the Rack implementation
    def secure_compare(a, b)
      return false unless a.bytesize == b.bytesize

      l = a.unpack("C*")

      r, i = 0, -1
      b.each_byte { |v| r |= v ^ l[i+=1] }
      r == 0
    end
  end
end
