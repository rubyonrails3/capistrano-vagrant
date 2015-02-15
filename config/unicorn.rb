root = "/home/vagrant/capistrano_project/current"
worker_processes 2
working_directory "/home/vagrant/capistrano_project/current" # available in 0.94.0+
listen "/tmp/unicorn.capistrano_project.sock", :backlog => 64
listen 8080, :tcp_nopush => true
timeout 30
pid "/home/vagrant/capistrano_project/current/tmp/pids/unicorn.pid"
stderr_path "/home/vagrant/capistrano_project/current/log/unicorn.stderr.log"
stdout_path "/home/vagrant/capistrano_project/current/log/unicorn.stdout.log"

preload_app true

before_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!


  old_pid = "#{server.config[:pid]}.oldbin"
  if old_pid != server.pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end

end

after_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
  end

  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
end
