class Ubiquo::WidgetsController < UbiquoController
  before_filter :load_page
  ubiquo_config_call :design_access_control, {:context => :ubiquo_design}

  helper "ubiquo/designs"
  def show
    @widget = uhook_find_widget

    template_path = "/widgets/%s/ubiquo/edit.html.erb" % @widget.key
    render :file => template_path, :locals => {:page => @page, :widget => @widget}
  end

  def create
    @block = Block.find(params[:block])

    widget_key = params[:widget] ? params[:widget].split('___').first : nil
    @widget = Widget.class_by_key(widget_key).new
    raise "#{widget_key} is not a widget" unless @widget.is_a? Widget

    @widget.block = @block
    @widget.name = Widget.default_name_for widget_key
    @widget = uhook_prepare_widget(@widget)
    @widget.save_without_validation

    respond_to do |format|
      format.html { redirect_to(ubiquo_page_design_path(@page)) }
      format.js {
        render :update do |page|
          page.insert_html :bottom, "block_type_holder_#{@block.block_type}", :partial => "ubiquo/widgets/widget", :object => @widget
          page.hide "widget_#{@widget.id}"
          page.visual_effect :slide_down, "widget_#{@widget.id}"
          id, opts = sortable_block_type_holder_options(@block.block_type,
                                                        change_order_ubiquo_page_design_widgets_path(@page),
                                                        @page.blocks.map(&:block_type))
          page.sortable id, opts
          page << "myLightWindow._processLink($('edit_widget_#{@widget.id}'));" if @widget.is_configurable?
          page.replace_html("page_info", :partial => 'ubiquo/designs/pageinfo_sidebar',
                                         :locals => { :page => @page.reload })
          page.call "update_error_on_widgets", @page.wrong_widgets_ids
        end
      }
    end
  end

  def destroy
    @widget = Widget.find(params[:id])

    uhook_destroy_widget(@widget)

    respond_to do |format|
      format.html { redirect_to(ubiquo_page_design_path(@page))}
      format.js {
        render :update do |page|
          page.visual_effect :slide_up, "widget_#{@widget.id}"
          page.delay(1) do
            page.remove "widget_#{@widget.id}"
          end
          page.replace_html("page_info", :partial => 'ubiquo/designs/pageinfo_sidebar',
                                         :locals => { :page => @page.reload })
          page.call "update_error_on_widgets", @page.wrong_widgets_ids
        end
      }
    end
  end

  def update
    @widget = uhook_update_widget
    if @widget.valid?
      respond_to do |format|
        format.html { redirect_to(ubiquo_page_design_path(@page))}
        format.js {
          render :update do |page|
            self.uhook_extra_rjs_on_update(page, true) do |page|
              page << 'myLightWindow.deactivate();'
              page.replace_html("page_info", :partial => 'ubiquo/designs/pageinfo_sidebar',
                :locals => { :page => @page.reload })
              page.call "update_error_on_widgets", @page.wrong_widgets_ids
            end
           end
        }
      end
    else
      respond_to do |format|
        format.html { redirect_to(ubiquo_page_design_widget_path(@page, @widget))}
        format.js {
          render :update do |page|
            self.uhook_extra_rjs_on_update(page, false) do |page|
              page.replace_html('error_messages', :partial => 'ubiquo/designs/error_messages',
                :locals => {:widget => @widget})
              page << "reviveEditor();"
            end
          end
        }
      end
    end
  end

  def change_name
    @widget = Widget.find(params[:id])
    @widget.update_attributes(:name => params[:value])
    respond_to do |format|
      format.js do
        js_response = render_to_string :update do |page|
          self.uhook_extra_rjs_on_update(page, true) do |page|
            page << 'myLightWindow.deactivate();'
            page.replace_html("page_info", :partial => 'ubiquo/designs/pageinfo_sidebar',
                              :locals => { :page => @page.reload })
            page.call "update_error_on_widgets", @page.wrong_widgets_ids
            page.replace_html("widget_name_field_#{@widget.id}", @widget.name)
          end
        end

        render :inline => "<%= javascript_tag(#{js_response.to_json}) %>", :locals => {:js_response => js_response }
      end
    end
  end

  def change_order
    unless params[:block].blank?
      params[:block].each do |block_type, widget_ids|
        block = @page.blocks.first(:conditions => { :block_type => block_type })
        Widget.transaction do
          widget_ids.each_with_index do |widget_id, index|
            widget = Widget.find(widget_id)
            widget.update_attributes(:position => index, :block_id => block.id)
          end
        end
      end
    end
    respond_to do |format|
      format.html { redirect_to(ubiquo_page_design_path(@page))}
      format.js {
        render :update do |page|
          page.replace_html("page_info", :partial => 'ubiquo/designs/pageinfo_sidebar',
                                         :locals => { :page => @page.reload })
          page.call "update_error_on_widgets", @page.wrong_widgets_ids
        end
      }
    end
  end

  private

  def load_page
    @page = Page.find(params[:page_id])
  end
end
