# frozen_string_literal: true

require 'base64'
require 'signed_form/errors'
require 'signed_form/hmac'

module SignedForm
  # The authenticated-data boundary used by signed forms.
  #
  # This intentionally preserves SignedForm's original wire format so forms
  # rendered by older releases remain valid while signing is separated from
  # Rails-specific form and controller concerns.
  class SignedData
    SEPARATOR = '--'.freeze
    INVALID_SIGNATURE = 'Form signature is not valid'.freeze

    def initialize(secret_key:)
      @hmac = HMAC.new(secret_key: secret_key)
    end

    def sign(value)
      data = Base64.strict_encode64(Marshal.dump(value))
      signature = @hmac.create(data)

      "#{data}#{SEPARATOR}#{signature}"
    end

    def verify(token)
      data, signature = split(token)

      invalid_signature! unless @hmac.verify(signature, data)

      Marshal.load(Base64.strict_decode64(data))
    end

    private

    def split(token)
      invalid_signature! unless token.is_a?(String)

      data, signature = token.split(SEPARATOR, 2)
      invalid_signature! if data.nil? || data.empty? || signature.nil? || signature.empty?

      [data, signature]
    end

    def invalid_signature!
      raise Errors::InvalidSignature, INVALID_SIGNATURE
    end
  end
end
