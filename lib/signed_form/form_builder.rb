module SignedForm
  class FormBuilder < ::ActionView::Helpers::FormBuilder

    # Base methods for form signing. Include this module in your own builders to get signatures for the base input
    # helpers. Add fields to sign with #add_signed_fields
    module Methods
      (::ActionView::Helpers::FormBuilder.field_helpers.map(&:to_s) - %w(label fields_for button apply_form_for_options!)).each do |h|
        define_method(h) do |field, *args|
          add_signed_fields field
          super(field, *args)
        end
      end

      def initialize(*) #:nodoc:#
        super
        if options[:signed_attributes_object]
          self.signed_attributes_object = options[:signed_attributes_object]
        else
          self.signed_attributes = { object_name => [] }
          self.signed_attributes_object = signed_attributes[object_name]
        end
      end

      def form_signature_tag
        signed_attributes.each { |k,v| v.uniq! if v.is_a?(Array) }
        signed_attributes[:__options__] = { method: options[:html][:method], url: options[:url] } if options[:sign_destination]
        encoded_data = Base64.strict_encode64 Marshal.dump(signed_attributes)
        signature = SignedForm::HMAC.create_hmac(encoded_data)
        token = "#{encoded_data}--#{signature}"
        %(<input type="hidden" name="form_signature" value="#{token}" />\n).html_safe
      end

      def fields_for(record_name, record_object = nil, fields_options = {}, &block)
        hash  = {}
        array = []

        if nested_attributes_association?(record_name)
          hash["#{record_name}_attributes"] = fields_options[:signed_attributes_object] = array
        else
          hash[record_name] = fields_options[:signed_attributes_object] = array
        end

        add_signed_fields hash

        content = super
        array.uniq!
        content
      end

      def add_signed_fields(*fields)
        signed_attributes_object.push(*fields)
      end

      private

      attr_accessor :signed_attributes, :signed_attributes_object
    end

    include Methods
  end
end
