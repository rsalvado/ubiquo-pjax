module UbiquoI18n::Extensions; end

ActiveRecord::Base.send(:include, UbiquoI18n::Extensions::ActiveRecord)
ActiveRecord::Associations::AssociationCollection.send(:include, UbiquoI18n::Extensions::AssociationCollection)
ActiveRecord::Associations::BelongsToAssociation.send(:include, UbiquoI18n::Extensions::BelongsToAssociation)
ActiveRecord::Associations::BelongsToPolymorphicAssociation.send(:include, UbiquoI18n::Extensions::BelongsToAssociation)
ActiveRecord::NamedScope::Scope.send(:include, UbiquoI18n::Extensions::NamedScope)
ActiveRecord::Associations::ClassMethods.send(:include, UbiquoI18n::Extensions::Associations)
Ubiquo::Extensions::Loader.append_include(:UbiquoController, UbiquoI18n::Extensions::LocaleChanger)
Ubiquo::Extensions::Loader.append_helper(:UbiquoController, UbiquoI18n::Extensions::Helpers)
if Rails.env.test?
  ActionController::TestCase.send(:include, UbiquoI18n::Extensions::TestCase)
  ActionController::TestCase.setup(:set_session_locale)
end
