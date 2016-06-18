module SignedForm
  module ActionController

    # This module is required for parameter verification on the controller.
    # Include it in controllers that will be receiving signed forms.
    module PermitSignedParams
      def self.included(base)
        if base.respond_to? :prepend_before_action
            base.prepend_before_action :permit_signed_form_data
        else
            base.prepend_before_filter :permit_signed_form_data
        end

        gem 'strong_parameters' unless defined?(::ActionController::Parameters)
      end

      protected

      def permit_signed_form_data
        return if request.method == 'GET' || params['form_signature'].blank?

        gate_keeper = GateKeeper.new(self)

        gate_keeper.allowed_attributes.each do |k, v|
          next if params[k].nil? || v.empty?
          params[k] = params[k].permit(*v)
        end
      rescue Errors::ExpiredForm
        if defined?(Rails)
          render 'signed_form/expired_form', status: 500, layout: nil
        else
          raise
        end
      end
    end
  end
end
