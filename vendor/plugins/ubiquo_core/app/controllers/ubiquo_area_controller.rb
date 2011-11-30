# UbiquoAreaController legacy support
# Using a real class instead of ActiveSupport::Deprecation::DeprecatedConstantProxy 
# because else you can't create subclasses of it (which was the primary use of UAC)
# TODO to be removed from the 0.9.0 release
class UbiquoAreaController < UbiquoController
  def self.inherited(subclass)
    ActiveSupport::Deprecation.warn("UbiquoAreaController is deprecated! #{subclass} should be a subclass of UbiquoController instead.")
    super
  end
end