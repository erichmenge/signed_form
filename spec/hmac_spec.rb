require 'spec_helper'

describe SignedForm::HMAC do
  it 'should raise if no key is given' do
    expect { SignedForm::HMAC.new }.to raise_error(SignedForm::Errors::NoSecretKey)
  end

  describe 'create' do
    let(:hmac) { SignedForm::HMAC.new(secret_key: "superdupersecret") }

    it 'should create a hex signature' do
      hmac.create("my signed message").length.should == 40
      hmac.create("my signed message").should == "93c1ecd4c10122cbf873ca6cf9eff08888565054"
    end
  end

  describe 'verify' do
    let(:hmac) { SignedForm::HMAC.new(secret_key: "superdupersecret") }
    let(:signature) { hmac.create "My super secret" }

    specify { hmac.verify(signature, "My super secret").should be_truthy }
    specify { hmac.verify(signature, "My bad secret").should_not be_truthy }
  end
end
