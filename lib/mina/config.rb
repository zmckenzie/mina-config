require 'mina/config/version'
require 'fileutils'
require 'yaml'
require 'mina/rvm'
require 'active_support/core_ext/hash'
require 'mina/String'


default_env = fetch(:default_env, 'staging')
config_file = 'config/deploy.yml'
ruby_version_file = '.ruby-version'
set :config, YAML.load(File.open(config_file)).with_indifferent_access if File.exists? config_file
set :rails_env, ENV['to'] || :staging

unless config.nil?
  envs = []
  config.each {|k,v| envs << k}

  set :environments, envs
end

unless environments.nil?
  environments.each do |environment|
    desc "Set the environment to #{environment}."
    task(environment) do
      set :rails_env, environment
      set :branch, ENV['branch'] || config[rails_env]['branch']
      set :user, config[rails_env]['user']
      set :domain, config[rails_env]['domain']
      set :app, config[rails_env]['app']
      set :repository, config[rails_env]['repository']
      set :shared_paths, config[rails_env]['shared_paths']
      set :start_sidekiq, config[rails_env]['start_sidekiq'] if config[rails_env]['start_sidekiq']
      set :start_rpush, config[rails_env]['start_rpush']if config[rails_env]['start_rpush']

      set :deploy_to, "/srv/app/#{app}"

      if File.exists?(ruby_version_file)
        set :ruby_version, File.read(ruby_version_file).strip
        invoke :"rvm:use[#{ruby_version}]"
      end
    end
  end

  unless environments.include?(ARGV.first)
    invoke default_env
  end
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

      app_params.each do |k,v|
        if(k != :common)
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
