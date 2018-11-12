require 'thor'
require 'aion_cli/commands/dawa'
require 'aion_cli/commands/excel'
require 'aion_cli/commands/random'
require 'aion_cli/commands/table'
require 'aion_cli/commands/test_data'
require 'aion_cli/commands/text'
require 'active_support/all'

module AionCLI
  class Main < Thor

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

  end
end