# -*- coding: utf-8 -*-
class Widget < ActiveRecord::Base

  INACCEPTABLE_OPTIONS = %w{options widget widget_id block block_id position}

  @@behaviours = {}

  @inheritable_attributes = inheritable_attributes.merge(:previewable => true)

  cattr_accessor :behaviours

  attr_accessor :update_page_denied

  validates_presence_of :name, :block

  belongs_to :block

  serialize :options, Hash
  attr_protected :options

  before_create :set_version
  
  before_save :update_position
  after_save :update_page
  after_destroy :update_page

  def without_page_expiration
    self.update_page_denied = true
    yield
    self.update_page_denied = false
  end

  def self.behaviour(name, options={}, &block)
    @@behaviours[name] = {:options => options, :proc => block}
  end

  def update_position
    self.position = (block.widgets.map(&:position).max || 0)+1 if self.position.nil?
  end

  # +options+ should be an empty hash by default (waiting for rails #1736)
  def options
    read_attribute(:options) || write_attribute(:options, {})
  end

  def self.allowed_options=(opts)
    opts = [opts].flatten
    unallowed_options = opts.map(&:to_s)&INACCEPTABLE_OPTIONS
    raise "Inacceptable options: '%s'" % unallowed_options.join(', ') unless unallowed_options.blank?
    self.cattr_accessor :allowed_options_storage
    self.allowed_options_storage = opts
    opts.each do |option|
      define_method(option) do
        self.options[option]
      end
      define_method("#{option}=") do |value|
        self.options[option] = value
      end
    end
  end

  def self.allowed_options
    self.allowed_options_storage ||= []
  end

  # Returns the default name for the given +widget+ type
  def self.default_name_for widget
    I18n.t("ubiquo.widgets.#{widget.to_s.downcase}.name")
  end

  # Returns the default description for the given +widget+ type
  def self.default_description_for widget
    I18n.t("ubiquo.widgets.#{widget.to_s.downcase}.description")
  end

  # Returns true if the widget has editable options
  def is_configurable?
    self.class.is_configurable?
  end

  # Returns true if the widget type has editable options
  def self.is_configurable?
    allowed_options.present?
  end

  # Returns the key representing the widget type
  def key
    self.class.to_s.underscore.to_sym
  end

  # Returns a Widget class given a key (inverse of Widget#key)
  def self.class_by_key key
    key.to_s.classify.constantize
  end

  # Returns a hash containing the defined widget_groups in design structure, and
  # for each group, the identifiers of the widgets that compose it
  def self.groups
    {}.tap do |groups|
      UbiquoDesign::Structure.widget_groups.each do |widget_group|
        groups[widget_group.keys.first] = widget_group.values.first.select do |h|
          h.keys.include?(:widgets)
        end.first[:widgets].map(&:keys).flatten
      end
    end
  end

  # Returns the page this widget is in
  def page
    # Not using delegate due to 'block' clash name...
    block.page
  end

  def is_previewable?
    self.class.is_previewable?
  end

  def self.is_previewable?
    read_inheritable_attribute :previewable
  end

  def self.previewable(value)
    write_inheritable_attribute :previewable, (value == true)
  end

  private

  # When a block is saved, the associated page must change its modified attribute
  def update_page
    if self.update_page_denied.blank?
      widget_page = self.block.reload.page.reload
      widget_page.update_modified(true) unless widget_page.is_modified?
    end
  end

  # Sets initial version number
  def set_version
    self.version = 0
  end
end
