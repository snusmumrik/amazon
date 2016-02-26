# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'a.crudoe.com'
set :repo_url, 'git@github.com:snusmumrik/amazon.git'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, '/var/www/my_app_name'
set :deploy_to, '/var/www'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')

# Default value for linked_dirs is []
# set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :deploy do
  desc "deploy #{fetch :application}"
  task :deploy do
    on roles(:web) do
      application = fetch :application
      deploy_to = fetch :deploy_to

      # execute "sudo chown deploy:deploy #{deploy_to}"

      if test "[ -d #{deploy_to}/#{application} ]"
        execute "cd #{deploy_to}/#{application}; git pull;"
      else
        execute "cd #{deploy_to}; git clone #{fetch :repo_url} #{application}; cd #{application};"
      end
    end
  end

  after :deploy, :migrate do
    deploy.migrate
  end

  after :deploy, :compile_assets do
    deploy.cleanup_assets
    deploy.compile_assets
    deploy.restart
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end
