class AssetPublic < Asset
  file_attachment :resource,
                  :visibility => "public",
                  :styles     => self.correct_styles(Ubiquo::Config.context(:ubiquo_media).get(:media_styles_list)),
                  :processors => Ubiquo::Config.context(:ubiquo_media).get(:media_processors_list),
                  :storage    => Ubiquo::Config.context(:ubiquo_media).get(:media_storage)

  validates_attachment_presence :resource

  before_post_process :clean_tmp_files
  after_resource_post_process :generate_geometries
end
