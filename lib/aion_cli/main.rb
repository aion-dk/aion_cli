require 'thor'
require 'aion_cli/commands/csv'
require 'aion_cli/commands/excel'

module AionCLI
  class Main < Thor

    desc 'csv COMMANDS', 'CSV Helpers'
    subcommand 'csv', AionCLI::CLI::Csv

    desc 'excel COMMANDS', 'excel Helpers'
    subcommand 'excel', AionCLI::CLI::Excel

  end
end