require 'thor'
require 'aion_cli/commands/csv'

module AionCLI
  class Main < Thor

    desc 'csv COMMANDS', 'CSV Helpers'
    subcommand 'csv', AionCLI::CLI::Csv

  end
end