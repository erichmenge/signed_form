require 'spec_helper'

class Controller < ActionController::Base
  include SignedForm::ActionController::PermitSignedParams

  public :permit_signed_form_data
end

describe SignedForm::ActionController::PermitSignedParams do
  let(:controller) { Controller.new }

  before do
    SignedForm::HMAC.secret_key = "abc123"

    Controller.any_instance.stub(request: double('request', method: 'POST', request_method: 'POST', fullpath: '/users', url: '/users'))
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

  it "should verify current url matches targeted url" do
    params = controller.params

    data      = Base64.strict_encode64(Marshal.dump("user" => [:name], :__options__ => { method: 'post', url: '/users'  }))
    signature = SignedForm::HMAC.create_hmac(data)

    params['form_signature'] = "#{data}--#{signature}"

    params.stub(:require).with('user').and_return(params)
    params.stub(:permit).with(:name).and_return(params)
    controller.request.should_receive(:fullpath).and_return '/users'
    controller.permit_signed_form_data
  end

  it "should reject if url doesn't match" do
    params = controller.params

    data      = Base64.strict_encode64(Marshal.dump("user" => [:name], :__options__ => { method: 'post', url: '/admin'  }))
    signature = SignedForm::HMAC.create_hmac(data)

    params['form_signature'] = "#{data}--#{signature}"

    params.stub(:require).with('user').and_return(params)
    params.stub(:permit).with(:name).and_return(params)

    expect { controller.permit_signed_form_data }.to raise_error(SignedForm::Errors::InvalidURL)
  end

  it "should reject if method doesn't match" do
    params = controller.params

    data      = Base64.strict_encode64(Marshal.dump("user" => [:name], :__options__ => { method: 'put', url: '/users'  }))
    signature = SignedForm::HMAC.create_hmac(data)

    params['form_signature'] = "#{data}--#{signature}"

    params.stub(:require).with('user').and_return(params)
    params.stub(:permit).with(:name).and_return(params)

    expect { controller.permit_signed_form_data }.to raise_error(SignedForm::Errors::InvalidURL)
  end
end
