class Ubiquo::<%= controller_class_name %>Controller < UbiquoController

  <%- if attributes.map(&:field_type).include? :text_area -%>
  uses_tiny_mce(:options => default_tiny_mce_options)
  <%- end -%>
  <%- unless options[:skip_activity] || !Ubiquo::Plugin.registered.include?(:ubiquo_activity) -%>
  register_activity :create, :update, :destroy
  <% end %>
  # GET /<%= table_name %>
  # GET /<%= table_name %>.xml
  def index
    @<%= table_name %>_pages, @<%= table_name %> = <%= class_name %><%= options[:translatable] ? ".locale(current_locale, :all)" : "" %>.paginated_filtered_search(params)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  {
        render :xml => @<%= table_name %>
      }
    end
  end

  # GET /<%= table_name %>/1
  # GET /<%= table_name %>/1.xml
  def show
    @<%= file_name %> = <%= class_name %>.find(params[:id])
    <%- if options[:translatable] %>
    unless @<%= file_name %>.in_locale?(current_locale)
      redirect_to(ubiquo_<%= table_name %>_url)
      return
    end
    <%- end %>
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @<%= file_name %> }
    end
  end


  # GET /<%= table_name %>/new
  # GET /<%= table_name %>/new.xml
  def new
    @<%= file_name %> = <%= class_name %><%= options[:translatable] ? ".translate(params[:from], current_locale)" : ".new" %>

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @<%= file_name %> }
    end
  end

  # GET /<%= table_name %>/1/edit
  def edit
    @<%= file_name %> = <%= class_name %>.find(params[:id])
    <%- if options[:translatable] -%>
    unless @<%= file_name %>.in_locale?(current_locale)
      redirect_to(ubiquo_<%= table_name %>_url)
      return
    end
    <%- end -%>
  end

  # POST /<%= table_name %>
  # POST /<%= table_name %>.xml
  def create
    @<%= file_name %> = <%= class_name %>.new(params[:<%= file_name %>])

    respond_to do |format|
      if @<%= file_name %>.save
        flash[:notice] = t("ubiquo.<%= singular_name %>.created")
        format.html { redirect_to(ubiquo_<%= table_name %>_url) }
        format.xml  { render :xml => @<%= file_name %>, :status => :created, :location => @<%= file_name %> }
      else
        flash[:error] = t("ubiquo.<%= singular_name %>.create_error")
        format.html { render :action => "new" }
        format.xml  { render :xml => @<%= file_name %>.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /<%= table_name %>/1
  # PUT /<%= table_name %>/1.xml
  def update
    @<%= file_name %> = <%= class_name %>.find(params[:id])
    <%- if options[:versionable] -%>
    ok = if params[:restore_from_version]
           @<%= file_name %>.restore params[:restore_from_version]
         else
           @<%= file_name %>.update_attributes(params[:<%= file_name %>])
         end
    <%- else -%>
    ok = @<%= file_name %>.update_attributes(params[:<%= file_name %>])
    <%- end -%>

    respond_to do |format|
      if ok
        flash[:notice] = t("ubiquo.<%= singular_name %>.edited")
        format.html { redirect_to(ubiquo_<%= table_name %>_url) }
        format.xml  { head :ok }
      else
        flash[:error] = t("ubiquo.<%= singular_name %>.edit_error")
        format.html { render :action => "edit" }
        format.xml  { render :xml => @<%= file_name %>.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /<%= table_name %>/1
  # DELETE /<%= table_name %>/1.xml
  def destroy
    @<%= file_name %> = <%= class_name %>.find(params[:id])
    <%- if options[:translatable] -%>
    destroyed = false
    if params[:destroy_content]
      destroyed = @<%= file_name %>.destroy_content
    else
      destroyed = @<%= file_name %>.destroy
    end
    if destroyed
      flash[:notice] = t("ubiquo.<%= singular_name %>.destroyed")
    else
      flash[:error] = t("ubiquo.<%= singular_name %>.destroy_error")
    end
    <%- else -%>
    if @<%= file_name %>.destroy
      flash[:notice] = t("ubiquo.<%= singular_name %>.destroyed")
    else
      flash[:error] = t("ubiquo.<%= singular_name %>.destroy_error")
    end
    <%- end -%>
    respond_to do |format|
      format.html { redirect_to(ubiquo_<%= table_name %>_url) }
      format.xml  { head :ok }
    end
  end
end
