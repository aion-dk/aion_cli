require 'thor'
require 'aion_cli/cli/csv'

module AionCLI
  class Main < Thor

    desc 'csv COMMANDS', 'CSV Helpers'
    subcommand 'csv', AionCLI::CLI::Csv

  end
end