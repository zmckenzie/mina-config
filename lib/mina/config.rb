require 'mina/config/version'
require 'fileutils'
require 'yaml'
require 'mina/rvm'
require 'active_support/core_ext/hash'
require 'mina/String'
require 'open4'
require 'open3'
require 'pry'

default_env = fetch(:default_env, 'staging')
config_file = 'config/deploy.yml'
ruby_version_file = '.ruby-version'
if File.exists? config_file
  config = YAML.load(File.open(config_file)).with_indifferent_access 
  set :config, config
end
set :rails_env, ENV['to'] || :staging

unless config.nil?
  environments = []
  config.each { |k, v| environments << k }

  set :environments, environments
end

unless environments.nil?
  environments.each do |environment|
    desc "Set the environment to #{environment}."
    task(environment) do
      set :rails_env, environment
      set :branch, ENV['branch'] || config[environment]['branch']
      set :user, config[environment]['user']
      set :domain, config[environment]['domain']
      set :app, config[environment]['app']
      set :repository, config[environment]['repository']
      set :shared_paths, config[environment]['shared_paths']
      set :start_sidekiq, config[environment]['start_sidekiq'] if config[environment]['start_sidekiq']
      set :start_rpush, config[environment]['start_rpush']if config[environment]['start_rpush']

      set :deploy_to, "/srv/app/#{fetch(:app)}"

      if File.exists?(ruby_version_file)
        set :ruby_version, File.read(ruby_version_file).strip
        invoke :"rvm:use[#{fetch(:ruby_version)}]"
      end
    end
  end

  if !environments.include?(ARGV.first) && environments.include?(default_env)
    invoke default_env
  end
end


def setup_environment rails_env

  set :rails_env, rails_env

  set :branch, ENV['branch'] || config[rails_env]['branch']
  set :user, config[rails_env]['user']
  set :domain, config[rails_env]['domain']
  set :app, config[rails_env]['app']
  set :repository, config[rails_env]['repository']
  set :shared_paths, config[rails_env]['shared_paths']
  set :deploy_to, "/srv/app/#{app}"
  set :ruby_version, File.read('.ruby-version')
  set :port, config[rails_env]['port'] || '22'
  
  set :keep_releases, config[rails_env]['keep_releases'] if config[rails_env].has_key? 'keep_releases'
  set :start_sidekiq, config[rails_env]['start_sidekiq'] if config[rails_env].has_key? 'start_sidekiq'
  set :start_rpush, config[rails_env]['start_rpush'] if config[rails_env].has_key? 'start_rpush'

  if config[rails_env].has_key? 'env'
    set :rails_env, config[rails_env]['env']
  else
    set :rails_env, rails_env
  end

  invoke :"rvm:use[#{fetch(:ruby_version)}]"
end

namespace :config do
  desc 'Create deploy config file'
  task :init do
    if File.exists?(config_file).blank?
      app_params = {}
      puts "What is your app name?"
      app_params.store(:common, {})
      app_params[:common][:app_name] = STDIN.gets.chomp
      puts "What is the ssh url for the repository?"
      app_params[:common][:repo] = STDIN.gets.chomp
      %w{staging production}.each do |stage|
        app_params.store("#{stage}".to_sym, {})
        puts "----------#{stage} Configuration----------"
        puts "What is the domain for #{stage}?"
        app_params["#{stage}".to_sym][:domain] = STDIN.gets.chomp
        puts "What is the user for #{stage}?"
        app_params["#{stage}".to_sym][:user] = STDIN.gets.chomp
        puts "What is the branch for #{stage}?"
        app_params["#{stage}".to_sym][:branch] = STDIN.gets.chomp
      end

      deploy_yml = "
          common: &common
                app: #{app_params[:common][:app_name]}
                repository: #{app_params[:common][:repo]}
                shared_paths: 
                  - 'config/database.yml'
                  - 'log'"

      app_params.each do |k, v|
        if (k != :common)
          deploy_yml += "
          #{k}:
                <<: *common
                domain: #{app_params[k][:domain]}
                user: #{app_params[k][:user]}
                branch: #{app_params[k][:branch]}"
        end
      end

      File.open(config_file, 'w') do |f|
        f.puts deploy_yml.dedent
      end
    end
  end
end

namespace :deploy do
  desc 'deploy to a cluster of servers'
  task :cluster do
    config[cluster_key].each do |env|
      if environments.include? env
        puts %[Called Deployment for #{env}.]
        Open3.popen3("mina #{env} deploy") do |stdin, stdout, stderr, thread|
          { :out => stdout, :err => stderr }.each do |key, stream|
            Thread.new do
              until (raw_line = stream.gets).nil? do
                puts raw_line
              end
            end
          end

          thread.join
        end
      else
        puts %[Environment #{env} not found. Please define it in your deploy.yml.]
        exit 1
      end
    end
  end

  desc "Rolls back the latest release"
  task :rollback => :environment do
    comment %[echo "-----> Rolling back to previous release for instance: #{domain}"]

    # Delete existing sym link and create a new symlink pointing to the previous release
    comment %[echo -n "-----> Creating new symlink from the previous release: "]
    command %[ls "#{deploy_to}/releases" -Art | sort | tail -n 2 | head -n 1]
    command %[ls -Art "#{deploy_to}/releases" | sort | tail -n 2 | head -n 1 | xargs -I active ln -nfs "#{deploy_to}/releases/active" "#{deploy_to}/current"]

    # Remove latest release folder (active release)
    comment %[echo -n "-----> Deleting active release: "]
    command %[ls "#{deploy_to}/releases" -Art | sort | tail -n 1]
    command %[ls "#{deploy_to}/releases" -Art | sort | tail -n 1 | xargs -I active rm -rf "#{deploy_to}/releases/active"]
  end
end
namespace :database do
  
  task :set_version => :environment do
    command "cd #{deploy_to}/#{current_path}"
    command "#{rails} r 'puts ActiveRecord::Migrator.current_version' > #{deploy_to}/#{current_path}/migration_version.txt"
  end
  
  task :rollback => :environment do
    command "cd #{deploy_to}/#{current_path}"
    command "#{rake} db:migrate VERSION=`cat migration_version.txt`"
  end
end
