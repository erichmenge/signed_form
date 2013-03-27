require 'spec_helper'

class Controller < ActionController::Base
  include SignedForm::ActionController::PermitSignedParams
end

describe SignedForm::ActionController::PermitSignedParams do
  let(:controller) { Controller.new }

  before do
    SignedForm::HMAC.secret_key = "abc123"

    Controller.any_instance.stub(request: double('request', method: 'POST'))
    Controller.any_instance.stub(params: { "user" => { name: "Erich Menge", occupation: 'developer' } })
  end

  after  { SignedForm::HMAC.secret_key = nil }

  it "should raise if signature isn't valid" do
    controller.params['form_signature'] = "bad signature"
    expect { controller.permit_signed_form_data }.to raise_error(SignedForm::Errors::InvalidSignature)
  end

  it "should permit attributes that are allowed" do
    params = controller.params

    data      = Base64.strict_encode64(Marshal.dump("user" => [:name]))
    signature = SignedForm::HMAC.create_hmac(data)

    params['form_signature'] = "#{data}--#{signature}"

    params.should_receive(:require).with('user').and_return(params)
    params.should_receive(:permit).with(:name).and_return(params)
    controller.permit_signed_form_data
  end
end
