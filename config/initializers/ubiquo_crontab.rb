# -*- coding: utf-8 -*-
Ubiquo::Cron::Crontab.schedule do |cron|
  # Who to mail on errors
  # cron.mailto = 'errors@change.me'

  # *     *     *   *    *
  # -     -     -   -    -
  # |     |     |   |    |
  # |     |     |   |    +----- day of week (0 - 6) (Sunday=0)
  # |     |     |   +------- month (1 - 12)
  # |     |     +--------- day of        month (1 - 31)
  # |     +----------- hour (0 - 23)
  # +------------- min (0 - 59)

  # Examples:
  # "30 08 10 06 *"  Executes on 10th June 08:30 AM.
  # "00 11,16 * * *" Executes at 11:00 and 16:00 on every day.
  # "00 09-18 * * *" Executes everyday (including weekends) during the working hours 9 a.m – 6 p.m
  # "* * * * *"      Execute every minute.
  # "*/10 * * * *"   Execute every 10 minutes.
  # "@hourly"        Execute every hour.
  # "@daily"         Execute daily.
  # "@monthly"       Execute monthly.
  # "@reboot"        Execute after every reboot.

  # The specification of days can be made in two fields: month day and weekday.
  # If both are specified in an entry, they are cumulative meaning both of the entries will get executed.

  # See man 5 crontab for more information.

  # Executes the routes (rake) task every minute
  # cron.rake   "* * * * *", "routes"

  # Executes the routes (rake) task every minute and logs debug information
  # cron.rake   "* * * * *", "routes debug='true'"

  # Executes a script/runner like task
  # cron.runner "* * * * *", "puts 6+6"
end
