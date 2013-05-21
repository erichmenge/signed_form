module SignedForm
  module ActionView
    module FormHelper

      # @option options :sign_destination [Boolean] Only the URL given/created will be allowed to receive the form.
      # @option options :digest [Boolean] Digest and verify the views have not been modified
      # @option options :digest_grace_period [Integer] Time in seconds to allow old forms
      # @option options :wrap_form [Symbol] Method of a form builder to wrap. Default is form_for
      def form_for(record, options = {}, &block)
        return super unless options[:signed]

        options_for_form = SignedForm.options.merge options
        options_for_form[:builder] ||= ::ActionView::Helpers::FormBuilder

        ancestors = options_for_form[:builder].ancestors

        if !ancestors.include?(::ActionView::Helpers::FormBuilder) && !ancestors.include?(SignedForm::FormBuilder)
          raise "Form signing not supported on builders that don't subclass ActionView::Helpers::FormBuilder or include SignedForm::FormBuilder"
        elsif !ancestors.include?(SignedForm::FormBuilder)
          options_for_form[:builder] = SignedForm::FormBuilder::BUILDERS[options_for_form[:builder]]
        end

        super record, options_for_form do |f|
          output = capture(f, &block)
          f.form_signature_tag + output
        end
      end
    end
  end
end

ActionView::Base.send :include, SignedForm::ActionView::FormHelper
