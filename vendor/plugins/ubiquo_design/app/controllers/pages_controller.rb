class PagesController < PublicController

  # Renders a Page using its associated template, displaying its blocks and widgets
  def show
    @page = uhook_load_page
    render_page @page
  end

end
