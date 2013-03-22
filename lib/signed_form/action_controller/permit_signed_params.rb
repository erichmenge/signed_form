module SignedForm
  module PermitSignedParams
    def permit_signed_form_data
      return if request.method == 'GET' || params['form_signature'].blank?

      data, signature = params['form_signature'].split('--', 2)

      signature ||= ''

      raise Errors::InvalidSignature, "Form signature is not valid" unless SignedForm::HMAC.verify_hmac signature, data
      allowed_attributes = Marshal.load Base64.strict_decode64(data)

      allowed_attributes.each do |k, v|
        params[k] = params.require(k).permit(*v)
      end
    end
  end
end

ActionController::Base.send :include, SignedForm::PermitSignedParams
ActionController::Base.prepend_before_filter :permit_signed_form_data

