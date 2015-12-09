require 'mina/config/version'
require 'fileutils'
require 'yaml'
require 'mina/rvm'
require 'active_support/core_ext/hash'
require 'mina/String'
# Default the platform to rails; you can override by including other platform files
require 'mina/config/rails'


default_env = fetch(:default_env, 'staging')
config_file = 'config/deploy.yml'
set :config, YAML.load(File.open(config_file)).with_indifferent_access if File.exists? config_file
set :environment, ENV['to'] || :staging

unless config.nil?
  envs = []
  config.each {|k,v| envs << k}

  set :environments, envs
end

unless environments.nil?
  environments.each do |environment|
    desc "Set the environment to #{environment}."
    task(environment) do
      set :environment, environment
      set :branch, ENV['branch'] || config[environment]['branch']
      set :user, config[environment]['user']
      set :domain, config[environment]['domain']
      set :app, config[environment]['app']
      set :repository, config[environment]['repository']
      set :shared_paths, config[environment]['shared_paths']

      set :deploy_to, "/srv/app/#{app}"

      # Invoke platform-specific tasks based on the required mina/config/#{platform}.rb file.
      # The platform defaults to rails.
      invoke :"mina_config:platform:#{platform}:tasks"
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
