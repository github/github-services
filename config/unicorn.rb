base = "#{File.dirname(__FILE__)}/../"
preload_app true

worker_processes ENV['UNICORN_WORKERS'] ? ENV['UNICORN_WORKERS'].to_i : 1
timeout ENV['UNICORN_TIMEOUT'] ? ENV['UNICORN_TIMEOUT'].to_i : 15
listen ENV['UNICORN_LISTEN'] ? ENV['UNICORN_LISTEN'] : '0.0.0.0:4000'

stderr_path "#{base}/log/unicorn.stderr.log"
stderr_path "#{base}/log/unicorn.stderr.log"
pid "#{base}/tmp/pids/unicorn.pid"

##
# Signal handling

# Called in the master before forking each worker process.
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

  # wait until last worker boots to send QUIT signal
  next if worker.nr != (server.worker_processes - 1)

  if File.exists?("#{pidfile}.oldbin") && server.pid != "#{pidfile}.oldbin"
    begin
      Process.kill("QUIT", File.read("#{pidfile}.oldbin").to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end