require 'thor'
require 'aion_cli/commands/dawa'
require 'aion_cli/commands/excel'
require 'aion_cli/commands/random'
require 'aion_cli/commands/table'
require 'aion_cli/commands/test_data'
require 'aion_cli/commands/text'
require 'aion_cli/commands/validate'
require 'aion_cli/commands/prepare'
require 'active_support/all'

module AionCLI
  class Main < Thor

    desc 'update', 'Pull the latest changes'
    def update
      project_root = File.expand_path(File.join(__FILE__, '../../../'))
      system("cd #{project_root} && git pull --ff && bundle install")
    end

    desc 'install', 'Install an executable at /usr/local/bin/aion'
    def install
      project_root = File.expand_path(File.join(__FILE__, '../../../'))

      version_file = %x[rbenv version-file #{project_root}].chomp
      ruby_version = %x[rbenv version-file-read #{version_file}].chomp if version_file.present?
      ruby_version ||= %x[rbenv version-name].chomp

      script_contents = <<-EOS.gsub(/^\s{8}/,'')
        #!/usr/bin/env bash

        # Switch to ruby #{ruby_version}
        eval "$(rbenv init -)"
        rbenv shell #{ruby_version}

        # Trigger script
        BUNDLE_GEMFILE=#{project_root}/Gemfile bundle exec #{project_root}/bin/aion "$@"
      EOS

      path = '/usr/local/bin/aion'

      if File.exists?(path)
        say("#{path} already exists")
        return if no?('Do you want to overwrite?')
      end

      File.write(path, script_contents)
      File.chmod(0755, path)
      say("aion script installed into path #{path}")
    end

    desc 'version', 'Print aion version and exit'
    def version
      say(AionCLI::VERSION)
    end

    desc 'dawa COMMANDS', 'DAWA helpers'
    subcommand 'dawa', AionCLI::CLI::Dawa

    desc 'excel COMMANDS', 'excel helpers'
    subcommand 'excel', AionCLI::CLI::Excel

    desc 'random COMMANDS', 'Random helpers'
    subcommand 'random', AionCLI::CLI::Random

    desc 'table COMMANDS', 'CSV helpers'
    subcommand 'table', AionCLI::CLI::Table

    desc 'testdata COMMANDS', 'testdata generators'
    subcommand 'testdata', AionCLI::CLI::TestData

    desc 'text COMMANDS', 'Text helpers'
    subcommand 'text', AionCLI::CLI::Text

    desc 'validate COMMANDS', 'Validation helpers'
    subcommand 'validate', AionCLI::CLI::Validate

    desc 'prepare COMMANDS', 'Preparation helpers'
    subcommand 'prepare', AionCLI::CLI::Prepare

  end
end