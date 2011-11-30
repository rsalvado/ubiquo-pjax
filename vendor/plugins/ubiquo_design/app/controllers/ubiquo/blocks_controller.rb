class Ubiquo::BlocksController < UbiquoController
  helper 'ubiquo/designs'
  helper 'ubiquo/widgets'
  def update
    @block = Block.find(params[:id])
    @page = Page.find(params[:page_id])
    @block.update_attributes(
      :is_shared => params[:is_shared],
      :shared_id => params[:shared_id])
    if @block.shared_id
      @block.widgets.map(&:destroy)
    end
    respond_to do |format|
      format.html { redirect_to(ubiquo_page_design_path(@page)) }
      format.js
    end
  end
end
