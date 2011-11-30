# -*- coding: utf-8 -*-
module Ubiquo

  class InvalidFilter < StandardError; end

  module FilteredSearch
    def self.included(base)
      # TODO: Remove DateParser dependency, see I18n.parse_date
      # (possible problem with calendar_date_select plugin)
      base.send :extend, Ubiquo::Extensions::DateParser
      base.send :extend, ClassMethods
    end

    module ClassMethods

      # This macro adds two class methods to facilitate search and
      # filtering within a model:
      # Example:
      #  >> Book.paginated_filtered_search(params)
      #  >> Book.filtered_search(params)
      #
      # filter_* like params are matched against the avaliable
      # named_scopes (removing the filter_ part) and applied.
      #
      # You can also enable and disable scopes and activate o
      # deactivate default scopes (which are created automatically).
      # Example:
      #  >> filtered_search_scopes # By default all scopes are enabled
      #  >> filtered_search_scopes :defaults => false # Disable auto-generated scopes
      #  >> filtered_search_scopes :enable => [ :text, :published_start ,:publish_end ], :defaults => false
      #
      # It is also  possible to define which fields should be affected by a
      # text search (filter_text param matched against a dinamically
      # generated text named_scope):
      #  >> filtered_search_scopes :text => [ :title, :description ]
      def filtered_search_scopes(options = {})
        options.reverse_merge!({:defaults => true})
        @enabled_scopes = options[:enable] || []
        text_scope(options[:text]) if (options[:defaults] || options[:text])
        if options[:defaults]
          published_at_scopes
          @enabled_scopes << :locale
        end
      end

      # Returns a paginated and filtered result set. You can use
      # params[:page] to specify which page to retrieve.
      #
      # It also takes into account order_by and sort_order params.
      # Check #filtered_search for more details
      def paginated_filtered_search(params = {}, options = {})
        order_by =  params[:order_by] || options[:order_by] || "#{table_name}.id"
        sort_order = params[:sort_order] || options[:sort_order] || 'desc'

        order_by_segments = order_by.split('.')

        # To deal with relation columns. Ex: :'author.name'
        # We need to deal with a special case with categories
        if order_by_segments.size > 2
          table, assoc, column = order_by_segments
          assoc_table = (self.reflections[assoc.to_sym] ||
                         self.reflections[assoc.pluralize.to_sym]).table_name
          options[:include] = assoc_table == 'categories' ? assoc.pluralize : assoc
          order_by = "#{assoc_table}.#{column}"
        end

        options[:order] = "#{order_by} #{sort_order}"

        ubiquo_paginate(:page => params[:page], :per_page => params[:per_page]) do
          filtered_search params, options.except(:order_by, :sort_order)
        end
      end

      # Returns a filtered, by named scopes, result set using filter params.
      #
      # The result is automatically filtered using params[:filter_*]
      # type params where * would be the name of the named_scoped to
      # apply. Multiple named_scopes can be applied simultaniously.
      #
      # You can also restrict the search to specific scopes.
      # Examples:
      #  >> Book.paginated_filtered_search(params)
      #  >> Book.paginated_filtered_search(params, :scopes => [ :text ])
      def filtered_search(params = {}, options = {})
        scopes = select_scopes(params, options[:scopes])
        scopes.inject(self) do |results, pair|
          pair.last.blank? ? results : results.send(pair.first, pair.last)
        end.all(options.except(:scopes))
      end

      protected

      # Defines a named_scope for text search using the received
      # fields or the default ones.
      #
      # It uses a regexp based and case insensitive and accent
      # insensitive search.
      def text_scope(selected_fields)
        fields = selected_fields || default_text_fields
        regexp_op = connection.adapter_name == "PostgreSQL" ? "~*" : "REGEXP"
        @enabled_scopes.concat [:text]
        named_scope :text, lambda { |value|
          match = accent_insensitive_regexp(value.downcase)
          matches = fields.inject([]) { |r, f| r << match }
          conditions = fields.map { |f| "lower(#{table_name}.#{f}) #{regexp_op} ?" }.join(" OR ")
          { :conditions => [ conditions, *matches ] }
        }
      end

      # Defines publish_start and publish_end named scopes if the
      # published_at column exists
      def published_at_scopes
        # TODO: End and removal of parse_date, see I18n.parse_date
        if table_exists? && column_names.include?("published_at")
          @enabled_scopes.concat [ :publish_start, :publish_end ]
          named_scope :publish_start , lambda { |value| { :conditions => ["#{table_name}.published_at >= ?", parse_date(value)] } }
          named_scope :publish_end   , lambda { |value| { :conditions => ["#{table_name}.published_at <= ?", parse_date(value, :time_offset => 1.day)] } }
        end
      end

      # Defines the default columns to search based on existing
      # columns. Currently it uses title, name and description
      def default_text_fields
        ["title", "name", "description"].inject([]) do |result, text_field|
          result << text_field if table_exists? && column_names.include?(text_field)
          result
        end
      end

      def accent_insensitive_regexp(text)
        regexps = ["(a|á|à|â|ã|A|Á|À|Â|Ã)", "(e|é|è|ê|E|É|È|Ê)", "(i|í|ì|I|Í|Ì)", "(o|ó|ò|ô|õ|O|Ó|Ò|Ô|Õ)", "(u|ú|ù|U|Ú|Ù)", "(c|ç|C|Ç)", "(ñ|Ñ)"]
        regexps.each { |exp| text.gsub! Regexp.new(exp), exp }
        text
      end

      # Returns an array of valid scopes filtering out invalid ones
      def select_scopes(params,restrict_scopes)
        filters = params.reject {|k,v| !k.to_s.match /^filter_/ }
        scopes = filters.inject({}) { |h, (k,v)| h[k.gsub('filter_', '').to_sym] = v; h } # transform filter_bla keys into :bla
        valid_scopes = restrict_scopes || @enabled_scopes || []
        rogue_filters = scopes.keys - valid_scopes
        unless rogue_filters.blank?
          raise Ubiquo::InvalidFilter, "Unexpected filter received in params: #{rogue_filters.inspect}"
        end
        scopes
      end

    end

  end
end

ActiveRecord::Base.send(:include, Ubiquo::FilteredSearch)
