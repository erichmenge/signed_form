module SignedForm
  module ActionView
    module FormHelper

      # This is a wrapper around ActionView's form_for helper.
      #
      # @option options :sign_destination [Boolean] Only the URL given/created will be allowed to receive the form.
      def signed_form_for(record, options = {}, &block)
        options_for_form = SignedForm.options.merge options
        options_for_form[:builder] ||= SignedForm::FormBuilder

        form_for(record, options_for_form) do |f|
          output = capture(f, &block)
          f.form_signature_tag + output
        end
      end
    end
  end
end

ActionView::Base.send :include, SignedForm::ActionView::FormHelper
