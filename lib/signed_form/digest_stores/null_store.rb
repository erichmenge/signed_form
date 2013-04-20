module SignedForm
  module DigestStores
    class NullStore
      def fetch(key)
        yield
      end
    end
  end
end
