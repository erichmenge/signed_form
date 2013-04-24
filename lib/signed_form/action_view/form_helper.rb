module SignedForm
  module ActionView
    module FormHelper

      # This is a wrapper around ActionView's form_for helper.
      #
      # @option options :sign_destination [Boolean] Only the URL given/created will be allowed to receive the form.
      # @option options :digest [Boolean] Digest and verify the views have not been modified
      # @option options :digest_grace_period [Integer] Time in seconds to allow old forms
      # @option options :wrap_form [Symbol] Method of a form builder to wrap. Default is form_for
      def signed_form_for(record, options = {}, &block)
        options_for_form = SignedForm.options.merge options
        options_for_form[:builder] ||= SignedForm::FormBuilder

        send SignedForm.options[:wrap_form], record, options_for_form do |f|
          output = capture(f, &block)
          f.form_signature_tag + output
        end
      end
    end
  end
end

ActionView::Base.send :include, SignedForm::ActionView::FormHelper
