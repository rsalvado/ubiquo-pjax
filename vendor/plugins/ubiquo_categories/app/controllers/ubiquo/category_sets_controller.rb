class Ubiquo::CategorySetsController < UbiquoController

  ubiquo_config_call :categories_access_control, {:context => :ubiquo_categories}
  before_filter :load_category_set, :only => [:show, :edit, :update, :destroy]
  
  # GET /category_sets
  # GET /category_sets.xml
  def index
    order_by = params[:order_by] || 'category_sets.id'
    sort_order = params[:sort_order] || 'desc'
    
    filters = {
      :text => params[:filter_text],
    }

    per_page = Ubiquo::Config.context(:ubiquo_categories).get(:category_sets_per_page)
    @category_sets_pages, @category_sets = CategorySet.paginate(:page => params[:page], :per_page => per_page) do
      # remove this find and add something like this:
      # CategorySet.filtered_search filters, :order => "#{order_by} #{sort_order}"
      CategorySet.filtered_search filters, :order => "#{order_by} #{sort_order}"
    end

    @can_manage = Ubiquo::Config.context(:ubiquo_categories).get(:administrable_category_sets)
    
    respond_to do |format|
      format.html # index.html.erb  
      format.xml  {
        render :xml => @category_sets
      }
    end
  end

  # GET /category_sets/1
  # GET /category_sets/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @category_set }
    end
  end


  # GET /category_sets/new
  # GET /category_sets/new.xml
  def new
    @category_set = CategorySet.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @category_set }
    end
  end

  # GET /category_sets/1/edit
  def edit
  end

  # POST /category_sets
  # POST /category_sets.xml
  def create
    @category_set = CategorySet.new(params[:category_set])

    respond_to do |format|
      if @category_set.save
        flash[:notice] = t("ubiquo.category_set.created")
        format.html { redirect_to(ubiquo_category_sets_url) }
        format.xml  { render :xml => @category_set, :status => :created, :location => @category_set }
      else
        flash[:error] = t("ubiquo.category_set.create_error")
        format.html { render :action => "new" }
        format.xml  { render :xml => @category_set.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /category_sets/1
  # PUT /category_sets/1.xml
  def update
    respond_to do |format|
      if @category_set.update_attributes(params[:category_set])
        flash[:notice] = t("ubiquo.category_set.edited")
        format.html { redirect_to(ubiquo_category_sets_url) }
        format.xml  { head :ok }
      else
        flash[:error] = t("ubiquo.category_set.edit_error")
        format.html { render :action => "edit" }
        format.xml  { render :xml => @category_set.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /category_sets/1
  # DELETE /category_sets/1.xml
  def destroy
    if @category_set.destroy
      flash[:notice] = t("ubiquo.category_set.destroyed")
    else
      flash[:error] = t("ubiquo.category_set.destroy_error")
    end
    respond_to do |format|
      format.html { redirect_to(ubiquo_category_sets_url) }
      format.xml  { head :ok }
    end
  end

  private

  def load_category_set
    @category_set = CategorySet.find(params[:id])
  end
end
