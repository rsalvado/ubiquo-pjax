class Category < ActiveRecord::Base
  
  belongs_to :category_set
  has_many :category_relations
  belongs_to :parent, :class_name => 'Category'
  has_many :children, :class_name => 'Category', :foreign_key => 'parent_id'
  
  validates_presence_of :name, :category_set
    
  def self.filtered_search(filters = {}, options = {})
    
    scopes = create_scopes(filters) do |filter, value|
      case filter
      when :text
        {:conditions => ["upper(categories.name) LIKE upper(?)", "%#{value}%"]}
      when :category_set
        {:conditions => {:category_set_id => value}}
      end
    end

    scopes += uhook_filtered_search(filters)
    
    apply_find_scopes(scopes) do
      find(:all, options)
    end
  end

  def to_s
    name
  end
  
  def self.alias_for_association association_name
    connection.table_alias_for "#{table_name}_#{association_name}"
  end

end
