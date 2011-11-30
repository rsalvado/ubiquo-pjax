class ActivityInfo < ActiveRecord::Base
  validates_presence_of :controller, :action, :status, :ubiquo_user_id
  belongs_to :related_object, :polymorphic => true
  belongs_to :ubiquo_user
  
  def self.filtered_search(filters = {}, options = {})
    
    scopes = create_scopes(filters) do |filter, value|
      case filter
      when :controller
        { :conditions => ["activity_infos.controller = ?", value] }
      when :action
        { :conditions => ["activity_infos.action = ?", value] }
      when :status
        { :conditions => ["activity_infos.status = ?", value] }
      when :date_start
        { :conditions => ["activity_infos.created_at >= ?", value]}
      when :date_end
        { :conditions => ["activity_infos.created_at <= ?", value]}        
      when :user
        { :conditions => ["activity_infos.ubiquo_user_id = ?", value]}
      end
    end
    
    apply_find_scopes(scopes) do
      find(:all, options)
    end
  end  
  
end
