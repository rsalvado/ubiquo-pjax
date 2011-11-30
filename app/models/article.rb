class Article < ActiveRecord::Base

  validates_presence_of :title

  filtered_search_scopes

end
