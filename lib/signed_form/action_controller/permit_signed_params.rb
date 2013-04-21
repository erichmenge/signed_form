module SignedForm
  module ActionController

    # This module is required for parameter verification on the controller.
    # Include it in controllers that will be receiving signed forms.
    module PermitSignedParams
      def self.included(base)
        base.prepend_before_filter :permit_signed_form_data

        gem 'strong_parameters' unless defined?(::ActionController::Parameters)
      end

      protected

      def permit_signed_form_data
        return if request.method == 'GET' || params['form_signature'].blank?

        data, signature = params['form_signature'].split('--', 2)

        signature ||= ''

        raise Errors::InvalidSignature, "Form signature is not valid" unless SignedForm.hmac.verify signature, data

        allowed_attributes = Marshal.load Base64.strict_decode64(data)
        options            = allowed_attributes.delete(:_options_)

        if options
          if options[:method].to_s.casecmp(request.request_method) != 0
            raise Errors::InvalidURL
          end
          url = url_for(options[:url])
          if url != request.fullpath and url != request.url
            raise Errors::InvalidURL
          end
        end

        allowed_attributes.each do |k, v|
          params[k] = params.require(k).permit(*v)
        end
      end
    end
  end
end
