require 'action_view'
require 'action_view/template'
require 'action_controller'
require 'active_model'
require 'action_controller'
require 'signed_form'

module SignedFormViewHelper
  include ActionView::Helpers::FormHelper
  include ActionView::RecordIdentifier       if defined?(ActionView::RecordIdentifier)
  include ActionController::RecordIdentifier if defined?(ActionController::RecordIdentifier)
  include SignedForm::ActionView::FormHelper

  def self.included(base)
    base.class_eval do
      attr_accessor :output_buffer
    end
  end

  def protect_against_forgery?
    false
  end

  def user_path(*)
    '/'
  end

  def get_data_from_form(content)
    Marshal.load Base64.strict_decode64(content.match(/name="form_signature" value="(.*)--/)[1])
  end
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true

  config.order = 'random'
end
