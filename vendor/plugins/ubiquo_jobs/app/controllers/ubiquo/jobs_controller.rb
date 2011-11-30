class Ubiquo::JobsController < UbiquoController
  # GET /jobs
  # GET /jobs.xml
  def index
    generic_index(false)
  end

  # GET /jobs/history
  # GET /jobs/history.xml
  def history
    generic_index(true)
  end

  # DELETE /jobs/1
  # DELETE /jobs/1.xml
  def destroy
    if UbiquoJobs.manager.delete(params[:id])
      flash[:notice] = t("ubiquo.jobs.job_removed")
    else
      flash[:error] = t("ubiquo.jobs.cant_remove")
    end

    respond_to do |format|
      format.html { redirect_to(ubiquo_jobs_path) }
      format.xml  { head :ok }
    end
  end
  
  # PUT /jobs/1
  # PUT /jobs/1.xml
  def update
    respond_to do |format|
      if UbiquoJobs.manager.update(params[:id], params[:job])
        flash[:notice] = t("ubiquo.jobs.job_edited")
        format.html { redirect_to(ubiquo_jobs_path) }
        format.xml  { head :ok }
        format.js
      else
        flash[:error] = t("ubiquo.jobs.cant_edit")
        format.html { render :action => "edit" }
        format.xml  { render :status => :unprocessable_entity }
        format.js
      end
    end
  end

  # PUT /jobs/1/repeat
  def repeat    
    UbiquoJobs.manager.repeat(params[:id])
    respond_to do |format|
      flash[:notice] = t("ubiquo.jobs.job_repeated")
      format.html { redirect_to(ubiquo_jobs_path) }
      format.xml  { head :ok }
      format.js
    end
  end

  # PUT /jobs/1/repeat
  def output
    @job = UbiquoJobs.manager.get_by_id(params[:id])
    render :layout => false
  end

  private
  
  def generic_index(finished)
    respond_to do |format|
      format.html {
        order_by = params[:order_by] || 'id'
        sort_order = params[:sort_order] || 'desc'
        
        filters = {
          :text => params[:filter_text],
          :date_start => params[:filter_date_start],
          :date_end => params[:filter_date_end],
          :state => (UbiquoJobs::Jobs::Base::STATES[:finished] if finished),
          :state_not => (UbiquoJobs::Jobs::Base::STATES[:finished] unless finished),
          :page => params[:page],
          :order => "#{order_by.gsub(/^.*\./, '')} #{sort_order}"
        }
        @jobs_pages, @jobs = UbiquoJobs.manager.list(filters) 
      } # index.html.erb or history.html.erb
      format.xml  {
        @jobs = UbiquoJobs.manager.list
        render :xml => @jobs
      }
    end    
  end
end
