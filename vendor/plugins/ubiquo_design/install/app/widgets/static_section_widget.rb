Widget.behaviour :static_section do |widget|
  @static_section = widget
  @image = widget.respond_to?(:image) ? widget.image.first : nil
  @docs = widget.respond_to?(:docs) ? widget.docs : []
end
