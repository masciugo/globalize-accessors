require 'globalize'

module Globalize::Accessors
  def globalize_accessors(options = {})
    options.reverse_merge!(:locales => I18n.available_locales, :attributes => translated_attribute_names)
    class_attribute :globalize_locales, :globalize_attribute_names, :globalize_attribute_names_components, :instance_writer => false

    self.globalize_locales = options[:locales]
    self.globalize_attribute_names = []
    self.globalize_attribute_names_components = {}

    each_attribute_and_locale(options) do |attr_name, locale|
      define_accessors(attr_name, locale)
    end

    include InstanceMethods
  end

  def localized_attr_name_for(attr_name, locale)
    "#{attr_name}_#{locale.to_s.underscore}"
  end

  def human_attribute_name(attr_name)
    if has_globalized_attributes? and is_attr_name_localized?(attr_name)
      components = globalize_attribute_names_components[attr_name.to_sym]
      super(components.first) + " [#{components.last}]"
    else
      super(attr_name)
    end
  end

  private

  def has_globalized_attributes?
    respond_to?(:globalize_attribute_names)
  end

  def is_attr_name_localized?(attr_name)
    self.globalize_attribute_names.include?(attr_name.to_sym)
  end

  def define_accessors(attr_name, locale)
    define_getter(attr_name, locale)
    define_setter(attr_name, locale)
  end

  def define_getter(attr_name, locale)
    define_method localized_attr_name_for(attr_name, locale) do
      globalize.stash.contains?(locale, attr_name) ? globalize.send(:fetch_stash, locale, attr_name) : globalize.send(:fetch_attribute, locale, attr_name)
    end
  end

  def define_setter(attr_name, locale)
    localized_attr_name = localized_attr_name_for(attr_name, locale)

    define_method :"#{localized_attr_name}=" do |value|
      write_attribute(attr_name, value, :locale => locale)
      translation_for(locale)[attr_name] = value
    end
    if respond_to?(:accessible_attributes) && accessible_attributes.include?(attr_name)
      attr_accessible :"#{localized_attr_name}"
    end
    self.globalize_attribute_names << localized_attr_name.to_sym
    self.globalize_attribute_names_components[localized_attr_name.to_sym] = [attr_name,locale]
  end

  def each_attribute_and_locale(options)
    options[:attributes].each do |attr_name|
      options[:locales].each do |locale|
        yield attr_name, locale
      end
    end
  end

  module InstanceMethods
    def localized_attr_name_for(attr_name, locale)
      self.class.localized_attr_name_for(attr_name, locale)
    end
  end
end

ActiveRecord::Base.extend Globalize::Accessors
