module SignedForm
  module ActionView
    module FormHelper
      def form_for(record, options = {}, &block)
        # Starting with Rails 7, form_for delegates to form_with.
        return super if ::ActionView::VERSION::MAJOR >= 7 || !signed_form_enabled?(options)

        super(record, signed_builder_options(options)) do |form|
          signed_form_body(form, &block)
        end
      end

      if ::ActionView::Helpers::FormHelper.method_defined?(:form_with)
        def form_with(**options, &block)
          return super unless signed_form_enabled?(options)

          options = signed_builder_options(options)
          if options[:sign_destination]
            options[:signed_form_url] = signed_form_url(options)
          end

          super(**options) do |form|
            signed_form_body(form, &block)
          end
        end
      end

      private

      def signed_form_enabled?(options)
        options[:signed].nil? ? SignedForm.options[:signed] : options[:signed]
      end

      def signed_builder_options(options)
        merged = SignedForm.options.merge(options)
        builder = merged[:builder] || ::ActionView::Helpers::FormBuilder
        merged[:builder] = SignedForm::FormBuilder.signed_builder(builder)
        merged
      end

      def signed_form_url(options)
        url = options[:url]
        html = options[:html] || {}
        # With no action attribute the browser submits to the current document.
        return request.fullpath if url == false || html[:action] == false || html['action'] == false

        if url.nil? && options[:model]
          url = polymorphic_path(options[:model], options.slice(:format).compact)
        end
        url_for(url || {})
      end

      def signed_form_body(form, &block)
        body = capture(form, &block)
        form.form_signature_tag + body
      end
    end
  end
end

ActionView::Base.send :include, SignedForm::ActionView::FormHelper
