# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, 'capistrano_project'
set :repo_url, 'git@github.com:rubyonrails3/capistrano-vagrant.git'
set :user, 'vagrant'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
set :deploy_to, "/home/#{fetch(:user)}/#{fetch(:application)}"

# Default value for :scm is :git
set :scm, :git

# Default value for :format is :pretty
set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
set :pty, true

# Default value for :linked_files is []
set :linked_files, %w{config/database.yml config/secrets.yml}

# Default value for linked_dirs is []
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 5


desc 'Check if agent forwarding is working'
task :forwarding do
  on roles(:all) do |host|
    if test("env | grep SSH_AUTH_SOCK")
      info "Agent forwarding is up to #{host}"
    else
      error "Agent forwarding is NOT up to #{host}"
    end
  end
end

namespace :deploy do

  %w[start stop restart reload upgrade].each do |command|
    desc "#{command} unicorn server"
    task command do
      on roles(:app) do |host|
        execute "/etc/init.d/unicorn_#{fetch(:application)} #{command}"
        info "excuted command: #{command}"
      end
    end
  end

  desc "symlinks web and app server configuration"
  task :setup_config do
    on roles(:app, :web) do |host|
      execute "sudo ln -nfs #{current_path}/config/nginx.conf /etc/nginx/sites-enabled/#{fetch(:application)}"
      execute "sudo ln -nfs #{current_path}/config/unicorn_init.sh /etc/init.d/unicorn_#{fetch(:application)}"
    end
  end

  after :publishing, :restart
  before :check, :setup_config
end
