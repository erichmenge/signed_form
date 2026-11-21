# frozen_string_literal: true

require 'spec_helper'

class SignedFormContractUser
  extend ActiveModel::Naming

  attr_accessor :name

  def to_key
    [1]
  end

  def persisted?
    false
  end
end

class SignedFormContractController < ActionController::Base
  include SignedForm::ActionController::PermitSignedParams

  public :permit_signed_form_data
end

RSpec.describe 'SignedForm form-to-controller contract' do
  include SignedFormViewHelper

  before do
    SignedForm.secret_key = 'contract-secret'
    SignedForm.options[:digest] = false
  end

  def signed_form_token(method: nil, sign_destination: true)
    options = {
      model: SignedFormContractUser.new,
      scope: :user,
      url: '/users',
      signed: true,
      sign_destination: sign_destination,
      digest: false
    }
    options[:method] = method if method

    html = if respond_to?(:form_with)
      form_with(**options) { |form| form.text_field(:name) }
    else
      form_for(options.delete(:model), options.merge(as: options.delete(:scope))) { |form| form.text_field(:name) }
    end
    html.match(/name="form_signature" value="([^"]+)"/)[1]
  end

  def token_payload(token)
    data, = token.split('--', 2)
    Marshal.load(Base64.strict_decode64(data))
  end

  def user_allowlist(payload)
    payload.key?('user') ? payload['user'] : payload.fetch(:user)
  end

  def tamper_allowlist(token)
    data, signature = token.split('--', 2)
    payload = Marshal.load(Base64.strict_decode64(data))
    user_allowlist(payload) << :admin
    tampered_data = Base64.strict_encode64(Marshal.dump(payload))
    "#{tampered_data}--#{signature}"
  end

  def contract_controller(parameters, request_method: 'POST', path: '/users')
    controller = SignedFormContractController.new
    strong_parameters = ActionController::Parameters.new(parameters)
    request = double(
      'Request',
      method: request_method,
      request_method: request_method,
      fullpath: path,
      url: path,
      variant: nil
    )

    allow(controller).to receive(:params).and_return(strong_parameters)
    allow(controller).to receive(:request).and_return(request)
    allow(controller).to receive(:url_for) { |value| value }

    controller
  end

  it 'puts the rendered field and POST destination inside the authenticated token' do
    payload = token_payload(signed_form_token)

    expect(user_allowlist(payload)).to eq([:name])
    expect(payload[:_options_]).to include(method: :post, url: '/users')
  end

  it 'round-trips a rendered signed form through the real strong-parameters path' do
    token = signed_form_token
    controller = contract_controller(
      {
        'user' => { 'name' => 'Ada', 'admin' => '1' },
        'form_signature' => token
      }
    )

    controller.permit_signed_form_data

    permitted_user = controller.params['user']
    expect(permitted_user).to be_permitted
    expect(permitted_user.to_h).to eq('name' => 'Ada')
  end

  it 'filters unsigned nested and scalar parameters while preserving signed nested fields' do
    token = SignedForm.tokenize(
      'user' => [:name, { preferences: [:theme] }]
    )
    controller = contract_controller(
      {
        'user' => {
          'name' => 'Ada',
          'admin' => '1',
          'preferences' => { 'theme' => 'dark', 'role' => 'root' }
        },
        'form_signature' => token
      }
    )

    controller.permit_signed_form_data

    expect(controller.params['user'].to_h).to eq(
      'name' => 'Ada',
      'preferences' => { 'theme' => 'dark' }
    )
  end

  it 'rejects a client that adds a field to the signed allowlist without the key' do
    token = tamper_allowlist(signed_form_token)
    controller = contract_controller(
      {
        'user' => { 'name' => 'Ada', 'admin' => '1' },
        'form_signature' => token
      }
    )

    expect { controller.permit_signed_form_data }
      .to raise_error(SignedForm::Errors::InvalidSignature)
    expect(controller.params['user']).not_to be_permitted
  end

  it 'rejects a valid rendered form replayed to a different path' do
    controller = contract_controller(
      {
        'user' => { 'name' => 'Ada' },
        'form_signature' => signed_form_token
      },
      path: '/admin/users'
    )

    expect { controller.permit_signed_form_data }
      .to raise_error(SignedForm::Errors::InvalidURL)
  end

  it 'rejects a valid rendered form replayed with a different HTTP method' do
    controller = contract_controller(
      {
        'user' => { 'name' => 'Ada' },
        'form_signature' => signed_form_token
      },
      request_method: 'PATCH'
    )

    expect { controller.permit_signed_form_data }
      .to raise_error(SignedForm::Errors::InvalidURL)
  end

  it 'honors an explicitly signed HTTP method' do
    token = signed_form_token(method: :patch)
    expect(token_payload(token)[:_options_][:method]).to eq(:patch)

    controller = contract_controller(
      {
        'user' => { 'name' => 'Ada' },
        'form_signature' => token
      },
      request_method: 'PATCH'
    )

    expect { controller.permit_signed_form_data }.not_to raise_error
    expect(controller.params['user'].to_h).to eq('name' => 'Ada')
  end

  it 'allows destination checks to be explicitly disabled without disabling field signing' do
    token = signed_form_token(sign_destination: false)
    expect(token_payload(token)[:_options_]).not_to include(:method, :url)

    controller = contract_controller(
      {
        'user' => { 'name' => 'Ada', 'admin' => '1' },
        'form_signature' => token
      },
      request_method: 'DELETE',
      path: '/somewhere-else'
    )

    controller.permit_signed_form_data

    expect(controller.params['user'].to_h).to eq('name' => 'Ada')
  end

  it 'leaves an unsigned POST unpermitted instead of silently trusting it' do
    controller = contract_controller(
      { 'user' => { 'name' => 'Ada', 'admin' => '1' } }
    )

    expect { controller.permit_signed_form_data }.not_to raise_error
    expect(controller.params['user']).not_to be_permitted
  end

  it 'does not try to authenticate or permit GET parameters' do
    controller = contract_controller(
      {
        'user' => { 'name' => 'Ada', 'admin' => '1' },
        'form_signature' => 'not-a-valid-token'
      },
      request_method: 'GET'
    )

    expect { controller.permit_signed_form_data }.not_to raise_error
    expect(controller.params['user']).not_to be_permitted
  end
end
