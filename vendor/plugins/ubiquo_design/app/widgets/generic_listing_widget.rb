Widget.behaviour :generic_listing do |widget|
  @model = widget.model
  @title = widget.title
  @show_images = widget.show_images
  @elements_pages, @elements = @model.constantize.paginate(:page => params[:page], :per_page => widget.per_page) do
    widget.elements
  end
end
