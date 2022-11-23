require 'spec_helper'

describe SignedForm::Digestor do
  let(:view_paths) { [File.join(File.dirname(__FILE__), 'fixtures', 'views')] }
  let(:template) { double(view_paths: view_paths) }

  before do
    def template.virtual_path=(path)
      @virtual_path = path
    end

    template.virtual_path = 'form'
  end

  it "should raise if template doesn't have view_paths" do
    template = double(view_paths: -> { raise NoMethodError })
    expect { SignedForm::Digestor.new(template) }.to raise_error(SignedForm::Errors::UnableToDigest)
  end

  it "should raise if the template doesn't have a virtual path" do
    template = double(view_paths: view_paths)
    expect { SignedForm::Digestor.new(template) }.to raise_error(SignedForm::Errors::UnableToDigest)

    template.instance_variable_set(:@virtual_path, 'form')
    digestor = SignedForm::Digestor.new(template)
    template.instance_variable_set(:@virtual_path, nil)
    expect { digestor << template }.to raise_error(SignedForm::Errors::UnableToDigest)
  end

  it "should not marshal view paths" do
    digestor = SignedForm::Digestor.new(template)

    digestor.view_paths.should_not be_empty

    data     = Marshal.dump digestor
    digestor = Marshal.load data

    digestor.view_paths.should be_empty
  end

  specify "#to_s should return the correct MD5 digest" do
    digestor = SignedForm::Digestor.new(template)
    digestor.to_s.should == "7a956713f33cabd57357c70025109e69"
    template.virtual_path = "_fields"
    digestor << template
    digestor.to_s.should == "6a161ab9978322e8251d809b3558ab1a"
  end

  specify "The view order should not affect the digest" do
    digestor = SignedForm::Digestor.new(template)
    template.virtual_path = '_fields'
    digestor << template

    digestor2 = SignedForm::Digestor.new(template)
    template.virtual_path = 'form'
    digestor2 << template
    digestor.to_s.should == digestor2.to_s
  end

  # Ruby 2.7 removed taint checking mechanism
  # https://blog.saeloun.com/2020/02/18/ruby-2-7-access-and-setting-of-safe-warned-will-become-global-variable.html
  it "should marshal and taint the digest", if: Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.7.0") do
    digestor = SignedForm::Digestor.new(template)
    data = Marshal.dump digestor
    digestor = Marshal.load data
    digestor.to_s.should be_tainted
  end

  it "should reset the digest if a template is added" do
    digestor = SignedForm::Digestor.new(template)
    first_digest = digestor.to_s
    template.virtual_path = '_fields'
    digestor << template
    digestor.to_s.should_not == first_digest
  end

  it "should be idempotent" do
    digestor = SignedForm::Digestor.new(template)
    first_digest = digestor.to_s
    digestor << template
    digestor.to_s.should == first_digest
  end
end
