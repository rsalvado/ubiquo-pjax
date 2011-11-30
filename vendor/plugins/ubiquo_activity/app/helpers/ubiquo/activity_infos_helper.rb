module Ubiquo::ActivityInfosHelper

  def activity_info_filters
    filters_for 'ActivityInfo' do |f|
      f.date(
        :caption => t('ubiquo.activity_info.date'),
        :field => [:filter_date_start, :filter_date_end]
      ) if Ubiquo::Config.context(:ubiquo_activity).get(:activities_date_filter_enabled)

      f.links_or_select(:user, @users, {
        :name_field => :full_name,
        :id_field   => :ubiquo_user_id,
        :caption    => ActivityInfo.human_attribute_name(:user)
      }) if Ubiquo::Config.context(:ubiquo_activity).get(:activities_user_filter_enabled)

      f.link(:controller, @controllers, {
        :id_field => :key,
        :caption  => t('ubiquo.activity_info.controller')
      }) if Ubiquo::Config.context(:ubiquo_activity).get(:activities_controller_filter_enabled)

      f.link(:action, @actions, {
        :id_field => :key,
        :caption  => t('ubiquo.activity_info.action')
      }) if Ubiquo::Config.context(:ubiquo_activity).get(:activities_action_filter_enabled)

      f.link(:status, @statuses, {
        :id_field => :key,
        :caption  => t('ubiquo.activity_info.status')
      }) if Ubiquo::Config.context(:ubiquo_activity).get(:activities_status_filter_enabled)
    end
  end

  def activity_info_list(collection, pages, options = {})
    list_partial = Ubiquo::Config.context(:ubiquo_activity).get(:info_list_partial)
    concat render(:partial => "shared/ubiquo/lists/#{list_partial}", :locals => {
        :name => 'activity_info',
        :headers => [
          ActivityInfo.human_attribute_name(:user),
          :controller,
          :action,
          :status,
          :created_at
        ],
        :rows => collection.collect do |activity_info|
          {
            :id => activity_info.id,
            :columns => [
              activity_info.ubiquo_user.name,
              t("ubiquo.#{activity_info.controller.gsub('ubiquo/', '').singularize}.title"),
              t("ubiquo.activity_info.actions.#{activity_info.action}"),
              t("ubiquo.activity_info.statuses.#{activity_info.status}"),
              l(activity_info.created_at)
            ],
            :actions => activity_info_actions(activity_info)
          }
        end,
        :pages => pages
      })
  end

  def activity_info_box(activity)
    custom_partial = Rails.root.join("app", "views", activity.controller,
                                     "_activity_#{activity.action}.html.erb")
    partial = if File.exist?(custom_partial)
      "#{activity.controller}/activity_#{activity.action}"
    else
      "shared/ubiquo/activity_infos/activity_#{activity.action}"
    end
    render :partial => partial, :locals => { :activity => activity }
  end

  private

  def activity_info_actions(activity_info, options = {})
    actions = []
    actions << link_to(t("ubiquo.remove"), [:ubiquo, activity_info],
                       :confirm => t("ubiquo.activity_info.confirm_removal"),
                       :method => :delete)
    if activity_info.status != "error" && activity_info.related_object
      actions << link_to(t("ubiquo.activity_info.show_it"),
                         :action => 'show',
                         :controller => activity_info.controller,
                         :id => activity_info.related_object_id)
    end
    actions
  end
end
