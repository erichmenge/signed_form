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

        gate_keeper = GateKeeper.new(self)

        gate_keeper.allowed_attributes.each do |k, v|
          params[k] = params.require(k).permit(*v)
        end
      rescue Errors::ExpiredForm
        if defined?(Rails)
          render 'signed_form/expired_form', status: 500, layout: nil
        else
          raise
        end
      end
    end

    class GateKeeper
      attr_reader :allowed_attributes

      def initialize(controller)
        @controller = controller
        @params     = controller.params
        @request    = controller.request

        extract_and_verify_form_signature
        verify_destination
        verify_digest
      end

      def options
        @options ||= {}
      end

      def extract_and_verify_form_signature
        data, signature = @params['form_signature'].split('--', 2)
        hmac = SignedForm::HMAC.new secret_key: SignedForm.secret_key

        signature ||= ''

        raise Errors::InvalidSignature, "Form signature is not valid" unless hmac.verify signature, data

        @allowed_attributes = Marshal.load Base64.strict_decode64(data)
        @options            = allowed_attributes.delete(:_options_)
      end

      def verify_destination
        return unless options[:method] && options[:url]
        raise Errors::InvalidURL if options[:method].to_s.casecmp(@request.request_method) != 0
        url = @controller.url_for(options[:url])
        raise Errors::InvalidURL if url != @request.fullpath && url != @request.url
      end

      def verify_digest
        return unless options[:digest]

        return if options[:digest_expiration] && Time.now < options[:digest_expiration]

        digestor = options[:digest]
        given_digest = digestor.digest
        digestor.view_paths = @controller.view_paths.map(&:to_s)
        digestor.refresh
        raise Errors::ExpiredForm unless given_digest == digestor.to_s
      end
    end
  end
end
