class Ubiquo::RolesController < UbiquoController

  ubiquo_config_call :role_access_control, {:context => :ubiquo_access_control}

  before_filter :load_permissions
  
  # GET /roles
  # GET /roles.xml
  def index
    params[:order_by] = params[:order_by] || Ubiquo::Config.context(:ubiquo_access_control).get(:roles_default_order_field)
    params[:sort_order] = params[:sort_order] || Ubiquo::Config.context(:ubiquo_access_control).get(:roles_default_sort_order)
    per_page = Ubiquo::Config.context(:ubiquo_access_control).get(:roles_elements_per_page)
    @roles_pages, @roles = Role.paginate(:page => params[:page], :per_page => per_page) do
      Role.find :all, :order => params[:order_by] + " " + params[:sort_order]
    end
    
    respond_to do |format|
      format.html {} # index.html.erb
      format.xml  {
        render :xml => @roles
      }
    end
  end

  # GET /roles/new
  # GET /roles/new.xml
  def new
    @role = Role.new()
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @role }
    end
  end

  # GET /roles/1/edit
  def edit
    @role = Role.find(params[:id])
  end

  # POST /roles
  # POST /roles.xml
  def create
    @role = Role.new(params[:role])
    respond_to do |format|
      if @role.save
        [params[:permissions]].flatten.each do |permission|
          @role.add_permission(permission.to_s)
        end
        flash[:notice] = t('ubiquo.auth.role_created')
        format.html { redirect_to(ubiquo_roles_path) }
        format.xml  { render :xml => @role, :status => :created, :location => @role }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @role.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /roles/1
  # PUT /roles/1.xml
  def update
    @role = Role.find(params[:id])
    @role.role_permissions.delete_all
    [params[:permissions]].flatten.each do |permission|
      @role.add_permission(permission.to_s)
    end
    respond_to do |format|
      if @role.update_attributes(params[:role])
        flash[:notice] = t('ubiquo.auth.role_edited')
        format.html { redirect_to(ubiquo_roles_path) }
        format.xml  { head :ok }
      else
        flash[:error] = t('ubiquo.auth.role_edit_error')
        format.html { render :action => "edit" }
        format.xml  { render :xml => @role.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /roles/1
  # DELETE /roles/1.xml
  def destroy
    @role = Role.find(params[:id])
    if @role.destroy
      flash[:notice] = t('ubiquo.auth.role_removed')
    else
      flash[:error] = t('ubiquo.auth.role_remove_error')
    end

    respond_to do |format|
      format.html { redirect_to(ubiquo_roles_path) }
      format.xml  { head :ok }
    end
  end
  
  private
  
  def load_permissions
    @permissions = Permission.all
  end
end
