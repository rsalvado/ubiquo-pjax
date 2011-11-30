class Ubiquo::UbiquoUsersController < UbiquoController
  
  #eval this option is a lambda that will be called in that context. Normally contains the access control method invocation
  ubiquo_config_call(:user_access_control, {:context => :ubiquo_authentication})
  
  before_filter :load_roles
  
  # GET /ubiquo_users
  # GET /ubiquo_users.xml
  def index
    order_by = params[:order_by] || Ubiquo::Config.context(:ubiquo_authentication).get(:ubiquo_users_default_order_field)
    sort_order = params[:sort_order] || Ubiquo::Config.context(:ubiquo_authentication).get(:ubiquo_users_default_sort_order)
    per_page = Ubiquo::Config.context(:ubiquo_authentication).get(:ubiquo_users_elements_per_page)
    filters = {
      "filter_admin" => (params[:filter_admin].blank? ? nil : (params[:filter_admin].to_s=="1").to_s),
      "filter_text" => params[:filter_text],
      "per_page" => per_page,
      "order_by" => order_by,
      "sort_order" => sort_order
    }
    @ubiquo_users_pages, @ubiquo_users = UbiquoUser.paginated_filtered_search(params.merge(filters))

    respond_to do |format|
      format.html { } # index.html.erb
      format.xml  {
        render :xml => @ubiquo_users
      }
    end
  end

  # GET /ubiquo_users/new
  # GET /ubiquo_users/new.xml
  def new
    @ubiquo_user = UbiquoUser.new(:is_active => true)

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @ubiquo_user }
    end
  end

  # GET /ubiquo_users/1/edit
  def edit
    @ubiquo_user = UbiquoUser.find(params[:id])
  end

  # POST /ubiquo_users
  # POST /ubiquo_users.xml
  def create
    @ubiquo_user = UbiquoUser.new(params[:ubiquo_user])

    is_admin_to_allow_admin = @ubiquo_user.is_admin ? current_ubiquo_user.is_admin : true
    
    respond_to do |format|
      if is_admin_to_allow_admin && @ubiquo_user.save
        if params[:send_confirm_creation]
          UbiquoUsersNotifier.deliver_confirm_creation(
            @ubiquo_user, 
            params[:welcome_message], 
            request.host_with_port
            )
        end
        flash[:notice] = t("ubiquo.auth.user_created")
        format.html { redirect_to(ubiquo_ubiquo_users_path) }
        format.xml  { render :xml => @ubiquo_user, :status => :created, :location => @ubiquo_user }
      else
        flash[:error] = t("ubiquo.auth.user_create_error")
        format.html { render :action => "new" }
        format.xml  { render :xml => @ubiquo_user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /ubiquo_users/1
  # PUT /ubiquo_users/1.xml
  def update
    @ubiquo_user = UbiquoUser.find(params[:id])
    %w{password password_confirmation}.each do |atr|
      params.delete(atr.to_sym) if params[atr.to_sym].blank?
    end

    is_admin_to_allow_admin = params[:ubiquo_user][:is_admin].present? ? current_ubiquo_user.is_admin : true
    respond_to do |format|
      if is_admin_to_allow_admin && @ubiquo_user.update_attributes(params[:ubiquo_user])
        flash[:notice] = t("ubiquo.auth.user_edited")
        format.html { redirect_to(ubiquo_ubiquo_users_path) }
        format.xml  { head :ok }
      else
        flash[:error] = t("ubiquo.auth.user_edit_error")
        format.html { render :action => "edit" }
        format.xml  { render :xml => @ubiquo_user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /ubiquo_users/1
  # DELETE /ubiquo_users/1.xml
  def destroy
    @ubiquo_user = UbiquoUser.find(params[:id])
    is_admin_to_allow_admin = @ubiquo_user.is_admin ? current_ubiquo_user.is_admin : true
    if is_admin_to_allow_admin && @ubiquo_user.destroy
      flash[:notice] = t("ubiquo.auth.user_removed")
    else
      flash[:error] = t("ubiquo.auth.user_remove_error")
    end

    respond_to do |format|
      format.html { redirect_to(ubiquo_ubiquo_users_path) }
      format.xml  { head :ok }
    end
  end
  
  private
  
  def load_roles 
    @roles = Role.all
  end
end
