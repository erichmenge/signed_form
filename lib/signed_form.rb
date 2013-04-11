require "action_view"
require "action_controller"

require "signed_form/version"
require "signed_form/errors"
require "signed_form/form_builder"
require "signed_form/hmac"
require "signed_form/action_view/form_helper"
require "signed_form/action_controller/permit_signed_params"

module SignedForm
  DEFAULT_OPTIONS = {
    sign_destination: true
  }.freeze

  class << self
    attr_reader :secret_key
    def secret_key=(key)
      @secret_key = key
      hmac.secret_key = key if @hmac
    end

    attr_writer :options
    def options
      @options ||= DEFAULT_OPTIONS.dup
    end

    attr_writer :hmac
    def hmac
      @hmac ||= SignedForm::HMAC.new(secret_key: secret_key)
    end

    def config
      yield self
    end
  end
end
