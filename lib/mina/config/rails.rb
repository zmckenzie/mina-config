

# Rails deployment tasks
set :platform, :rails
namespace :mina_config do
  namespace :platform do
    namespace :rails do
      task :tasks do
        set :ruby_version, File.read('.ruby-version')

        desc "Setting rvm to use ruby version #{ruby_version}"
        invoke :"rvm:use[#{ruby_version.chomp}]"
      end
    end
  end
end
