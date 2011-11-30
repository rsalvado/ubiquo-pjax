# The PublicController is a recommended wrapper for all the controllers of
# your public site. You can add here any filters or methods that you want for
# the public part, but that won't be present inside ubiquo

class PublicController < ApplicationController
  layout "main"
  include UbiquoDesign::RenderPage
  include Ubiquo::Extensions::PublicController rescue nil
end
