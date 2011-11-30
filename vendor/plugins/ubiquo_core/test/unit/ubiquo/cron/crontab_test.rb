require File.dirname(__FILE__) + "/../../../test_helper.rb"

class Ubiquo::Cron::CrontabTest < ActiveSupport::TestCase

  def setup
    @krontab = Ubiquo::Cron::Crontab
    @crontab = @krontab.instance.send(:reset!)
  end

  test "Should be able to set a mailto" do
    assert_equal 'test@test.com', @crontab.mailto = 'test@test.com'
  end

  test "Should be able to set a path" do
    assert_equal Rails.root, @crontab.path
    assert_equal "/root", @crontab.path = "/root"
  end

  test "Should be able to a log file" do
    default_log_file = File.join Rails.root, 'log', "cron-#{Rails.env}.log"
    assert_equal default_log_file, @crontab.logfile
    assert_equal '/tmp/cron.log', @crontab.logfile = '/tmp/cron.log'
  end

  test "Should be able to force a specific environment" do
    assert_equal "test", @crontab.env
    assert_equal "production", @crontab.env = "production"
  end

  test "Should be able to configure the crontab" do
    assert_respond_to @krontab, :schedule
    assert_respond_to @krontab, :instance
    @krontab.schedule do |config|
      config.path    = '/mypath'
      config.logfile = '/mylogfile'
    end
    crontab = @krontab.instance
    assert_equal '/mypath'    , crontab.path
    assert_equal '/mylogfile' , crontab.logfile
    @krontab.schedule do |config|
      config.mailto = 'test@test.com'
    end
    new_crontab = @krontab.instance
    assert_equal '/mypath'       , new_crontab.path
    assert_equal '/mylogfile'    , new_crontab.logfile
    assert_equal 'test@test.com' , new_crontab.mailto
  end

  test "Should be able add a rake task to a crontab instance" do
    assert_difference "@crontab.render.split('\n').size", +1 do
      schedule = "@weekly"; task = "ubiquo:guides"
      assert @crontab.rake schedule, task
      line = @crontab.render.split('\n').last
      assert_match /^#{Regexp.escape(schedule)} /, line
      assert_match /rake ubiquo:cron:runner task='#{task}'/, line
      assert_match /2>&1\"$/, line
    end
  end

  test "Should be able add a rake task to a crontab instance with vars" do
    assert_difference "@crontab.render.split('\n').size", +1 do
      assert @crontab.rake "@weekly", "ubiquo:guides myvar='6'"
      line = @crontab.render.split('\n').last
      assert_match /^#{Regexp.escape("@weekly")} /, line
      assert_match /rake ubiquo:cron:runner task='ubiquo:guides' myvar='6'/, line
      assert_match /2>&1\"$/, line
    end
  end

  test "Should be able to launch a script runner" do
    assert_difference "@crontab.render.split('\n').size", +1 do
      schedule = "* * * * *"; task = "Article.notify_users_on_update"
      assert @crontab.runner schedule, task
      line = @crontab.render.split('\n').last
      assert_match /^#{Regexp.escape(schedule)} /, line
      assert_match /rake ubiquo:cron:runner task='#{task}' type='script'/, line
      assert_match /2>&1\"$/, line
    end
  end

  test "Should be able to add a comment line in the crontab" do
    assert_difference "@crontab.render.split('\n').size", +2 do
      @crontab.rake("@daily","test") # comment only crontabs not rendered
      comment = "This is a comment"
      assert @crontab.comment comment
      line = @crontab.render.split('\n').last
      assert_match /^#/, line
      assert_match /#{comment}/, line
    end
  end

  test "Should be able to add a free command to the schedule" do
    assert_difference "@crontab.render.split('\n').size", +1 do
      schedule = "* * * * *"; command = "vacuumdb --all --analyze -q"
      assert @crontab.command schedule, command
      line = @crontab.render.split('\n').last
      assert_match /^#{Regexp.escape(schedule)} #{schedule}/, line
    end
  end

  test "Should be able to add several jobs to the schedule" do
    assert_difference "@crontab.render.split('\n').size", +3 do
      @crontab.rake    "@weekly", "clear"
      @crontab.runner  "@reboot", "Articles.tagify!"
      @crontab.comment "End of tasks"
    end
  end

  test "Should be able to define a crontab schedule" do
    @krontab.schedule do |cron|
      cron.rake    "@reboot", "sphinx:start"
      cron.runner  "@weekly", "Users.notify!"
      cron.command "@daily" , "vacuumdb --all --analyze -q"
    end
    crontab = @krontab.instance.render.split("\n")
    assert_equal 5, crontab.size
    assert_match /^### Start jobs for application/, crontab.shift
    assert_match /^@reboot/, crontab.shift
    assert_match /Users/, crontab.shift
    assert_match /@daily/, crontab.shift
    assert_match /^### End jobs/, crontab.shift
  end

  test "Should be able to render a crontab as a string" do
    @krontab.schedule do |cron|
      cron.rake "@reboot", "sphinx:start"
    end
    assert_respond_to @krontab.instance, :render
    assert_kind_of String, @krontab.instance.render
    assert_match /sphinx/, @krontab.instance.render
    assert_equal 3, @krontab.instance.render.split("\n").size # 2 lines of comments
  end

  test "Should be able to install a rendered crontab schedule" do
    assert_respond_to @crontab, :install!
    @crontab.expects(:system).with("crontab", anything).returns(0)
    @crontab.schedule do |cron|
      cron.rake "@reboot", "sphinx:start"
    end
    @crontab.install!
  end

  test "Should not install empty schedule" do
    @krontab.expects(:system).never
    assert_equal 0, @krontab.instance.install!
  end

end
