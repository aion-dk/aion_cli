require 'thor'
require 'aion_cli/commands/text'
require 'aion_cli/commands/csv'
require 'aion_cli/commands/excel'
require 'aion_cli/commands/random'
require 'aion_cli/commands/test_data'
require 'aion_cli/commands/dawa'

module AionCLI
  class Main < Thor

    desc 'text COMMANDS', 'Text helpers'
    subcommand 'text', AionCLI::CLI::Text

    desc 'random COMMANDS', 'Random helpers'
    subcommand 'random', AionCLI::CLI::Random

    desc 'csv COMMANDS', 'CSV helpers'
    subcommand 'csv', AionCLI::CLI::Csv

    desc 'excel COMMANDS', 'excel helpers'
    subcommand 'excel', AionCLI::CLI::Excel

    desc 'testdata COMMANDS', 'testdata generators'
    subcommand 'testdata', AionCLI::CLI::TestData

    desc 'dawa COMMANDS', 'DAWA helpers'
    subcommand 'dawa', AionCLI::CLI::Dawa

  end
end