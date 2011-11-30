module UbiquoI18n
  module Extensions

    # This module fixes the #updated? method from belongs_to associations. Rails
    # does not reset this flag to false when a model is saved, thus leading in
    # unnecessary repeated behaviour, which in turn causes that Rails sometimes
    # changes the XXX_id field in AutosaveAssociation when it shouldn't (because
    # this field has been changed, and not the association, which might be cached
    # or proxied)
    module BelongsToAssociation

      def self.append_features(base)
        base.send :include, InstanceMethods
        base.alias_method_chain :updated?, :shared_translations
      end

      module InstanceMethods
        def updated_with_shared_translations?
          if updated_without_shared_translations?
            # If the XXX_id field is updated, respect it even if the association
            # also says that she has been updated, since this last condition
            # sometimes is not true.
            # For caution, only applies this "fixed" behaviour on
            # translation_shared associations
            !(proxy_reflection.options[:translation_shared] &&
              proxy_owner.has_updated_existing_primary_key(proxy_reflection))
          end
        end
      end
    end
  end
end