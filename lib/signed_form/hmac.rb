require 'openssl'

module SignedForm
  module HMAC
    class << self
      attr_accessor :secret_key

      def create_hmac(data)
        if secret_key.nil? || secret_key.empty?
          raise Errors::NoSecretKey, "Please consult the README for instructions on creating a secret key"
        end

        OpenSSL::HMAC.hexdigest OpenSSL::Digest::SHA1.new, secret_key, data
      end

      def verify_hmac(signature, data)
        if secret_key.nil? || secret_key.empty?
          raise Errors::NoSecretKey, "Please consult the README for instructions on creating a secret key"
        end

        secure_compare OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, secret_key, data), signature
      end

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
end
