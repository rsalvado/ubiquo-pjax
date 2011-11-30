class CategoryRelation < ActiveRecord::Base
  
  belongs_to :category
  belongs_to :related_object, :polymorphic => true

  before_create :create_position
  validates_presence_of :category, :related_object, :attr_name
    
  # See vendor/plugins/ubiquo_core/lib/ubiquo/extensions/active_record.rb to see an example of usage.
  def self.filtered_search(filters = {}, options = {})
    
    scopes = create_scopes(filters) do |filter, value|
      case filter
      when :text
        {}
      end
    end
    
    apply_find_scopes(scopes) do
      find(:all, options)
    end
  end

  def self.last_position attr_name
    self.maximum("#{table_name}.position", :conditions => {:attr_name => attr_name.to_s})
  end

  def self.alias_for_association association_name
    connection.table_alias_for "#{table_name}_#{association_name}"
  end

  protected

  def create_position
    if !read_attribute(:position)
      last_position = CategoryRelation.last_position read_attribute(:attr_name)
      last_position ||= 0
      write_attribute :position, last_position+1
    end
  end

end
