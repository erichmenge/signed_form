require 'spec_helper'

describe SignedForm::HMAC do
  describe 'key selection' do
    it 'raises when neither an explicit key nor a Rails key exists' do
      allow(Rails).to receive(:application).and_return(nil)

      expect { described_class.new }.to raise_error(SignedForm::Errors::NoSecretKey)
    end

    it 'uses Rails.application.secret_key_base when no key is supplied' do
      application = double('Rails application', secret_key_base: 'rails-secret-key')
      allow(Rails).to receive(:application).and_return(application)

      expect(described_class.new.secret_key).to eq('rails-secret-key')
    end

    it 'falls back to Rails.application.secret_key_base for an empty explicit key' do
      application = double('Rails application', secret_key_base: 'rails-secret-key')
      allow(Rails).to receive(:application).and_return(application)

      expect(described_class.new(secret_key: '').secret_key).to eq('rails-secret-key')
    end

    it 'prefers an explicit key without consulting the Rails application' do
      expect(Rails).not_to receive(:application)

      expect(described_class.new(secret_key: 'explicit-key').secret_key).to eq('explicit-key')
    end
  end

  describe 'create' do
    let(:hmac) { described_class.new(secret_key: 'superdupersecret') }

    it 'creates the stable SHA1 HMAC expected by existing signed forms' do
      expect(hmac.create('my signed message')).to eq('93c1ecd4c10122cbf873ca6cf9eff08888565054')
    end

    it 'returns a 40-character hexadecimal signature' do
      expect(hmac.create('my signed message')).to match(/\A[0-9a-f]{40}\z/)
    end

    it 'binds the signature to the secret key' do
      other_hmac = described_class.new(secret_key: 'different-secret')

      expect(other_hmac.create('my signed message')).not_to eq(hmac.create('my signed message'))
    end
  end

  describe 'verify' do
    let(:hmac) { described_class.new(secret_key: 'superdupersecret') }
    let(:data) { 'My super secret' }
    let(:signature) { hmac.create(data) }

    it 'accepts the exact signature for the exact data' do
      expect(hmac.verify(signature, data)).to be(true)
    end

    it 'rejects the right signature for different data' do
      expect(hmac.verify(signature, 'My bad secret')).to be(false)
    end

    it 'rejects a same-length signature with one changed byte' do
      tampered_signature = signature.dup
      tampered_signature[0] = signature[0] == '0' ? '1' : '0'

      expect(hmac.verify(tampered_signature, data)).to be(false)
    end

    it 'rejects truncated and empty signatures without raising' do
      expect(hmac.verify(signature[0...-1], data)).to be(false)
      expect(hmac.verify('', data)).to be(false)
    end
  end
end
