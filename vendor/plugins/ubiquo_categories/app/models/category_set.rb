class CategorySet < ActiveRecord::Base

  has_many :categories, {:order => "name ASC"} do

    # This method accepts an options parameter if you use it like this:
    #
    #   set << [category_1, category_2, {:option => value}]
    #
    # Can be used as usual too
    #
    #   set << category_1
    #
    # In any case, category can be a Category instance or a simple string
    def << categories
      if categories.is_a? Array
        options = categories.extract_options!
      else
        categories = [categories]
        options = {}
      end
      categories.flatten.reject(&:blank?).each do |category|
        # skip if already added
        load_target
        next if proxy_target.map(&:to_s).include? category.to_s

        case category
        when String
          raise UbiquoCategories::CreationNotAllowed unless proxy_owner.is_editable?
          self.concat(Category.uhook_new_from_name(category, options))
        when Hash
          parent = category.keys.first
          self << parent
          parent_id = self.select{|cat| cat.to_s == parent.to_s}.first.id
          self << [category[parent], {:parent_id => parent_id}]
        else
          self.concat(category)
        end
      end
    end
  end

  validates_presence_of :name, :key
  validates_uniqueness_of :key, :case_sensitive => false

  def initialize(attrs = {})
    attrs ||= {}
    attrs.reverse_merge!(:is_editable => true)
    super attrs
  end

  def self.filtered_search(filters = {}, options = {})
    
    scopes = create_scopes(filters) do |filter, value|
      case filter
      when :text
        {:conditions => ["upper(category_sets.name) LIKE upper(?)", "%#{value}%"]}
      end
    end
    
    apply_find_scopes(scopes) do
      find(:all, options)
    end
  end

  # Sets the set as editable
  def is_editable!
    update_attribute :is_editable, true
  end

  # Sets the set as not editable
  def is_not_editable!
    update_attribute :is_editable, false
  end

  # Returns the fittest category given the required params.
  # category can be either a Category or a string (category name)
  def select_fittest(category, options = {})
    category = case category
    when Category
      category
    when String
      categories.first(:conditions => ['upper(categories.name) = upper(?)', category])
    end
    uhook_select_fittest category, options unless category.nil?
  end

end
