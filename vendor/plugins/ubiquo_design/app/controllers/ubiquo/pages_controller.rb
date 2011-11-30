class Ubiquo::PagesController < UbiquoController
  ubiquo_config_call :design_access_control, {:context => :ubiquo_design}
  before_filter :load_page_templates
  before_filter :load_page, :only => [:edit, :update, :destroy]
  before_filter :load_parent_pages, :only => [:new, :edit]
  
  # GET /pages
  # GET /pages.xml
  def index
    order_by = params[:order_by] || Ubiquo::Config.context(:ubiquo_design).get(:pages_default_order_field)
    sort_order = params[:sort_order] || Ubiquo::Config.context(:ubiquo_design).get(:pages_default_sort_order)

    filters = { :text => params[:filter_text] }
    per_page = Ubiquo::Config.context(:ubiquo_design).get(:pages_elements_per_page)

    @pages_pages, @pages = Page.paginate(:page => params[:page], :per_page => per_page) do
      uhook_find_private_pages(filters, order_by, sort_order)
    end
    
    respond_to do |format|
      format.html {} # index.html.erb
      format.xml  {
        render :xml => @pages
      }
      format.js {
        render :json => @pages.to_json(:only => [:id, :name])
      }
    end
  end

  # GET /pages/new
  # GET /pages/new.xml
  def new
    @page = uhook_new_page

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @page }
    end
  end

  # GET /pages/1/edit
  def edit
  end

  # POST /pages
  # POST /pages.xml
  def create
    @page = uhook_create_page
    respond_to do |format|
      if @page.valid?
        flash[:notice] = t('ubiquo.design.page_created')
        format.html { redirect_to(ubiquo_pages_path) }
        format.xml  { render :xml => @page, :status => :created, :location => @page }
      else
        flash[:error] = t('ubiquo.design.page_create_error')
        format.html { render :action => "new" }
        format.xml  { render :xml => @page.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /pages/1
  # PUT /pages/1.xml
  def update
    respond_to do |format|
      if uhook_update_page(@page)
        flash[:notice] = t('ubiquo.design.page_edited')
        format.html { redirect_to(ubiquo_pages_path) }
        format.xml  { head :ok }
      else
        flash[:error] = t('ubiquo.design.page_edit_error')
        format.html { render :action => "edit" }
        format.xml  { render :xml => @page.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /pages/1
  # DELETE /pages/1.xml
  def destroy
    if uhook_destroy_page(@page)
      flash[:notice] = t('ubiquo.design.page_removed')
    else
      flash[:error] = t('ubiquo.design.page_remove_error')
    end

    respond_to do |format|
      format.html { redirect_to(ubiquo_pages_path) }
      format.xml  { head :ok }
    end
  end

  private
  
  def load_page_templates
    @page_templates = Page.templates
  end

  def load_page
    @page = Page.find(params[:id])    
  end
  
  def load_parent_pages
    @pages = Page.drafts.all(:conditions => ["url_name != ''"]) - [@page]
  end
  
end
