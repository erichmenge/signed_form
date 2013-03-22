require 'spec_helper'

class User
  extend ActiveModel::Naming

  attr_accessor :name

  def to_key
    [1]
  end
end

describe SignedForm::FormBuilder do
  include SignedFormViewHelper

  before { SignedForm::HMAC.secret_key = "abc123" }
  after  { SignedForm::HMAC.secret_key = nil }

  describe "signed_form_for" do
    it "should build a form with signature" do
      content = signed_form_for(User.new) do |f|
        f.text_field :name
      end

      regex = '<form.*>.*<input type="hidden" name="form_signature" ' \
              'value="BAhDOi1BY3RpdmVTdXBwb3J0OjpIYXNoV2l0aEluZGlmZmVy' \
              'ZW50QWNjZXNzewZJIgl1c2VyBjoGRUZbBjoJbmFtZQ==--17dd04878890cd6e1c9ed8192c3e5dfd42c1f8de" />.*' \
              '<input.*name="user\[name\]".*/>.*' \
              '</form>'

      content.should =~ Regexp.new(regex, Regexp::MULTILINE)
    end
  end

  describe "additional_signed_fields" do
    it "should add fields to the marshaled data" do
      content = signed_form_for(User.new) do |f|
        f.additional_signed_fields :name, :address
      end

      data = get_data_from_form(content)
      data['user'].should include(:name, :address)
      data['user'].size.should == 2
    end
  end
end

