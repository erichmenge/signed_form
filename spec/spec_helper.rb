require 'action_view'
require 'action_view/template'
require 'action_controller'
require 'active_model'
require 'action_controller'
require 'active_support/core_ext'

require 'coveralls'
Coveralls.wear! do
  add_filter "/spec/"
end

require 'signed_form'

class ControllerRenderer < AbstractController::Base
  include AbstractController::Rendering
  self.view_paths = [ActionView::FileSystemResolver.new(File.join(File.dirname(__FILE__), 'fixtures', 'views'))]

  view_context_class.class_eval do
    def url_for(*args)
      '/users'
    end

  def to_key
    [1]
  end
end

module SignedFormViewHelper
  include ActionView::Helpers

  if defined?(ActionView::RecordIdentifier)
    include ActionView::RecordIdentifier
  elsif defined?(ActionController::RecordIdentifier)
    include ActionController::RecordIdentifier
  end

  include ActionView::Context if defined?(ActionView::Context)
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
    '/users'
  end

  def polymorphic_path(*)
    '/users'
  end

  def _routes(*)
    double('routes', url_for: '')
  end

  def controller(*)
    double('controller')
  end

  def default_url_options
    {}
  end

  def get_data_from_form(content)
    Marshal.load Base64.strict_decode64(content.match(/name="form_signature" value="(.*)--/)[1])
  end
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true

  config.filter_run_excluding action_pack: ->(version) { ActionPack::VERSION::STRING.match(/\d+\.\d+/)[0] !~ version }

  config.order = 'random'

  config.around(:each) do |example|
    prestine_module = SignedForm.dup
    example.run
    Object.send :remove_const, :SignedForm
    SignedForm = prestine_module
  end
end
