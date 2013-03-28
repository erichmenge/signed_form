require 'spec_helper'

describe SignedForm::HMAC do
  describe 'create_hmac' do
    it 'should raise if no key is given' do
      expect { SignedForm::HMAC.create_hmac "foo" }.to raise_error(SignedForm::Errors::NoSecretKey)
    end

    context 'when a key is present' do
      before { SignedForm::HMAC.secret_key = "superdupersecret" }
      after  { SignedForm::HMAC.secret_key = nil }

      it 'should create a hex signature' do
        SignedForm::HMAC.create_hmac("my signed message").length.should == 40
      end
    end
  end

  describe 'verify_hmac' do
    it 'should raise if no key is given' do
      expect { SignedForm::HMAC.verify_hmac 'foo', 'bar' }.to raise_error(SignedForm::Errors::NoSecretKey)
    end

    context 'when a key is present' do
      before { SignedForm::HMAC.secret_key = "superdupersecret" }
      after  { SignedForm::HMAC.secret_key = nil }

      let(:signature) { SignedForm::HMAC.create_hmac "My super secret" }

      specify { SignedForm::HMAC.verify_hmac(signature, "My super secret").should be_true }
      specify { SignedForm::HMAC.verify_hmac(signature, "My bad secret").should_not be_true }
    end
  end
end
