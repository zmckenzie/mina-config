# Mina::Config

Adds a multi-environment yml configuration file to mina. Environment configuration is dynamically created by the definitions in the deploy.yml file.

As of right now the gem does require you to use rvm and have a .ruby-version file if you are doing a Ruby deployment.

## Installation

Add this line to your application's Gemfile:

    gem 'mina-config', require: false

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mina-config

## Usage

Require `mina/config` in `config/deploy.rb`:

```rb
require 'mina/config'
require 'mina/bundler'
require 'mina/rails'
require 'mina/git'

...

task setup: :environment do
  ...
end

desc 'Deploys the current version to the server.'
task deploy: :environment do
  ...
end
```

At the moment the gem requires usage of rvm. Add the following to `config/deploy.rb` with the path to your rvm install:
```rb
set :rvm_path, '/usr/local/rvm/scripts/rvm'
```

Then run the config initializer:

```shell
$ mina config:init
```

It will create `config/deploy.yml`.
Use this file to define stage-specific configuration.

```yml
common: &common
      app: Mina_config
      repository: git@github.com:zmckenzie/mina-config.git
      shared_paths: ['config/database.yml', 'log']
staging:
      <<: *common
      domain: staging.example.com
      user: example
      branch: staging
```

Now deploy `staging` with:

```shell
$ mina deploy
```

Or specify a stage explicitly:

```shell
$ mina staging deploy
$ mina production deploy
```

## Contributing

1. Fork it ( http://github.com/zmckenzie/mina-config/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
