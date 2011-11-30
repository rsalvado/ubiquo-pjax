class Ubiquo::DesignsController < UbiquoController
  class UnpreviewablePage < StandardError; end
  include UbiquoDesign::RenderPage
  helper 'ubiquo/widgets'
  ubiquo_config_call :design_access_control, {:context => :ubiquo_design}
  uses_tiny_mce(:options => default_tiny_mce_options.merge(:entities => ''))

  def show
    @page = Page.find(params[:page_id])
    @template_content = render_ubiquo_design_template(@page)
  end

  def preview
    @page = Page.find(params[:page_id])
    unless @page.is_previewable?
      raise Ubiquo::DesignsController::UnpreviewablePage.new
    else
      @page.blocks.map(&:widgets).flatten.each do |widget|
        params.merge!(widget.respond_to?(:preview_params) ? widget.preview_params : {})
      end
      render_page(@page)
    end
  end

  def publish
    page = Page.find(params[:page_id])
    if page.publish
      flash[:notice] = t('ubiquo.design.page_published')
    else
      flash[:error] = t('ubiquo.design.page_publish_error')
    end
    redirect_to :action => "show"
  end

  def unpublish
    page = Page.find(params[:page_id])
    if page.unpublish
      flash[:notice] = t('ubiquo.design.page_unpublished')
    else
      flash[:error] = t('ubiquo.design.page_unpublish_error')
    end
    redirect_to :action => "show"
  end
  
  private

  def render_ubiquo_design_template(page)
    template_file = Rails.root.join("app/views/page_templates/ubiquo/#{page.page_template}.html.erb")
    if File.exists?(template_file)
      template_contents = render_to_string(:file => template_file, 
                                           :locals => { :page => page })
    else
      template_contents = render_to_string(:inline => <<-EOS, :locals => { :page => page })
        <% page.template_structure.map do |block_key, num_cols, subblocks| %>
          <%= send("block_for_design", page, block_key.to_s, num_cols, subblocks) %>
        <% end %>
      EOS
    end

    render_to_string :partial => 'template',
                     :locals => {:template_contents => template_contents, :page => page}
  end
end
