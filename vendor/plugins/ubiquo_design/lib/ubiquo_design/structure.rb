# Manages the declaration of block structures
module UbiquoDesign
  module Structure

    @@structures  ||= []

    class << self

      # Starts the definition of an structure
      #   context: possible context to create multiple structures
      def define(context = nil, &block)
        with_scope(context) do
          yield_inside(&block)
        end
      end

      # Returns a list of the applicable identifiers
      #   key:      what we want to obtain
      #   filters:  optional filters to scope the values
      #   context:  possible context for multiple structures
      def find(key, filters = {}, context = nil)
        with_scope(context) do
          get(filters)[key].map(&:keys).flatten rescue []
        end
      end

      # Returns a hash with the required structure
      #   args: can either be
      #         nil (default): returns the whole structure as stored
      #         a hash, in this case it's interpreted as a filter
      #         [context, hash] to use a non-default context to filter
      def get(*args)
        result = case args[0]
        when String, Symbol
          with_scope(args[0].to_sym) do
            filter(args[1])
          end
        else
          filter(args[0])
        end
        concat_merge(result)
      end

      # Sets the current context during a declaration
      def with_scope(scope)
        (@@scopes ||= []) << scope
        yield ensure @@scopes.pop
      end

      # Cleans the current structure
      #   context: possible context for multiple structures
      def clear(context = nil)
        with_scope(context) { current_base.clear }
      end

      # Yields a block with this module binding
      def yield_inside(&block)
        block.bind(self).call
      end

      # Catches all the possible calls and stores them
      def method_missing(method, *args, &block)
        scope = scope_name(method)
        with_scope(scope) do
          store_definition args, &block
        end
      end

      # Stores an invocation definition
      def store_definition args, &block
        base = current_base
        options = args.extract_options!
        args.inject(base) do |acc, element|
          container = {element => []}
          container[element] << {:options => options} unless options.empty?
          (acc << container).tap do
            with_scope(element, &block) if block_given?
          end
        end
      end

      # Given a set of filters, returns the appropiate information
      #   filters:  can be either nil (no filter) or a hash of conditions
      #             in the form {:filter => value}
      #   base:     base set of results to filter. Defaults to current_base
      def filter(filters, base = nil)
        results = {}
        base ||= current_base
        case filters
        when Hash
          results = []
          base.each do |element|
            element.keys.each do |element_key|
              # retrieve the filters key that may limit this element_key
              applicable_key = filters.keys.select do |key|
                scope_name(key) == element_key
              end.first

              # if there is a filter to apply, compare its value
              if applicable_key
                # the value to compare can be an array of inclusive possibilites
                Array(filters[applicable_key]).each do |filter_value|
                  found = find_in_scope(
                    element[element_key],
                    filter_value
                  )
                  results.concat(found.values.flatten) if found
                end
              else
                results << element
              end
            end
          end
          # call recursively while it's filtering
          results = filter(filters, results) unless results == base
        else
          results = base
        end
        results
      end

      # Homogenizes a scope name to a pluralized symbol
      def scope_name name
        name.to_s.pluralize.to_sym
      end

      # Returns the current base array, given the applied scopes
      def current_base
        current = @@structures
        @@scopes.each do |scope|
          next unless scope
          if !struct = find_in_scope(current, scope)
            current << (struct = {scope => []})
          end
          current = struct.values.first
        end
        current
      end

      # Returns the hash scope +element+ in the +scope+, if exists
      def find_in_scope scope, element
        scope.select do |struct|
          struct.keys.include?(element.to_sym)
        end.first
      end

      # Performs a merge concatenating the results sharing keys
      def concat_merge original
        {}.tap do |result|
          original.each do |element|
            element.each_pair do |key, value|
              if value.is_a?(Array)
                result[key] ||= []
                result[key].concat value
                merge_if_equals(result[key])
              else
                result[key] = value
              end
            end
          end
        end
      end

      # Given an array of hashes, will merge them if they share the key
      def merge_if_equals(array)
        merged = []
        keymap = {}
        array.each do |hash|
          key = hash.keys.first
          if i = keymap[key]
            merged[i].values.first.concat hash.values.first
          else
            keymap[key] = merged.size
            merged << hash
          end
        end
        array.replace(merged)
      end
    end
  end
end
