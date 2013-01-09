base = "#{File.dirname(__FILE__)}/../"
worker_processes ENV['UNICORN_WORKERS'] ? ENV['UNICORN_WORKERS'].to_i : 1
timeout ENV['UNICORN_TIMEOUT'] ? ENV['UNICORN_TIMEOUT'].to_i : 15

# create log and tmp directories
%w[tmp tmp/sockets tmp/pids log].each do |dir|
  Dir.mkdir "#{base}/#{dir}" unless File.directory?("#{base}/#{dir}")
end

# if ENV['GH_APP']
  preload_app true
  # listen "#{base}/tmp/sockets/unicorn.sock"
  listen '0.0.0.0:4000'
  stderr_path "#{base}/log/unicorn.stderr.log"
  stderr_path "#{base}/log/unicorn.stderr.log"
  pid "#{base}/tmp/pids/unicorn.pid"
# end

before_fork do |server, worker|
  ##
  # When sent a USR2, Unicorn will suffix its pidfile with .oldbin and
  # immediately start loading up a new version of itself (loaded with a new
  # version of our app). When this new Unicorn is completely loaded
  # it will begin spawning workers. The first worker spawned will check to
  # see if an .oldbin pidfile exists. If so, this means we've just booted up
  # a new Unicorn and need to tell the old one that it can now die. To do so
  # we send it a QUIT.
  #
  # Using this method we get 0 downtime deploys.

  if ENV['GH_APP']
    old_pid = "#{base}/tmp/pids/unicorn.pid.oldbin"
    if File.exists?(old_pid) && server.pid != old_pid
      begin
        Process.kill("QUIT", File.read(old_pid).to_i)
      rescue Errno::ENOENT, Errno::ESRCH
        # someone else did our job for us
      end
    end
  end
end
