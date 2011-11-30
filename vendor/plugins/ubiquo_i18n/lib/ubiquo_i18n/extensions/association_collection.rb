module UbiquoI18n
  module Extensions
    module AssociationCollection
   
      def self.included(klass)
        klass.alias_method_chain :count, :translation_shared
        klass.alias_method_chain :construct_find_options!, :translation_shared
      end

      def construct_find_options_with_translation_shared!(options)
        if proxy_reflection.options[:translation_shared] && loaded?
          conditions = options[:conditions].split(' AND ')
          conditions.shift # replace finder_sql
          options[:conditions] = merge_conditions({:id => proxy_target.map(&:id)}, *conditions)
        end
        construct_find_options_without_translation_shared!(options)
      end

      def count_with_translation_shared(*args)
        if proxy_reflection.options[:translation_shared]
          if args.blank?
            loaded? ? size : count_without_translation_shared
          else
            raise NotImplementedError
          end
        else
          count_without_translation_shared *args
        end
      end
    end
  end
end
