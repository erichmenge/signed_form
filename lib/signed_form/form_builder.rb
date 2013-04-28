module SignedForm
  class FormBuilder < ::ActionView::Helpers::FormBuilder

    # Base methods for form signing. Include this module in your own builders to get signatures for the base input
    # helpers. Add fields to sign with #add_signed_fields
    module Methods
      FIELDS_TO_SIGN = [:select, :collection_select, :grouped_collection_select,
                        :time_zone_select, :collection_radio_buttons, :collection_check_boxes,
                        :date_select, :datetime_select, :time_select,
                        :text_field, :password_field, :hidden_field,
                        :file_field, :text_area, :check_box,
                        :radio_button, :color_field, :search_field,
                        :telephone_field, :phone_field, :date_field,
                        :time_field, :datetime_field, :datetime_local_field,
                        :month_field, :week_field, :url_field,
                        :email_field, :number_field, :range_field]

      FIELDS_TO_SIGN.delete_if { |e| !::ActionView::Helpers::FormBuilder.instance_methods.include?(e) }
      FIELDS_TO_SIGN.freeze

      FIELDS_TO_SIGN.each do |h|
        define_method(h) do |field, *args|
          add_signed_fields field
          super(field, *args)
        end
      end

      def initialize(*)
        super
        if options[:signed_attributes_context]
          @signed_attributes_context = options[:signed_attributes_context]
        else
          @signed_attributes = { object_name => [] }
          @signed_attributes_context = @signed_attributes[object_name]
          prepare_signed_attributes_hash
        end
      end

      def form_signature_tag
        @signed_attributes.each { |k,v| v.uniq! if v.is_a?(Array) }
        encoded_data = Base64.strict_encode64 Marshal.dump(@signed_attributes)

        hmac = SignedForm::HMAC.new(secret_key: SignedForm.secret_key)
        signature = hmac.create(encoded_data)
        token = "#{encoded_data}--#{signature}"
        %(<input type="hidden" name="form_signature" value="#{token}" />\n).html_safe
      end

      # Wrapper for Rails fields_for
      #
      # @see http://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-fields_for
      def fields_for(record_name, record_object = nil, fields_options = {}, &block)
        hash  = {}
        array = []

        if nested_attributes_association?(record_name)
          hash["#{record_name}_attributes"] = fields_options[:signed_attributes_context] = array
        else
          hash[record_name] = fields_options[:signed_attributes_context] = array
        end

        add_signed_fields hash

        content = super
        array.uniq!
        content
      end

      # This method is used to add additional fields to sign. A usecase for this may be if you want to add fields later with javascript.
      #
      # @example
      #   <%= signed_form_for(@user) do |f| %>
      #     <% f.add_signed_fields :name, :address
      #   <% end %>
      #
      def add_signed_fields(*fields)
        @signed_attributes_context.push(*fields)
        options[:digest] << @template if options[:digest]
      end

      private

      def prepare_signed_attributes_hash
        @signed_attributes[:_options_] = {}

        if options[:sign_destination]
          @signed_attributes[:_options_][:method] = options[:html][:method]
          @signed_attributes[:_options_][:url]    = options[:url]
        end

        if options[:digest]
          @signed_attributes[:_options_][:digest] = options[:digest] = Digestor.new(@template)
          @signed_attributes[:_options_][:digest_expiration] = Time.now + options[:digest_grace_period] if options[:digest_grace_period]
        end
      end
    end

    include Methods
  end
end
