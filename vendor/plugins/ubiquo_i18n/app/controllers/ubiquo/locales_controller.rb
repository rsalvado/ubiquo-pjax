class Ubiquo::LocalesController < UbiquoController
  
  ubiquo_config_call(:locales_access_control, {:context => :ubiquo_i18n})
  
  def show
    order_by = params[:order_by] || Ubiquo::Config.context(:ubiquo_i18n).get(:locales_default_order_field)
    sort_order = params[:sort_order] || Ubiquo::Config.context(:ubiquo_i18n).get(:locales_default_sort_order)
    @locales =  Locale.all(:order => order_by + " " + sort_order)

    respond_to do |format|
      format.html { } # index.html.erb
      format.xml  {
        render :xml => @locales
      }
    end
  end
  
  def update
    if params[:selected_locales].include?(params[:default_locale])
    Locale.transaction{
      Locale.update_all :is_active => false
      Locale.update_all({:is_active => true}, {:id => params[:selected_locales]})

      Locale.update_all :is_default => false
      Locale.update_all({:is_default => true}, {:id => params[:default_locale]})
    }
      flash[:notice] = t("ubiquo.i18n.locales_updated")
    else
      flash[:error] = t("ubiquo.i18n.select_default_locale_error")
    end
    redirect_to ubiquo_locales_path
  end
  
end
