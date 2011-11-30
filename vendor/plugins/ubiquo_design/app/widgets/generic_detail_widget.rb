Widget.behaviour :generic_detail do |widget|
  @model = widget.model
  @element = widget.element(params[:url].last)
end
