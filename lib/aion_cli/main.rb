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
      #version_file = %x[rbenv version-file #{PROJECT_ROOT.shellescape}].chomp
      #ruby_version = %x[rbenv version-file-read #{version_file}].chomp if version_file.present?
      #ruby_version ||= %x[rbenv version-name].chomp

      escaped_project_root = PROJECT_ROOT.shellescape
      #escaped_ruby_version = ruby_version.shellescape

      script_contents = <<~EOS
        #!/usr/bin/env bash
        set -e

        # Switch to ruby #-{ruby_version}
        #eval "$(rbenv init - bash)"
        #rbenv shell #-{escaped_ruby_version}

        # Trigger script
        exec env BUNDLE_GEMFILE=#{escaped_project_root}/Gemfile bundle exec #{escaped_project_root}/bin/aion "$@"
      EOS

      path = File.expand_path("~/.local/bin/aion")
      require 'fileutils'

      # 1. Expand the tilde into a real absolute path
      # 2. Create the directory and any missing parent directories
      FileUtils.mkdir_p(File.expand_path('~/.local/bin'))

      # Make sure .local/bin is in the path
      zshrc_path = File.expand_path('~/.zshrc')
      say("Checking for ~/.local/bin in PATH...")
      if File.exist?(zshrc_path)
        if File.read(zshrc_path).include?("\nexport PATH=\"$HOME/.local/bin:$PATH\"\n")
          say("It's there, we good")
        else
          say("adding ~/.local/bin to PATH...")
          File.open(zshrc_path, "a") do |f|
            f.write <<~NOTE
              # Added by aion_cli
              export PATH="$HOME/.local/bin:$PATH"
            NOTE
          end
        end
      else
        say(<<~NOTE)
          To be able to run the command, you need to add the following to your terminal config file:
          export PATH="$HOME/.local/bin:$PATH"
        NOTE
      end

      if File.exist?(path)
        say("#{path} already exists")
        return if no?('Do you want to overwrite?')
      end

      File.open(path, "w") do |f|
        f.write(script_contents)
      end
      File.chmod(0o755, path)
      say("aion script installed into path #{path}")
      say("if it says the command 'aion' is unrecoqnized, try restarting the terminal")
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
