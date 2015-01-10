module SignedForm
  module FormBuilder
    FIELDS_TO_SIGN = [:select, :collection_select, :grouped_collection_select,
                      :time_zone_select, :collection_radio_buttons, :collection_check_boxes,
                      :date_select, :datetime_select, :time_select,
                      :text_field, :password_field, :hidden_field,
                      :file_field, :text_area, :check_box,
                      :radio_button, :color_field,
                      :telephone_field, :phone_field, :date_field,
                      :time_field, :datetime_field, :datetime_local_field,
                      :month_field, :week_field, :url_field,
                      :email_field, :number_field, :range_field]

    FIELDS_TO_SIGN.delete_if { |e| !::ActionView::Helpers::FormBuilder.instance_methods.include?(e) }
    FIELDS_TO_SIGN.freeze

    FIELDS_TO_SIGN.each do |kind|
      define_method(kind) do |field, *args|
        options = args.last.is_a?(Hash) ? args.last : {}
        add_signed_fields(field) unless options[:disabled]
        super(field, *args)
      end
    end

    BUILDERS = Hash.new do |h,k|
      h[k] = Class.new(k) do
        include FormBuilder
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
      recursive_merge_identical_hashes! @signed_attributes
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

    def recursive_merge_identical_hashes! hash
      hash.each do |k,v|
        hashes = []
        hash[k] = v.reject do |attr|
          attr.is_a?(Hash) && hashes << attr
        end
        unless hashes.empty?
          sub_attrs = Hash.new {|hash,key| hash[key] = []}
          hashes.each do |h|
            h.each do |subk,subv|
              sub_attrs[subk] += subv
            end
          end
          recursive_merge_identical_hashes! sub_attrs
          sub_attrs.default = nil
          hash[k] << sub_attrs
        end
      end
    end
  end
end
