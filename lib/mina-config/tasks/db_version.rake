require 'rake'

namespace :mina do
  namespace :db do
    desc 'Print the current database migration version number'
    task :version => :environment do
      puts ActiveRecord::Migrator.current_version
    end
  end
end
