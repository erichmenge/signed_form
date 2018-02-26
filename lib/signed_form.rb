require "action_view"
require "action_controller"

require "signed_form/version"
require "signed_form/errors"
require "signed_form/form_builder"
require "signed_form/hmac"
require "signed_form/digest_stores"
require "signed_form/digestor"
require "signed_form/action_view/form_helper"
require "signed_form/gate_keeper"
require "signed_form/action_controller/permit_signed_params"

module SignedForm
  DEFAULT_OPTIONS = {
    sign_destination:    true,
    digest:              true,
    digest_grace_period: 300,
    signed:              false
  }.freeze

  class << self
    attr_accessor :secret_key

    attr_writer :options
    def options
      @options ||= DEFAULT_OPTIONS.dup
    end

    attr_writer :digest_store
    def digest_store
      @digest_store ||= SignedForm::DigestStores::NullStore.new
    end

    def config
      yield self
    end
  end
end
