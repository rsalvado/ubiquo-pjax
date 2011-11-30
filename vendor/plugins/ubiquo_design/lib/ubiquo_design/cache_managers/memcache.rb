require 'memcache'

module UbiquoDesign
  module CacheManagers
    # Memcache implementation for the cache manager
    class Memcache < UbiquoDesign::CacheManagers::Base

      CONFIG = Ubiquo::Config.context(:ubiquo_design).get(:memcache)
      DATA_TIMEOUT = CONFIG[:timeout]

      # Exception class raised in situations where memcache is not available
      class MemcacheNotAvailable < StandardError; end

      class << self

        protected

        # retrieves the widget content identified by +content_id+
        def retrieve content_id
          begin
            connection.get crypted_key(content_id)
          rescue MemCache::MemCacheError, MemcacheNotAvailable
            raise CacheNotAvailable.new("Cache is not available, impossible to retrieve")
          end
        end

        # retrieves the widgets content by an array of +content_ids+
        def multi_retrieve content_ids, crypted = true
          unless crypted
            crypted_content_ids = []
            content_ids.each do |c_id|
              crypted_content_ids << crypted_key(c_id)
            end
          else
            crypted_content_ids = content_ids
          end
          begin
            connection.get_multi crypted_content_ids
          rescue MemCache::MemCacheError, MemcacheNotAvailable
            raise CacheNotAvailable.new("Cache is not available, impossible to multi_retrieve")
          end
        end

        # Stores a widget content indexing by a +content_id+
        def store content_id, contents, expiration_time
          begin
            exp_time = expiration_time || DATA_TIMEOUT
            connection.set crypted_key(content_id), contents, exp_time
          rescue MemCache::MemCacheError, MemcacheNotAvailable
            raise CacheNotAvailable.new("Cache is not available, memcached can not store the content")
          end
        end

        # removes the widget content from the store
        def delete content_id
          Rails.logger.debug "Widget cache expiration request for key #{content_id}"
          begin
            connection.delete crypted_key(content_id)
          rescue MemCache::MemCacheError, MemcacheNotAvailable
            raise CacheNotAvailable.new("Cache is not available, impossible to delete cache")
          end
        end

        # Returns or initializes a memcache connection
        def connection
          if @cache.blank?
            begin
              @cache = MemCache.new(CONFIG[:server])
            rescue
              Rails.logger.warn "Memcache Error: memcached servers are not available"
              raise MemcacheNotAvailable, "Memcache Error: memcached servers are not available"
            end
            if @cache.servers.empty?
              Rails.logger.warn "Memcache Error: memcached servers are not available"
              raise MemcacheNotAvailable, "Memcache Error: memcached servers are not available" if @cache.servers.empty?
            end
            @cache.servers.each do |s|
              if s.socket.blank?
                Rails.logger.error "Memcache Error: memcached socket has no connection on #{s.instance_variable_get(:@host)}"
                raise MemcacheNotAvailable, "Memcache Error: memcached socket has no connection on #{s.instance_variable_get(:@host)}"
              end
            end
          end
          @cache
        end
      end

    end
  end
end
