module Ubiquo
  module Extensions
    module Array
      # Convert  array to hash. The elements on the array 
      # must be (key, value) pairs 
      #
      # Example: 
      # 
      # >> [[1, 2], [3, 4]].to_hash
      # >> {1=>2, 3=>4}
      def to_hash
        h = {}
        each { |k, v| h[k] = v }
        h
      end
    end
  end
end
