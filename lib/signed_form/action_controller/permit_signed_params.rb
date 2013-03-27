module SignedForm
  module ActionController
    module PermitSignedParams
      def self.included(base)
        base.prepend_before_filter :permit_signed_form_data

        gem 'strong_parameters' unless defined?(::ActionController::Parameters)
      end

      def permit_signed_form_data
        return if request.method == 'GET' || params['form_signature'].blank?

        data, signature = params['form_signature'].split('--', 2)

        signature ||= ''

        raise Errors::InvalidSignature, "Form signature is not valid" unless SignedForm::HMAC.verify_hmac signature, data

        allowed_attributes = Marshal.load Base64.strict_decode64(data)
        options            = allowed_attributes.delete(:__options__)

        raise Errors::InvalidURL if options && (!options[:method].to_s.casecmp(request.method) || options[:url] != request.fullpath)

        allowed_attributes.each do |k, v|
          params[k] = params.require(k).permit(*v)
        end
      end
    end
  end
end
