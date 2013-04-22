module SignedForm
  module Errors
    class NoSecretKey      < StandardError; end
    class InvalidSignature < StandardError; end
    class InvalidURL       < StandardError; end
    class UnableToDigest   < StandardError; end
    class ExpiredForm      < StandardError; end
  end
end
