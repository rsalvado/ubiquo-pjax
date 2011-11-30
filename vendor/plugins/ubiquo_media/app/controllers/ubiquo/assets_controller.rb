class Ubiquo::AssetsController < UbiquoController
  ubiquo_config_call :assets_access_control, {:context => :ubiquo_media}
  before_filter :load_asset_visibilities
  before_filter :load_asset_types

  # GET /assets
  # GET /assets.xml
  def index
    params[:order_by] = params[:order_by] || Ubiquo::Config.context(:ubiquo_media).get(:assets_default_order_field)
    params[:sort_order] = params[:sort_order] || Ubiquo::Config.context(:ubiquo_media).get(:assets_default_sort_order)

    filters = {
      :type => params[:filter_type],
      :text => params[:filter_text],
      :visibility => params[:filter_visibility],
      :created_start => parse_date(params[:filter_created_start]),
      :created_end => parse_date(params[:filter_created_end], :time_offset => 1.day),
    }.merge(uhook_index_filters)

    per_page = Ubiquo::Config.context(:ubiquo_media).get(:assets_elements_per_page)
    @assets_pages, @assets = Asset.ubiquo_paginate(:page => params[:page], :per_page => per_page) do
      uhook_index_search_subject.filtered_search(filters, :order => params[:order_by] + " " + params[:sort_order])
    end

    respond_to do |format|
      format.html{ } # index.html.erb
      format.xml{
        render :xml => @assets
      }
    end
  end

  # GET /assets/new
  # GET /assets/new.xml
  def new
    @asset = uhook_new_asset

    respond_to do |format|
      format.html{ } # new.html.erb
      format.xml{ render :xml => @asset }
    end
  end

  # GET /assets/1/edit
  def edit
    @asset = Asset.find(params[:id])
    return if uhook_edit_asset(@asset) == false
  end

  # POST /assets
  # POST /assets.xml
  def create
    counter = params.delete(:counter)
    field = params.delete(:field)
    visibility = get_visibility(params)
    asset_visibility = "asset_#{visibility}".classify.constantize
    @asset = uhook_create_asset asset_visibility
    respond_to do |format|
      if @asset.save
        flash[:notice] = t('ubiquo.media.asset_created')
        format.html { redirect_to(ubiquo_assets_path) }
        format.xml  { render :xml => @asset, :status => :created, :location => @asset }
        format.js {
          responds_to_parent do
            render :update do |page|
              page << "media_fields.add_element('#{field}',null,#{@asset.id},"+
                "#{@asset.name.to_s.to_json}, #{counter}, "+
                "#{thumbnail_url(@asset).to_json},"+
                "#{view_asset_link(@asset).to_json},null,"+
                "{advanced_form:#{advanced_asset_form_for(@asset).to_json}});"
              # Here we set @asset to be a new asset, to render the partial form with empty values
              saved_asset = @asset
              @asset = asset_visibility.new
              page.replace_html(
                "add_#{counter}",
                :partial => "ubiquo/asset_relations/asset_form",
                :locals => {
                  :counter => counter,
                  :field => field,
                  :visibility => visibility
                })
              @asset = saved_asset
            end
          end
        }
      else
        flash[:error] = t('ubiquo.media.asset_create_error')
        format.html {
          render :action => "new"
        }
        format.xml  { render :xml => @asset.errors, :status => :unprocessable_entity }
        format.js {
          responds_to_parent do
            render :update do |page|
              page.replace_html(
                "add_#{counter}",
                :partial => "ubiquo/asset_relations/asset_form",
                :locals => {
                  :field => field,
                  :counter => counter,
                  :visibility => visibility
                })
            end
          end
        }
      end
    end
  end

  # PUT /assets/1
  # PUT /assets/1.xml
  def update
    @asset = Asset.find(params[:id])
    respond_to do |format|
      if @asset.update_attributes(params[:asset])
        flash[:notice] = t('ubiquo.media.asset_updated')
        format.html { redirect_to(ubiquo_assets_path) }
        format.xml  { head :ok }
      else
        flash[:error] = t('ubiquo.media.asset_update_error')
        format.html {
          render :action => "edit"
        }
        format.xml  { render :xml => @asset.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /assets/1
  # DELETE /assets/1.xml
  def destroy
    @asset = Asset.find(params[:id])
    if uhook_destroy_asset(@asset)
      flash[:notice] = t('ubiquo.media.asset_removed')
    else
      flash[:error] = t('ubiquo.media.asset_remove_error')
    end

    respond_to do |format|
      format.html { redirect_to(ubiquo_assets_path) }
      format.xml  { head :ok }
    end
  end

  # GET /assets
  def search
    @field = params[:field]
    @counter = params[:counter]
    @search_text = params[:text]
    @page = params[:page] || 1
    @assets_pages, @assets = Asset.ubiquo_paginate(:page => @page, :per_page => Ubiquo::Config.context(:ubiquo_media).get(:media_selector_list_size)) do
      uhook_index_search_subject.filtered_search({:text => @search_text, :type => params[:asset_type_id], :visibility => params[:visibility]}, {:order => "#{Asset.table_name}.id desc"})
    end
  end

  # GET /assets/1/advanced_edit
  def advanced_edit
    @asset = Asset.find(params[:id])
    if !@asset.is_resizeable?
      flash[:error] = t('ubiquo.media.asset_not_resizeable')
      redirect_to :action => "index"
    else
      render :layout => false
    end
  end

  # PUT /assets/1/advanced_update
  def advanced_update
    @asset = Asset.find(params[:id])
    errors = !@asset.is_resizeable? || !params[:crop_resize]

    unless params[:crop_resize_save_as_new].blank?
      original_asset = @asset
      @asset = @asset.clone
      @asset.name = params[:asset_name] || @asset.name
      @asset.save!
    end

    @asset.keep_backup = ( params[:asset][:keep_backup] rescue Ubiquo::Config.context(:ubiquo_media).get(:assets_default_keep_backup))
    errors ||= !@asset.save

    asset_area = nil
    if params[:operation_type] != "original"
      # Dont save original if crop is not on original, and viceversa
      params[:crop_resize].delete(:original)
      #Save asset_areas
      params[:crop_resize].each do |style, values|
        asset_area = @asset.asset_areas.find_by_style(style)
        if asset_area
          asset_area.update_attributes( values )
        else
          asset_area = @asset.asset_areas.new(
            :style => style,
            :width => values["width"],
            :height => values["height"],
            :top => values["top"],
            :left => values["left"]
          )
          asset_area.save
        end
        if !asset_area.errors.empty?
          errors = true
          break
        end
      end unless errors
      unless errors
        @asset.resource.reprocess!
        @asset.touch
      end
    else
      if params[:crop_resize]["original"].find{|k,v|v.to_i > 0}
        begin
          AssetArea.original_crop! params[:crop_resize]["original"].merge(
            :asset => @asset, :style => "original") unless errors
        rescue ActiveRecord::RecordInvalid => e
          @rescued_exception = e
          errors = true
        end
      end
    end

    respond_to do |format|
      if !errors && @asset.errors.empty? && @asset.resource.errors.empty?
        flash[:notice] = t('ubiquo.media.asset_updated')

        if params[:apply] || params[:save_as_new]
          format.any{ redirect_to( advanced_edit_ubiquo_asset_path(@asset, :target => params[:target]) )}
        elsif params[:target]
          flash.delete :notice
          format.any{ render "advanced_update_target", :layout => false }
        else
          format.html { redirect_to(ubiquo_assets_path) }
          format.xml  { head :ok }
        end
      else
        #Destroy cloned
        if original_asset
          @asset.destroy
          @asset = original_asset
        end

        if @rescued_exception
          flash[:error] = t('ubiquo.media.asset_original_crop_error') % @rescued_exception.record.errors.full_messages.join(" ")
        else
          flash[:error] = t('ubiquo.media.asset_update_error')
        end
        format.html {
          render :action => "advanced_edit", :layout => false
        }
        format.xml  { render :xml => @asset.errors, :status => :unprocessable_entity }
      end
    end
  end

  # POST /assets/1/restore
  def restore
    @asset = Asset.find(params[:id])
    return if uhook_edit_asset(@asset) == false
    if @asset.restore!
      flash[:notice] = t('ubiquo.media.asset_updated')
    else
      flash[:error] = t('ubiquo.media.asset_update_error')
    end
    redirect_to advanced_edit_ubiquo_asset_path(@asset, :target => params[:target])
  end


  private

  def load_asset_visibilities
    @asset_visibilities = [
                           OpenStruct.new(:key => 'public', :name => t('ubiquo.media.public')),
                           OpenStruct.new(:key => 'private', :name => t('ubiquo.media.private'))
                          ]
  end

  def load_asset_types
    @asset_types = AssetType.find :all
  end

  def get_visibility(params)
    if (forced_vis = Ubiquo::Config.context(:ubiquo_media).get(:force_visibility))
      return forced_vis
    end
    if %w{private 1 true}.include?(params[:asset][:is_protected])
      "private"
    else
      "public"
    end
  end

end
