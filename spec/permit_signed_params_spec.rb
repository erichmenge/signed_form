require 'spec_helper'

class Controller < ActionController::Base
  include SignedForm::ActionController::PermitSignedParams

  public :permit_signed_form_data

  def view_paths
    [File.join(File.dirname(__FILE__), 'fixtures', 'views')]
  end
end

describe SignedForm::ActionController::PermitSignedParams do
  let(:controller) { Controller.new }
  let(:hmac)       { SignedForm::HMAC.new(secret_key: SignedForm.secret_key) }
  let(:params)     { controller.params }
  let(:template)   { double(view_paths: [File.join(File.dirname(__FILE__), 'fixtures', 'views')], virtual_path: 'form') }
  let(:digestor)   { SignedForm::Digestor.new(template) }

  def marshal_and_sign(data)
    encoded_data = Base64.strict_encode64(Marshal.dump(data))
    signature = hmac.create(encoded_data)
    "#{encoded_data}--#{signature}"
  end

  Object.send(:remove_const, :Rails) if defined?(Rails)

  before do
    SignedForm.secret_key = "abc123"

    Controller.any_instance.stub(request: double('request', method: 'POST', request_method: 'POST', fullpath: '/users', url: '/users', variant: nil))
    Controller.any_instance.stub(params: { "user" => { name: "Erich Menge", occupation: 'developer' } })

    params.stub(:[]).and_call_original
    params.stub(:[]).with('user').and_return(params)
  end

  it "should raise if signature isn't valid" do
    params['form_signature'] = "bad signature"
    expect { controller.permit_signed_form_data }.to raise_error(SignedForm::Errors::InvalidSignature)
  end

  context "when the parameters are good" do
    before { params.should_receive(:permit).with(:name).and_return(params) }

    it "should permit attributes that are allowed" do
      params['form_signature'] = marshal_and_sign "user" => [:name]
      controller.permit_signed_form_data
    end

    it "should verify current url matches targeted url" do
      params['form_signature'] = marshal_and_sign("user" => [:name], :_options_ => { method: 'post', url: '/users'  })

      controller.request.should_receive(:fullpath).and_return '/users'
      controller.permit_signed_form_data
    end
  end

  it "should reject if url doesn't match" do
    params['form_signature'] = marshal_and_sign("user" => [:name], :_options_ => { method: 'post', url: '/admin' })
    expect { controller.permit_signed_form_data }.to raise_error(SignedForm::Errors::InvalidURL)
  end

  it "should reject if the method doesn't match" do
    params['form_signature'] = marshal_and_sign("user" => [:name], :_options_ => { method: 'put', url: '/users' })
    expect { controller.permit_signed_form_data }.to raise_error(SignedForm::Errors::InvalidURL)
  end

  context "when the digest is bad" do
    before { digestor.stub(:to_s).and_return "bad" }

    it "should not reject if inside grace period" do
      params['form_signature'] = marshal_and_sign("user" => [:name], :_options_ => { digest: digestor, digest_expiration: Time.now + 20 })
      expect { controller.permit_signed_form_data }.not_to raise_error(SignedForm::Errors::ExpiredForm)
    end

    it "should reject if outside the grace period" do
      params['form_signature'] = marshal_and_sign("user" => [:name], :_options_ => { digest: digestor, digest_expiration: Time.now - 20 })
      expect { controller.permit_signed_form_data }.to raise_error(SignedForm::Errors::ExpiredForm)
    end

    it "should reject if no grace period" do
      params['form_signature'] = marshal_and_sign("user" => [:name], :_options_ => { digest: digestor })
      expect { controller.permit_signed_form_data }.to raise_error(SignedForm::Errors::ExpiredForm)
    end
  end

  context "when the digest is good" do
    it "should not reject if outside grace period" do
      params['form_signature'] = marshal_and_sign("user" => [:name], :_options_ => { digest: digestor, digest_expiration: Time.now - 20 })
      expect { controller.permit_signed_form_data }.not_to raise_error(SignedForm::Errors::ExpiredForm)
    end

    it "should not reject if no grace period" do
      params['form_signature'] = marshal_and_sign("user" => [:name], :_options_ => { digest: digestor })
      expect { controller.permit_signed_form_data }.not_to raise_error(SignedForm::Errors::ExpiredForm)
    end
  end
end
