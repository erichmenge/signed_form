module SignedForm
  module ActionView
    module FormHelper

      # @option options :sign_destination [Boolean] Only the URL given/created will be allowed to receive the form.
      # @option options :digest [Boolean] Digest and verify the views have not been modified
      # @option options :digest_grace_period [Integer] Time in seconds to allow old forms
      # @option options :wrap_form [Symbol] Method of a form builder to wrap. Default is form_for
      def form_for(record, options = {}, &block)
        if options[:signed].nil? && !SignedForm.options[:signed] || !options[:signed].nil? && !options[:signed]
          return super
        end

        options = SignedForm.options.merge options
        options[:builder] ||= ::ActionView::Helpers::FormBuilder

        ancestors = options[:builder].ancestors

        if !ancestors.include?(::ActionView::Helpers::FormBuilder) && !ancestors.include?(SignedForm::FormBuilder)
          raise "Form signing not supported on builders that don't subclass ActionView::Helpers::FormBuilder or include SignedForm::FormBuilder"
        elsif !ancestors.include?(SignedForm::FormBuilder)
          options[:builder] = SignedForm::FormBuilder::BUILDERS[options[:builder]]
        end

        super record, options do |f|
          output = capture(f, &block)
          f.form_signature_tag + output
        end
      end
    end
  end
end

ActionView::Base.send :include, SignedForm::ActionView::FormHelper
