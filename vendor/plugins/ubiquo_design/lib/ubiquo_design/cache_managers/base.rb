module UbiquoDesign

  # Return the manager class to use. You can override the default by setting
  # the :cache_manager_class in ubiquo config:
  #   Ubiquo::Config.context(:ubiquo_design).set(
  #     :cache_manager_class,
  #     UbiquoDesign::CacheManagers::Memcache
  #   )
  def self.cache_manager
    Ubiquo::Config.context(:ubiquo_design).call(:cache_manager_class, self)
  end

  module CacheManagers
    # cache errors
    class CacheNotAvailable < StandardError; end

    # Base class for widget cache
    class Base

      require "digest/sha2"

      class << self

        # Gets the cached content of a widget. Returns false if this widget is not
        # currently cached
        def get(widget_id, options = {})
          if (key = calculate_key(widget_id, options))
            valid = not_expired(widget_id, key, options)
            if valid
              cached_content = retrieve(key)
              if cached_content
                Rails.logger.debug "Widget cache hit for widget: #{widget_id.to_s} with key #{key}"
              else
                Rails.logger.debug "Widget cache miss for widget: #{widget_id.to_s} with key #{key}"
              end
              cached_content
            end
          end
        end
        
        # Gets all of the cached widgets content of a web. Return a hash where
        # the key is the id of the widget and the value is the content
        def multi_get(page, options = {})
          widgets_with_key = {}
          all_widgets = []
          page.blocks.each do |block|
            block.real_block.widgets.each do |widget|
              key = calculate_key(widget, options)
              all_widgets << [widget, key] if key
            end
          end

          valid_widgets = validate_parents(all_widgets, options)
          valid_widgets.each do |elems|
            widgets_with_key[elems[0].id] = elems[1]
          end
          
          crypted_table = crypt_all_keys(widgets_with_key.values)
          
          cached_widgets = begin
            multi_retrieve crypted_table.keys
          rescue CacheNotAvailable
            return {}
          end

          widgets = {} 
          cached_widgets.each do |cached_widget|
            if cached_widget.last
              key = widgets_with_key.index(crypted_table[cached_widget.first])
              Rails.logger.debug "Widget cache hit for widget with id: #{key} with key #{crypted_table[cached_widget.first]}"
              widgets[key] = cached_widget.last
            end
          end
          widgets
        end

        # Caches the content of a widget, with a possible expiration date.
        def cache(widget_id, contents, options = {})
          key = calculate_key(widget_id, options)
          validate(widget_id, key, options)
          if key
            Rails.logger.debug "Widget cache store request sent for widget: #{widget_id.to_s} with key #{key}"
            #check if expires_in is present and set it to store call
            store(key, contents, get_expiration_time(widget_id, options))
          else
            Rails.logger.debug "Widget cache missing policies for widget: #{widget_id.to_s}"
          end
        end

        # Expires the applicable content of a widget given its id
        def expire(widget_id, options = {})
          Rails.logger.debug "-- cache EXPIRATION --"
          begin
            model_key = calculate_key(widget_id, options.slice(:scope))
            delete(model_key) if model_key

            with_instance_content(widget_id, options) do |instance_key|
              keys = retrieve(instance_key)[:keys] rescue []
              keys.each{|key| delete(key)}
              delete(instance_key)
            end
          rescue CacheNotAvailable
          end
        end

        protected

        # Calculates a string content identifier depending on the widget
        # +widget+ can be either a Widget instance or a widget id
        # possible options:
        #   policy_context:  cache Policies definition context (default nil)
        #   scope:    object where the params and lambdas will be evaluated
        # Returns nil if the widget should not be cached according to the policies
        def calculate_key(widget, options = {})
          widget, policies = policies_for_widget(widget, options)
          return unless policies
          key = "#{widget.id.to_s}_#{widget.version || 0}"
          options[:widget] = widget
          policies[:models].each do |_key, val|
            if options[:scope].respond_to?(:params) || _key == options[:scope].class.name
              key += process_params(policies[:models][_key], options)
              key += process_procs(policies[:models][_key], options)
            end
          end
          if options[:scope].respond_to?(:params)
            key += process_params(policies, options)
            key += process_procs(policies, options)
          end
          key
        end

        def process_params policies, options
          params_key = ''
          if policies[:params].present? || policies[:widget_params].present? 
            param_ids = policies[:params].map do |param_id_raw|
              param_id, t_param_id = case param_id_raw
              when Symbol
                [param_id_raw, param_id_raw]
              when Hash
                if options[:scope].respond_to?(:params)
                  [param_id_raw.keys.first(),
                   param_id_raw.keys.first()]
                else
                  [param_id_raw.keys.first(),
                   param_id_raw.values.first()]
                end
              end
              if options[:scope].respond_to?(:params)
                "###{param_id}###{options[:scope].send(:params)[t_param_id]}"
              else
                "###{param_id}###{options[:scope].send(t_param_id)}"
              end
            end
            if policies[:widget_params].present?
              param_ids << "c_params_" + options[:scope].params.map{|key, val| "#{key}@#{val}" }.sort.join("&")
            end
            params_key = '_params_' + param_ids.join
          end
          params_key
        end

        def process_procs policies, options
          procs_key = ''
          if policies[:procs].present?
            proc_ids = policies[:procs].map do |proc_raw|
              proc = case proc_raw
              when Proc
                next unless options[:scope].respond_to?(:params)
                proc_raw
              when Array
                if options[:scope].respond_to?(:params)
                  proc_raw.first
                else
                  proc_raw.last
                end
              end
              if proc.is_a?(Proc)
                "###{proc.bind(options[:scope]).call(options[:widget])}"
              elsif proc.is_a?(Symbol)
                if options[:scope].respond_to?(:params)
                  "###{options[:scope].send(:params)[proc]}"
                else
                  "###{options[:scope].send(proc)}"
                end
              end
            end
            procs_key = '_procs_' + proc_ids.join if proc_ids.compact.present?
          end
          procs_key
        end

        # retrieves the widget content identified by +key+
        def retrieve(key)
          raise NotImplementedError.new 'Implement retrieve(key) in your CacheManager'
        end

        # Stores a widget content indexing by a +key+
        def store(key, contents)
          raise NotImplementedError.new 'Implement store(key, contents) in your CacheManager'
        end

        # removes the widget content from the store
        def delete(key)
          raise NotImplementedError.new 'Implement delete(key) in your CacheManager'
        end

        # Returns true if the key fragment is not expired and still vigent
        def not_expired(widget, key, options)
          with_instance_content(widget, options) do |instance_key|
            valid_keys = retrieve(instance_key)
            begin
              if valid_keys.blank? || !valid_keys[:keys].include?(key)
                return false
              end
            rescue
              return false
            end
          end
          true
        end

        # Marks the key as valid if necessary
        def validate(widget, key, options)
          with_instance_content(widget, options) do |instance_key|
            valid_keys = begin
              retrieve(instance_key)
            rescue CacheNotAvailable
              return {}
            end
            valid_keys ||= {}
            (valid_keys[:keys] ||= []) << key
            valid_keys[:keys].uniq
            store(instance_key, valid_keys, get_expiration_time(widget, options))
          end

        end

        def validate_parents(all_widgets, options)
          valid_widgets = []
          parents = get_parents(all_widgets.map{|lk| lk[0]}, options)

          crypted_table = crypt_all_parents_keys(parents) 
          begin 
            cached_parents = multi_retrieve crypted_table.keys
            crypted_keys = crypted_table.keys
            all_widgets.each_with_index do |widget, index|
              current_keys = parents[widget[0].id]
              valid_widgets << widget if own_parents_valid(cached_parents, current_keys, widget[1])
            end
          rescue CacheNotAvailable
            valid_widget = []
          end
          
          valid_widgets
        end

        def own_parents_valid parents, current_keys, own_key
          current_keys.each do |ck|
            val = parents[ck]
            return false if val.blank? || !val[:keys].include?(own_key)
          end
          return true
        end
        
        def get_parents all_widgets, options
          parents = {} #each parent
          all_widgets.each do |widget|
            options[:widget] = widget
            parents[widget.id] = []
            with_instance_content(widget, options) do |ikey|
              parents[widget.id] << ikey
            end
          end
          return parents
        end

        # Wrapper for getting, if applicable, the instance content id,
        # given a Widget instance
        def with_instance_content(widget, options)
          widget, policies = policies_for_widget(widget, options)
          return unless policies

          widget_pre_key = "__" + (widget.is_a?(Widget) ? widget.id.to_s : widget.to_s )
          if policies[:models].present?
            policies[:models].each do |key, val|
              if options[:current_model].present? && options[:current_model].to_s != key.to_s
                next
              end
              if val[:identifier].is_a?(Hash)
                if options[:scope].respond_to?(:params)
                  true_identifier = val[:identifier].keys.first
                else
                  true_identifier = val[:identifier].values.first
                end
              elsif val[:identifier].is_a?(Array)
                if options[:scope].respond_to?(:params)
                  true_identifier = val[:identifier].first
                else
                  true_identifier = val[:identifier].last
                end
              else
                true_identifier = val[:identifier]
              end

              p_i = key.to_s + '_' 
              p_i += process_params(val, options)
              p_i += process_procs(val, options)
              yield(widget_pre_key + p_i)
            end
          else
            yield(widget_pre_key)
          end
          return

        end

        # Returns a widget and its policies ([widget, policies])
        # for a given widget or widget_id

        def policies_for_widget widget, options
          widget = widget.is_a?(Widget) ? widget : Widget.find(widget)
          policies = UbiquoDesign::CachePolicies.get(options[:policy_context])[widget.key]
          [widget, policies]
        end

        def get_expiration_time widget, options
          widget = widget.is_a?(Widget) ? widget : Widget.find(widget)
          policies = UbiquoDesign::CachePolicies.get(options[:policy_context])[widget.key]
          policies[:expires_in]
        end

        def crypted_key key
          obj = Digest::SHA256.new << key
          obj.to_s
        end

        def crypt_all_keys(values)
          ret_set = {}
          values.each do |val|
            ret_set[crypted_key(val)] = val
          end
          ret_set
        end

        def crypt_all_parents_keys(widget_hash)
          ret_set = {}
          widget_hash.each do |key, val|
            vals = []
            val.each do |non_crypted|
              c_key =  crypted_key(non_crypted)
              vals << c_key
              ret_set[c_key] = non_crypted 
            end
            widget_hash[key] = vals
          end
          ret_set
        end
      end
    end
  end
end
