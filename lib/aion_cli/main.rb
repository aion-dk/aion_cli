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
    def self.exit_on_failure?
      true
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
