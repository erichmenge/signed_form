require 'logger'
require 'rails'
require 'action_view'
require 'action_view/template'
require 'action_controller'
require 'active_model'
require 'action_controller/test_case'
require 'active_support/core_ext'
require 'base64'
require 'signed_form'

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

  def url_for(options = {})
    case options
    when String
      options
    when Hash
      # In reality, Rails hits `routes.url_for` here
      options.empty? ? "/some/path" : "/some/path?#{options.to_a.join('=')}"
    else
      "/some/path"
    end
  end

  def polymorphic_path(model, options = {})
    path = if model.persisted?
      "/users/#{model.to_key.join}"
    else
      "/users/new"
    end

    if options[:format]
      "#{path}.#{options[:format]}"
    else
      path
    end
  end

  def controller(*)
    double('controller')
  end

  def get_data_from_form(content)
    Marshal.load Base64.strict_decode64(content.match(/name="form_signature" value="(.*)--/)[1])
  end
end

module Helpers
  def rails_version_satisfies?(ver)
    Gem::Requirement.new(ver).satisfied_by?(ActionPack::gem_version)
  end
end

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true

  config.expect_with(:rspec) { |c| c.syntax = [:expect, :should] }

  config.order = 'random'

  config.extend Helpers

  config.after do
    SignedForm.secret_key = nil
    SignedForm.options = SignedForm::DEFAULT_OPTIONS.dup
    SignedForm.digest_store = SignedForm::DigestStores::NullStore.new
  end
end
