module Ubiquo::RelationSelector
  autoload :Helper, "ubiquo/relation_selector/relation_selector"
end
ActionView::Base.send(:include, Ubiquo::RelationSelector::Helper)
