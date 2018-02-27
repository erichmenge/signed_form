# frozen_string_literal: true

module SignedForm
  RSpec.describe GateKeeper do
    before do
      SignedForm.config do |c|
        c.secret_key = 'hunter2'
      end
    end

    let :url do
      'http://www.example.com/posts/1/comments/2'
    end

    let :controller do
      attributes = { 'foo' => 'bar' }
      double(
        'Controller',
        params: attributes.merge(
          'form_signature' => SignedForm.tokenize(attributes)
        ),
        request: double(
          'Request',
          fullpath: url,
          url: url,
          request_method: 'GET'
        ),
        url_for: url
      )
    end

    subject do
      GateKeeper.new controller
    end

    it 'ignores anchor when verifying url' do
      allow(subject).to receive(:options).and_return(
        method: :get,
        url: "#{url}#redirect_to=back"
      )

      expect(subject.verify_destination).to be(nil)
    end

    it 'raises error when url is invalid' do
      allow(controller.request).to receive(:fullpath).and_return('foo')
      allow(subject).to receive(:options).and_return(method: :get, url: url)

      expect(subject.verify_destination).to be(nil)
    end
  end
end
