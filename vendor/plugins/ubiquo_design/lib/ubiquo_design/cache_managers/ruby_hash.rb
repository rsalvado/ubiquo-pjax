module UbiquoDesign
  module CacheManagers
    # Cache Manager implementation using a simple ruby hash
    # Useful as a lightweight manager, it's used in manager tests
    class RubyHash < UbiquoDesign::CacheManagers::Base

      class << self

        protected

        # retrieves the widget content identified by +content_id+
        def retrieve content_id
          base[content_id]
        end

        # retrieves the widgets content by an array of +content_ids+
        def multi_retrieve content_ids
          base.slice(*content_ids)
        end

        # Stores a widget content indexing by a +content_id+
        # +expiration_time+ is not currently supported
        def store content_id, contents, expiration_time = nil
          base.merge!(content_id => contents)
        end

        # removes the widget content from the store
        def delete content_id
          base.delete(content_id)
        end

        # Returns or initializes the hash that serves as store
        def base
          @base ||= {}
        end
      end

    end
  end
end
