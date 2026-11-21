# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SignedForm::SignedData do
  let(:secret_key) { 'signed-data-secret' }
  let(:signed_data) { described_class.new(secret_key: secret_key) }
  let(:payload) do
    {
      'user' => [:name, { preferences: [:theme] }],
      _options_: { method: :post, url: '/users' }
    }
  end

  def legacy_token(value, secret: secret_key)
    data = Base64.strict_encode64(Marshal.dump(value))
    signature = SignedForm::HMAC.new(secret_key: secret).create(data)
    "#{data}--#{signature}"
  end

  it 'round-trips authenticated Ruby data' do
    expect(signed_data.verify(signed_data.sign(payload))).to eq(payload)
  end

  it 'emits the exact legacy SignedForm wire format' do
    expect(signed_data.sign(payload)).to eq(legacy_token(payload))
  end

  it 'accepts tokens emitted before the codec was extracted' do
    expect(signed_data.verify(legacy_token(payload))).to eq(payload)
  end

  it 'binds tokens to the signing key' do
    token = signed_data.sign(payload)
    other_key = described_class.new(secret_key: 'different-secret')

    expect { other_key.verify(token) }
      .to raise_error(SignedForm::Errors::InvalidSignature)
  end

  it 'rejects a changed payload without deserializing it' do
    token = signed_data.sign(payload)
    data, signature = token.split('--', 2)
    tampered = Base64.strict_encode64(Marshal.dump('admin' => true))

    expect(Marshal).not_to receive(:load)
    expect { signed_data.verify("#{tampered}--#{signature}") }
      .to raise_error(SignedForm::Errors::InvalidSignature)
  end

  it 'rejects a changed signature' do
    data, signature = signed_data.sign(payload).split('--', 2)
    changed = signature.dup
    changed[0] = changed[0] == '0' ? '1' : '0'

    expect { signed_data.verify("#{data}--#{changed}") }
      .to raise_error(SignedForm::Errors::InvalidSignature)
  end

  it 'rejects missing and structurally malformed tokens consistently' do
    [nil, {}, [], '', 'not-a-token', '--'].each do |token|
      expect { signed_data.verify(token) }
        .to raise_error(SignedForm::Errors::InvalidSignature)
    end
  end
end
