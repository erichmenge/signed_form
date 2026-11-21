require 'openssl'

module SignedForm
  class HMAC
    attr_accessor :secret_key

    def initialize(options = {})
      self.secret_key = options[:secret_key]

      if missing_secret_key? && defined?(::Rails) && ::Rails.respond_to?(:application)
        application = ::Rails.application
        if application && application.respond_to?(:secret_key_base)
          self.secret_key = application.secret_key_base
        end
        if missing_secret_key? && application && application.respond_to?(:secrets)
          self.secret_key = application.secrets.secret_key_base
        end
      end

      if missing_secret_key?
        raise Errors::NoSecretKey, 'Please consult the README for instructions on creating a secret key'
      end
    end

    def create(data)
      OpenSSL::HMAC.hexdigest OpenSSL::Digest::SHA1.new, secret_key, data
    end

    def verify(signature, data)
      secure_compare OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, secret_key, data), signature
    end

    private

    def missing_secret_key?
      secret_key.nil? || secret_key.empty?
    end

    # After the Rack implementation
    def secure_compare(a, b)
      return false unless a.bytesize == b.bytesize

      l = a.unpack('C*')

      r, i = 0, -1
      b.each_byte { |v| r |= v ^ l[i += 1] }
      r == 0
    end
  end
end
