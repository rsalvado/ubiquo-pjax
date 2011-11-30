module Ubiquo::JobsHelper

  def job_filters
    filters_for 'UbiquoJobs::Jobs::ActiveJob' do |f|
      f.text :caption => t('ubiquo.jobs.text')
      f.date(
        :field   => [:filter_date_start, :filter_date_end],
        :caption => t('ubiquo.jobs.creation_date')
      )
    end
  end

  def short_date(date)
    date.in_time_zone('Madrid').strftime('%d/%m/%Y %H:%M') if date
  end

  def state_name(state)
    case state
    when UbiquoJobs::Jobs::Base::STATES[:waiting]
      t('ubiquo.jobs.state.waiting')
    when UbiquoJobs::Jobs::Base::STATES[:instantiated]
      t('ubiquo.jobs.state.instantiated')
    when UbiquoJobs::Jobs::Base::STATES[:started]
      t('ubiquo.jobs.state.started')
    when UbiquoJobs::Jobs::Base::STATES[:finished]
      t('ubiquo.jobs.state.finished')
    when UbiquoJobs::Jobs::Base::STATES[:error]
      t('ubiquo.jobs.state.error')
    end
  end

  def priority_name(priority)
    case priority
    when UbiquoJobs::Jobs::Base::PRIORITIES[:high]
      t('ubiquo.jobs.priority.high')
    when UbiquoJobs::Jobs::Base::PRIORITIES[:medium]
      t('ubiquo.jobs.priority.medium')
    when UbiquoJobs::Jobs::Base::PRIORITIES[:low]
      t('ubiquo.jobs.priority.low')
    end
  end

  def job_actions(job, context = 'index')
    remove_action = link_to(t('ubiquo.jobs.remove'), ubiquo_job_path(job.id), :confirm => t('ubiquo.jobs.remove_confirmation'), :method => :delete)
    repeat_action  = link_to(t('ubiquo.jobs.repeat'), repeat_ubiquo_job_path(job.id), :confirm => t('ubiquo.jobs.repeat_confirmation'), :method => :put)
    output_action = link_to(t('ubiquo.jobs.read_output'), output_ubiquo_job_path(job.id), :class => "lightwindow", :type => "page", :params => "lightwindow_width=610")
    if context == 'index'
      if job.state == UbiquoJobs::Jobs::Base::STATES[:error]
        [remove_action, repeat_action, output_action]
      else
        [remove_action]
      end
    else
      [repeat_action, output_action]
    end
  end
end
