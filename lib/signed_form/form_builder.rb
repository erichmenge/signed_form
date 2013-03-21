module SignedForm
  class FormBuilder < ::ActionView::Helpers::FormBuilder
    attr_accessor :signed_attributes, :signed_attributes_object

    # Rails 3 uses strings, Rails 4 uses symbols
    (field_helpers.map(&:to_s) - %w(label fields_for)).each do |h|
      define_method(h) do |field, *args|
        signed_attributes_object << field
        super(field, *args)
      end
    end

    def initialize(*)
      super
      if options[:signed_attributes_object]
        self.signed_attributes_object = options[:signed_attributes_object]
      else
        self.signed_attributes = HashWithIndifferentAccess.new(object_name => [])
        self.signed_attributes_object = signed_attributes[object_name]
      end
    end

    def form_signature_tag
      encoded_data = Base64.strict_encode64 Marshal.dump(signed_attributes)
      signature = SignedForm::HMAC::create_hmac(encoded_data)
      token = "#{encoded_data}--#{signature}"
      %(<input type="hidden" name="form_signature" value="#{token}" />\n).html_safe
    end

    def fields_for(record_name, record_object = nil, fields_options = {}, &block)
      hash = HashWithIndifferentAccess.new
      if nested_attributes_association?(record_name)
        hash["#{record_name}_attributes"] = fields_options[:signed_attributes_object] = []
      else
        hash[record_name] = fields_options[:signed_attributes_object] = []
      end

      signed_attributes_object << hash
      super
    end
  end
end

