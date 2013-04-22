require 'active_support'

module SignedForm
  module DigestStores
    class MemoryStore < ActiveSupport::Cache::MemoryStore; end
  end
end
