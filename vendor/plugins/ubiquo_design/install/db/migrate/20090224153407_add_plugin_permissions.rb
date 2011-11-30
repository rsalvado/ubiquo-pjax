class AddPluginPermissions < ActiveRecord::Migration
  def self.up
    Permission.create :key => "design_management", :name => "Design management"
    Permission.create :key => "sitemap_management", :name => "Sitemap management"
  end

  def self.down
    Permission.destroy_all(:key => %w[design_management sitemap_management])
  end
end
