require 'mina/rails'
require 'mina/git'
require 'mina/rvm'
require 'mina_sidekiq/tasks'
require 'fileutils'

FileUtils.mkdir_p "#{Dir.pwd}/deploy"

set :ssh_options, '-o StrictHostKeyChecking=no'

set :domain, 'localhost'
set :deploy_to, "#{Dir.pwd}/deploy"
set :repository, 'https://github.com/Mic92/mina-sidekiq-test-rails.git'
set :keep_releases, 2
set :sidekiq_processes, 2

set :shared_dirs, fetch(:shared_dirs, []).push('log')

task :environment do
  # this line is disabled because of a bug in mina 1.0.0
  # invoke :'rvm:use', ENV.fetch('RUBY_VERSION', 'ruby-2.3.1')
  env = ENV.fetch('RUBY_VERSION', 'ruby-2.3.1')
  command %{source #{fetch(:rvm_use_path)}}
  command %{rvm use "#{env}" --create}
end

task setup: :environment do
  command %(mkdir -p "#{fetch(:deploy_to)}/shared/pids/")
  command %(mkdir -p "#{fetch(:deploy_to)}/shared/log/")
end

task :deploy do
  deploy do
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'

    on :launch do
      invoke :'sidekiq:start'
      command %(sleep 3; kill -0 `cat #{fetch(:sidekiq_pid)}`)

      invoke :'sidekiq:quiet'

      invoke :'sidekiq:stop'
      command %((kill -0 `cat #{fetch(:sidekiq_pid)}`) 2> /dev/null && exit 1 || exit 0)
    end
  end
end
