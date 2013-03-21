module SignedForm
  module Errors
    class NoSecretKey < StandardError; end
    class InvalidSignature < StandardError; end
  end
end
