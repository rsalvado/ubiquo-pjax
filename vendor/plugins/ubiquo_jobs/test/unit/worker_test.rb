require File.dirname(__FILE__) + "/../test_helper.rb"
require 'mocha'

class UbiquoWorker::WorkerTest < ActiveSupport::TestCase

  def test_should_build_worker
    UbiquoWorker::Worker.expects(:new)
    start_worker rescue nil
  end

  def test_should_not_build_worker_without_name
    assert_raise ArgumentError do
      start_worker(:name => '')
    end
  end

  def test_should_set_sleep_time
    UbiquoWorker::Worker.any_instance.expects(:sleep_time=).with(10.0)
    start_worker :worker_options => {:sleep_time => 10.0}, :iterations => 1
  end

  def test_should_set_sleep_interval
    UbiquoWorker::Worker.any_instance.expects(:sleep_interval=).with(4.0)
    start_worker :worker_options => {:sleep_interval => 4.0}, :iterations => 1
  end

  def test_should_get_tasks
    UbiquoJobs.manager.expects(:get).with('new_worker')
    start_worker :iterations => 2
  end

  def test_should_create_and_cleanup_pid_file
    UbiquoWorker::Worker.any_instance.expects(:store_pid)
    UbiquoWorker::Worker.any_instance.expects(:cleanup_pid_file)
    start_worker :iterations => 1
  end

  def test_should_set_pid_file_path
    pid_file = Tempfile.new('pid')
    pid_file_path = pid_file.path
    pid_file.unlink
    File.expects(:open).with(pid_file_path, 'w')
    start_worker :iterations =>1, :worker_options => { :pid_file_path => pid_file_path }
  end

  def test_should_abort_with_existing_pid_file_and_invalid_contents
    assert_raise SystemExit do
      pid_file = Tempfile.new('pid')
      pid_file_path = pid_file.path
      start_raw_worker :test, { :pid_file_path => pid_file_path }
    end
  end

  def test_should_abort_with_existing_pid_file_and_running_process
    assert_raise SystemExit do
      pid_file = Tempfile.new('pid')
      pid_file_path = pid_file.path
      pid_file.write(Process.pid)
      pid_file.flush
      start_raw_worker :test, { :pid_file_path => pid_file_path }
    end
  end

  def test_should_start_worker_with_existing_pid_file_and_no_running_process
    pid_file = Tempfile.new('pid')
    pid_file_path = pid_file.path
    pid_file.write('6666666') #FIXME: This should be an inexistent pid
    pid_file.flush
    UbiquoWorker::Worker.any_instance.expects(:store_pid)
    start_worker :worker_options => {:pid_file_path => pid_file_path}, :iterations => 1
  end

  def test_should_abort_with_existing_pid_file_and_pid_with_permissions_to_be_queried
    assert_raise SystemExit do
      pid_file = Tempfile.new('pid')
      pid_file_path = pid_file.path
      pid_file.write("1")
      pid_file.flush
      start_raw_worker :test, { :pid_file_path => pid_file_path }
    end
  end

  def test_should_trap_term_signal
    Signal.expects(:trap).with("TERM")
    start_worker :iterations => 1
  end

  private

  def create_task(options = {})
    default_options = {
      :command => 'ls',
      :planified_at => Time.now.utc,
    }
    Task.create(default_options.merge(options))
  end

  def start_worker(options = {})
    sleep_interval = 1
    options = {
      :name => 'new_worker',
      :iterations => 0,
      :worker_options => {}
    }.merge(options)

    options[:worker_options][:sleep_time] ||= 5.0
    options[:worker_options][:sleep_interval] ||= options[:worker_options][:sleep_time]

    shutdown_values = ([false]*(options[:iterations] > 1 ? options[:iterations]-1 : 0)) << true

    sleep_invoked_times = options[:worker_options][:sleep_time]/options[:worker_options][:sleep_interval]
    UbiquoWorker::Worker.any_instance.expects(:sleep).times(0..sleep_invoked_times).returns(nil)
    UbiquoWorker::Worker.any_instance.expects(:shutdown).at_least(options[:iterations]).returns(*shutdown_values)

    start_raw_worker(options[:name], options[:worker_options])
  end

  def start_raw_worker(name, options)
    orig_stdout = $stdout
    $stdout = File.new('/dev/null', 'w')
    UbiquoWorker.init(name, options)
    $stdout = orig_stdout
  end

end
