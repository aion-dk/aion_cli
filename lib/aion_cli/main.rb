require 'thor'
require 'shellwords'
require 'aion_cli/commands/avx'
require 'aion_cli/commands/dawa'
require 'aion_cli/commands/excel'
require 'aion_cli/commands/add'
require 'aion_cli/commands/table'
require 'aion_cli/commands/test_data'
require 'aion_cli/commands/text'
require 'aion_cli/commands/data'
require 'aion_cli/commands/s3'
require 'active_support/all'

module AionCLI
  class Main < Thor
    PROJECT_ROOT = File.expand_path('../..', __dir__)

    desc 'update', 'Pull the latest changes'
    def update
      Dir.chdir(PROJECT_ROOT) do
        system('git', 'pull', '--ff') && system('bundle', 'install')
      end
    end

    desc 'install', 'Install an executable at /usr/local/bin/aion'
    def install
      version_file = %x[rbenv version-file #{PROJECT_ROOT.shellescape}].chomp
      ruby_version = %x[rbenv version-file-read #{version_file}].chomp if version_file.present?
      ruby_version ||= %x[rbenv version-name].chomp

      escaped_project_root = PROJECT_ROOT.shellescape
      escaped_ruby_version = ruby_version.shellescape

      script_contents = <<~EOS
        #!/usr/bin/env bash
        set -e

        # Switch to ruby #{ruby_version}
        eval "$(rbenv init - bash)"
        rbenv shell #{escaped_ruby_version}

        # Trigger script
        exec env BUNDLE_GEMFILE=#{escaped_project_root}/Gemfile bundle exec #{escaped_project_root}/bin/aion "$@"
      EOS

      path = '/usr/local/bin/aion'

      if File.exist?(path)
        say("#{path} already exists")
        return if no?('Do you want to overwrite?')
      end

      File.write(path, script_contents)
      File.chmod(0o755, path)
      say("aion script installed into path #{path}")
    end

    method_option :ruby, type: :boolean, desc: 'Also print version of ruby used to run CLI'
    desc 'version', 'Print aion version and exit'
    def version
      say("Running ruby version is #{RUBY_VERSION}") if options[:ruby]
      say(AionCLI::VERSION)
    end


    desc 'data COMMANDS', 'Data preparation helpers'
    subcommand 'data', AionCLI::CLI::Data

    desc 'add COMMANDS', 'Data addition helpers'
    subcommand 'add', AionCLI::CLI::Add
    
    desc 'dawa COMMANDS', 'DAWA helpers'
    subcommand 'dawa', AionCLI::CLI::Dawa

    desc 'excel COMMANDS', 'Excel helpers'
    subcommand 'excel', AionCLI::CLI::Excel

    desc 'table COMMANDS', 'CSV helpers'
    subcommand 'table', AionCLI::CLI::Table

    desc 'testdata COMMANDS', 'testdata generators'
    subcommand 'testdata', AionCLI::CLI::TestData

    desc 'text COMMANDS', 'Text helpers'
    subcommand 'text', AionCLI::CLI::Text

    desc 's3 COMMANDS', 'S3 helpers via aion-s3 gem'
    subcommand 's3', AionCLI::CLI::S3

    desc 'avx COMMANDS', 'AVX helpers'
    subcommand 'avx', AionCLI::CLI::AVX
  end
end
