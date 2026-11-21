# frozen_string_literal: true

require 'spec_helper'

module SignedForm
  RSpec.describe GateKeeper do
    before { SignedForm.secret_key = 'hunter2' }

    let(:allowed_attributes) { { 'user' => [:name] } }
    let(:signed_options) { {} }
    let(:token_attributes) do
      allowed_attributes.merge(signed_options.empty? ? {} : { _options_: signed_options })
    end
    let(:token) { SignedForm.tokenize(token_attributes) }
    let(:request_method) { 'POST' }
    let(:request_fullpath) { '/posts/1/comments/2' }
    let(:request_url) { "http://www.example.com#{request_fullpath}" }
    let(:request) do
      double(
        'Request',
        fullpath: request_fullpath,
        url: request_url,
        request_method: request_method
      )
    end
    let(:controller) do
      double('Controller', params: { 'form_signature' => token }, request: request).tap do |instance|
        allow(instance).to receive(:url_for) { |value| value }
      end
    end

    subject(:gate_keeper) { described_class.new(controller) }

    it 'returns the authenticated allowlist' do
      expect(gate_keeper.allowed_attributes).to eq('user' => [:name])
    end

    it 'removes signed transport options from the attribute allowlist' do
      signed_options.merge!(method: :post, url: request_fullpath)

      expect(gate_keeper.allowed_attributes).to eq('user' => [:name])
      expect(gate_keeper.options).to eq(method: :post, url: request_fullpath)
    end

    it 'accepts a signed destination that matches the request fullpath' do
      signed_options.merge!(method: :post, url: request_fullpath)

      expect { gate_keeper }.not_to raise_error
    end

    it 'accepts a signed absolute destination that matches request.url' do
      signed_options.merge!(method: :post, url: request_url)

      expect { gate_keeper }.not_to raise_error
    end

    it 'compares the signed request method case-insensitively' do
      signed_options.merge!(method: 'post', url: request_fullpath)

      expect { gate_keeper }.not_to raise_error
    end

    it 'ignores a fragment when verifying the signed destination' do
      signed_options.merge!(method: :post, url: "#{request_url}#return-here")

      expect { gate_keeper }.not_to raise_error
    end

    it 'rejects a request sent to a different path' do
      signed_options.merge!(method: :post, url: '/admin')

      expect { gate_keeper }.to raise_error(SignedForm::Errors::InvalidURL)
    end

    it 'rejects a request whose query string differs from the signed destination' do
      signed_options.merge!(method: :post, url: "#{request_fullpath}?admin=1")

      expect { gate_keeper }.to raise_error(SignedForm::Errors::InvalidURL)
    end

    it 'rejects a request made with a different HTTP method' do
      signed_options.merge!(method: :patch, url: request_fullpath)

      expect { gate_keeper }.to raise_error(SignedForm::Errors::InvalidURL)
    end

    it 'rejects an allowlist changed after it was signed' do
      data, signature = token.split('--', 2)
      attributes = Marshal.load(Base64.strict_decode64(data))
      attributes['user'] << :admin
      tampered_data = Base64.strict_encode64(Marshal.dump(attributes))
      allow(controller).to receive(:params).and_return(
        'form_signature' => "#{tampered_data}--#{signature}"
      )

      expect { described_class.new(controller) }
        .to raise_error(SignedForm::Errors::InvalidSignature)
    end

    it 'rejects a changed signature' do
      data, signature = token.split('--', 2)
      tampered_signature = signature.dup
      tampered_signature[0] = signature[0] == '0' ? '1' : '0'
      allow(controller).to receive(:params).and_return(
        'form_signature' => "#{data}--#{tampered_signature}"
      )

      expect { described_class.new(controller) }
        .to raise_error(SignedForm::Errors::InvalidSignature)
    end

    it 'rejects a malformed token instead of accepting an empty signature' do
      allow(controller).to receive(:params).and_return('form_signature' => 'not-a-token')

      expect { described_class.new(controller) }
        .to raise_error(SignedForm::Errors::InvalidSignature)
    end
  end
end
