require 'spec_helper'

describe SignedForm do
  it "should reset the hmac object secret key if the secret key changes" do
    SignedForm.secret_key = "foo"

    SignedForm.hmac.secret_key.should == "foo"
    SignedForm.secret_key = "bar"
    SignedForm.hmac.secret_key.should == "bar"
  end
end
