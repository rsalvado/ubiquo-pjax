class Ubiquo::ArticlesController < UbiquoController

  uses_tiny_mce(:options => default_tiny_mce_options)
  register_activity :create, :update, :destroy
  
  # GET /articles
  # GET /articles.xml
  def index
    @articles_pages, @articles = Article.paginated_filtered_search(params)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  {
        render :xml => @articles
      }
    end
  end

  # GET /articles/1
  # GET /articles/1.xml
  def show
    @article = Article.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @article }
    end
  end


  # GET /articles/new
  # GET /articles/new.xml
  def new
    @article = Article.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @article }
    end
  end

  # GET /articles/1/edit
  def edit
    @article = Article.find(params[:id])
  end

  # POST /articles
  # POST /articles.xml
  def create
    @article = Article.new(params[:article])

    respond_to do |format|
      if @article.save
        flash[:notice] = t("ubiquo.article.created")
        format.html { redirect_to(ubiquo_articles_url) }
        format.xml  { render :xml => @article, :status => :created, :location => @article }
      else
        flash[:error] = t("ubiquo.article.create_error")
        format.html { render :action => "new" }
        format.xml  { render :xml => @article.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /articles/1
  # PUT /articles/1.xml
  def update
    @article = Article.find(params[:id])
    ok = @article.update_attributes(params[:article])

    respond_to do |format|
      if ok
        flash[:notice] = t("ubiquo.article.edited")
        format.html { redirect_to(ubiquo_articles_url) }
        format.xml  { head :ok }
      else
        flash[:error] = t("ubiquo.article.edit_error")
        format.html { render :action => "edit" }
        format.xml  { render :xml => @article.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /articles/1
  # DELETE /articles/1.xml
  def destroy
    @article = Article.find(params[:id])
    if @article.destroy
      flash[:notice] = t("ubiquo.article.destroyed")
    else
      flash[:error] = t("ubiquo.article.destroy_error")
    end
    respond_to do |format|
      format.html { redirect_to(ubiquo_articles_url) }
      format.xml  { head :ok }
    end
  end
end
