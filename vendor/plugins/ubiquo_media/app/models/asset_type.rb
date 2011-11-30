class AssetType < ActiveRecord::Base
  has_many :assets
  
  # Generic find (ID, key or record)
  def self.gfind(something, options={})
    case something
    when Fixnum
      find_by_id(something, options)
    when String, Symbol
      find_by_key(something.to_s, options)
    when AssetType
      something
    else
      nil
    end
  end

end
