require 'spec_helper'

class User
  extend ActiveModel::Naming

  attr_accessor :name, :widgets_attributes

  def to_key
    [1]
  end
end

class Widget
  extend ActiveModel::Naming

  attr_accessor :name

  def persisted?
    false
  end
end

describe SignedForm::FormBuilder do
  include SignedFormViewHelper

  before { SignedForm::HMAC.secret_key = "abc123" }
  after  { SignedForm::HMAC.secret_key = nil }

  let(:user) { User.new }
  let(:widget) { Widget.new }

  describe "signed_form_for" do
    it "should build a form with signature" do
      content = signed_form_for(User.new) do |f|
        f.text_field :name
      end

      regex = '<form.*>.*<input type="hidden" name="form_signature" ' \
              'value="\w+={0,2}--\w+".*/>.*' \
              '<input.*name="user\[name\]".*/>.*' \
              '</form>'

      content.should =~ Regexp.new(regex, Regexp::MULTILINE)
    end

    it "should set a target" do
      content = signed_form_for(User.new, sign_destination: true) do |f|
        f.text_field :name
      end

      data = get_data_from_form(content)
      data.size.should == 2
      data.should include(:__options__)
      data[:__options__].should include(:method, :url)
      data[:__options__][:method].should == :post
      data[:__options__][:url].should == '/users'
    end
  end

  describe "form inputs" do
    fields  = ActionView::Helpers::FormBuilder.instance_methods - Object.instance_methods
    fields -= [:button, :multipart=, :submit,
               :field_helpers, :label, :multipart,
               :emitted_hidden_id?, :to_model, :field_helpers?,
               :field_helpers=, :fields_for, :object_name=,
               :object=, :object_name, :model_name_from_record_or_class,
               :multipart?, :options, :options=,
               :convert_to_model, :to_partial_path, :index,
               :object, :radio_button, :parent_builder,
               :collection_check_boxes, :grouped_collection_select, :select,
               :collection_select, :collection_radio_buttons, :time_select,
               :datetime_select, :time_zone_select, :date_select]

    after do
      @data.should be
      @data.size.should == 1
      @data['user'].size.should == 1
      @data['user'].should include(:name)
    end

    fields.each do |field|
      it "should add to the allowed attributes when #{field} is used" do
        content = signed_form_for(User.new) do |f|
          f.send field, :name
        end

        @data = get_data_from_form(content)
      end
    end

    it "should add to the allowed attributes when collection_check_boxes is used", action_pack: /4\.\d+/ do
      content = signed_form_for(User.new) do |f|
        f.collection_check_boxes :name, ['a', 'b'], :to_s, :to_s
      end

      @data = get_data_from_form(content)
    end

    it "should add to the allowed attributes when grouped_collection_select is used" do
      continent   = Struct.new('Continent', :continent_name, :countries)
      country     = Struct.new('Country', :country_id, :country_name)

      content = signed_form_for(User.new) do |f|
        f.grouped_collection_select(:name, [continent.new("<Africa>", [country.new("<sa>", "<South Africa>")])],
                                    :countries, :continent_name, :country_id, :country_name)
      end

      @data = get_data_from_form(content)
    end

    it "should add to the allowed attributes when select is used" do
      content = signed_form_for(User.new) do |f|
        f.select :name, %w(a b)
      end

      @data = get_data_from_form(content)
    end

    it "should add to the allowed attributes when collection_select is used" do
      content = signed_form_for(User.new) do |f|
        f.collection_select :name, %w(a b), :to_s, :to_s
      end

      @data = get_data_from_form(content)
    end

    it "should add to the allowed attributes when collection_radio_buttons is used", action_pack: /4\.\d+/ do
      content = signed_form_for(User.new) do |f|
        f.collection_radio_buttons :name, %w(a b), :to_s, :to_s
      end

      @data = get_data_from_form(content)
    end

    it "should add to the allowed attributes when date_select is used" do
      content = signed_form_for(User.new) do |f|
        f.date_select :name
      end

      @data = get_data_from_form(content)
    end

    it "should add to the allowed attributes when time_select is used" do
      content = signed_form_for(User.new) do |f|
        f.time_select :name
      end

      @data = get_data_from_form(content)
    end

    it "should add to the allowed attributes when datetime_select is used" do
      content = signed_form_for(User.new) do |f|
        f.datetime_select :name
      end

      @data = get_data_from_form(content)
    end

    it "should add to the allowed attributes when time_zone_select is used" do
      content = signed_form_for(User.new) do |f|
        f.time_zone_select :name
      end

      @data = get_data_from_form(content)
    end

    it "should add to the allowed attributes when radio_button is used" do
      content = signed_form_for(User.new) do |f|
        f.radio_button :name, ['bar']
      end

      @data = get_data_from_form(content)
    end
  end

  describe "add_signed_fields" do
    it "should add fields to the marshaled data" do
      content = signed_form_for(User.new) do |f|
        f.add_signed_fields :name, :address
      end

      data = get_data_from_form(content)
      data['user'].should include(:name, :address)
      data['user'].size.should == 2
    end
  end

  describe "fields_for" do
    it "should nest attributes" do
      user.stub(widgets: [widget])

      content = signed_form_for(user) do |f|
        f.fields_for :widgets do |ff|
          ff.text_field :name
        end
      end

      data = get_data_from_form(content)
      data['user'].should include("widgets_attributes" => [:name])
    end

    it "should deeply nest attributes" do
      content = signed_form_for(:author, url: '/') do |f|
        f.fields_for :books do |ff|
          ff.text_field :name
          ff.check_box :hardcover
          ff.fields_for :pages do |fff|
            fff.text_field :number
          end
        end
      end

      data = get_data_from_form(content)

      data.should include(:author)
      data[:author].first.should include(:books)
      data[:author].first[:books].should include(:name, :hardcover, { pages: [:number] })
    end

    specify "nested arrays should not have duplicates" do
      content = signed_form_for(:author, url: '/') do |f|
        f.fields_for :books do |ff|
          ff.text_field :name
          ff.text_field :name
        end
      end

      data = get_data_from_form(content)
      data[:author].first[:books].size.should == 1
    end

    specify "attribute arrays should not have duplicates" do
      content = signed_form_for(:author, url: '/') do |f|
        f.text_field :name
        f.text_field :name
      end

      data = get_data_from_form(content)
      data[:author].size.should == 1
    end
  end
end
