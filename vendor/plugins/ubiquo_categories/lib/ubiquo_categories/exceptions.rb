
# Raised when there is an attempt of add a category to a relation that is full
class UbiquoCategories::LimitError < StandardError; end

# Raised when there is an attempt to use a categorization that does not exist
class UbiquoCategories::CategorizationNotFoundError < StandardError; end

# Raised when there is an attempt to create categories inside a not editable set
class UbiquoCategories::CreationNotAllowed < StandardError; end

# Raised when there is an assignation to a category set that does not exist
class UbiquoCategories::SetNotFoundError < StandardError

  def initialize *args
    @key = args.first
  end

  def to_s
    @key ? "CategorySet with key '#{@key}' was not found" : super
  end
end

