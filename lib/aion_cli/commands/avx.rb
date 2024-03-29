require 'crypto/crypto'
require 'aion_cli/helpers/application_helper'

module AionCLI
  module CLI
    class AVX < Thor
      include AionCLI::ApplicationHelper

      desc 'credentials_print n', 'Generate and print n pair of election codes - public keys'
      def credentials_print(n)
        credential_pairs = generate_credential_pairs(n.to_i)

        credential_pairs.each do |election_code, public_key|
          say("#{election_code}\t#{public_key}")
        end
      end

      desc 'credentials_generate PATH', 'Generate election codes and public keys for each identifier in the file'
      def credentials_generate(path)
        headers, *rows = read_csv(path)

        credential_pairs = generate_credential_pairs(rows.size)

        # generate election codes file
        rows_plus_election_codes = rows.zip(credential_pairs.keys).map{ |row, election_code| row + [election_code] }
        headers_plus_election_code = headers + ['Election code']

        ec_absolute_path = ask_output_path('.csv', 'election_codes', 'Pick a name for the election codes file')
        output(ec_absolute_path) do |csv|
          csv << headers_plus_election_code
          rows_plus_election_codes.each{ |row| csv << row }
        end


        # generate public keys file
        rows_plus_public_keys = rows.zip(credential_pairs.values).map{ |row, public_key| row + [public_key] }
        headers_plus_public_key = headers + ['Public key']

        pk_absolute_path = ask_output_path('.csv', 'public_keys', 'Pick a name for the public keys file')
        output(pk_absolute_path) do |csv|
          csv << headers_plus_public_key
          rows_plus_public_keys.each{ |row| csv << row }
        end

        say("Done! Outputted files:\n#{ec_absolute_path}\n#{pk_absolute_path}")
      end

      desc 'credentials_compute PATH', 'Compute public keys for each identifier in the file, using as election codes a specific column'
      def credentials_compute(path)
        headers, *rows = read_csv(path)

        election_codes = []
        loop do
          index = ask_header_index(headers, 'What column to use as election codes?')
          column = rows.map{ |row| row[index] }

          # Error if there are empty values
          if column.any?(&:blank?)
            say("The column '#{headers[index]}' contains blank values. Please select another column!", :red)
            next
          end

          # Warn if there are duplicates
          unless column.size == column.uniq.size
            unless yes?("The column '#{headers[index]}' contains doublet values. Do you wish to continue?", :yellow)
              next
            end
          end

          # Warn if there are insecure (weak) election codes
          if column.any?{ |v| v.length < 14 }
            unless yes?("The column '#{headers[index]}' contains insecure values. Do you wish to continue?", :yellow)
              next
            end
          end

          election_codes = column
          break
        end

        public_keys = election_codes.map{ |ec| Crypto.election_code_to_public_key(ec) }

        # generate public keys file
        rows_plus_public_keys = rows.zip(public_keys).map{ |row, public_key| row + [public_key] }
        headers_plus_public_key = headers + ['Public key']

        pk_absolute_path = ask_output_path('.csv', 'public_keys', 'Pick a name for the public keys file')
        output(pk_absolute_path) do |csv|
          csv << headers_plus_public_key
          rows_plus_public_keys.each{ |row| csv << row }
        end

        say("Done! Outputted file:\n#{pk_absolute_path}")
      end

      desc 'credentials_aggregate FILE_PATHS', 'Group all public key files into one'
      def credentials_aggregate(*paths)
        public_keys = {}

        paths_first, *paths_rest = paths
        file_headers, *file_rows = read_csv(paths_first)

        index = ask_header_index(file_headers, 'What is the identifier column?')

        file_rows.each do |row|
          id = row[index]
          public_keys[id] = row.last
        end


        paths_rest.each do |path|
          headers, *rows = read_csv(path)

          rows.each do |row|
            id = row[index]
            public_key = row.last

            unless public_keys.key?(id)
              raise Thor::Error, 'Files are not consistent. Identifier column does not match across files'
            end

            public_keys[id] = Crypto.combine_public_keys(public_keys[id], public_key)
          end
        end


        file_rows.zip(public_keys.values).map do |row, public_key|
          # replace the old public key with the new computed one
          row[row.size - 1] = public_key
        end

        # Generate csv file
        ask_output do |csv|
          csv << file_headers
          file_rows.each{ |row| csv << row }
        end
      end

      desc 'one_quick', 'Computes one public key based on a given number of factors'
      def one_quick

        n = ask_natural_number("How many election codes?")

        election_codes = (1..n).map do |x|
          ask("Election code #{x}:")
        end

        public_keys = election_codes.map{ |ec| Crypto.election_code_to_public_key(ec) }

        public_keys.each_with_index do |pk,i|
          say("Public key #{i+1}: #{pk}")
        end

        aggregated_public_key = public_keys.inject { |out,pk| Crypto.combine_public_keys(out, pk) }
        say("Aggregated public key: #{aggregated_public_key}")
      end

      private

      def generate_credential_pairs(n)
        credential_pairs = {}

        n.times do
          # generate unique codes
          begin
            election_code, public_key = Crypto.generate_credential_pair
          end while credential_pairs.key?(election_code)

          credential_pairs[election_code] = public_key
        end

        credential_pairs
      end
    end
  end
end
