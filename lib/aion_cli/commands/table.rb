require 'aion_cli/helpers/application_helper'

module AionCLI
  module CLI
    class Table < Thor
      include AionCLI::ApplicationHelper

      desc 'uniform CSV_FILE', 'Convert to semi-colon separated UTF-8 csv file'
      def uniform(path)
        rows = read_spreadsheet(path)

        # Generate csv file
        ask_output do |csv|
          rows.each do |row|
            csv << row
          end
        end
      end

      desc 'slice CSV_FILE', 'Filter columns for csv file'
      def slice(path)

        rows = read_spreadsheet(path)
        indexes = ask_header_indexes(rows.first, 'Pick the columns to keep')

        ask_output do |csv|
          rows.each do |row|
            csv << row.values_at(*indexes)
          end
        end
      end

      desc 'pivot CSV_FILE', 'Count votes with weights'
      def pivot(path)
        headers, *rows = read_spreadsheet(path)

        group_by_indexes = ask_header_indexes(headers, 'Pick columns to group by')
        sum_index = ask_header_index(headers, 'Pick a column to sum up')

        result = Hash.new(0)
        rows.each do |row|
          key = row.values_at(*group_by_indexes)

          sum_value = row[sum_index]
          raise Thor::Error, 'Non num value in sum' unless sum_value =~ /^\d+$/

          result[key] += sum_value.to_i
        end

        ask_output do |csv|
          new_headers = headers.values_at(*group_by_indexes)
          new_headers << 'sum of votes'

          csv << new_headers

          result.each do |key, sum|
            csv << key + [sum]
          end
        end

      end

      desc 'sort CSV_FILE', 'Sorts a CSV file given a list of indexes'
      def sort(path)
        headers, *rows = read_spreadsheet(path)

        sort_by_indexes = ask_header_indexes_for_sort(headers, 'Pick the sort order')

        new_rows = rows.sort { |a,b|
          sort_by_indexes.inject(0) { |m,(reverse,index)|

            next m if m != 0

            a_value = a[index]
            b_value = b[index]

            # Convert to numbers
            if a_value =~ /^\s*-?\d+\s*$/ and b_value =~ /^\s*-?\d+\s*$/
              a_value = a_value.to_i
              b_value = b_value.to_i
            end

            next b_value <=> a_value if reverse

            a_value <=> b_value
          }
        }

        ask_output do |csv|
          csv << headers

          new_rows.each do |row|
            csv << row
          end
        end
      end


      desc 'join MAIN_FILE ADDITIONAL_FILE', 'Adds the columns of ADDITIONAL_FILE by joining where a value match is found'
      def join(path_a, path_b)
        headers_a, *rows_a = read_spreadsheet(path_a)
        headers_b, *rows_b = read_spreadsheet(path_b)

        join_index_a = ask_header_index(headers_a, 'Pick a join column for MAIN_FILE')
        join_index_b = ask_header_index(headers_b, 'Pick a join column for ADDITIONAL_FILE')

        # Build search index
        join_b_hash = {}
        allow_empty = nil
        rows_b.each do |values|
          key = values[join_index_b]

          if key.blank?
            allow_empty ||= yes?('Empty value in join column for ADDITIONAL_FILE. Would you like to continue anyway?')
            raise Thor::Error, 'Empty value in join column for ADDITIONAL_FILE' unless allow_empty
            next
          end

          raise Thor::Error, "Duplicate keys in join column for ADDITIONAL_FILE (key: #{key})" if join_b_hash.has_key?(key)
          join_b_hash[key] = values
        end

        count_key_blank = 0
        count_match = 0
        count_no_match = 0

        # Generate csv file
        ask_output do |csv|

          csv << headers_a + headers_b

          rows_a.each do |values_a|
            join_value = values_a[join_index_a]

            unless join_value.present?
              count_key_blank += 1
            end

            if join_b_hash.key?(join_value)
              count_match += 1
            else
              count_no_match += 1
            end

            values_b = join_b_hash[join_value] || [nil] * headers_b.size

            csv << values_a + values_b
          end

        end

        say
        say "count_match    : #{count_match}"
        say "count_no_match : #{count_no_match}"
        say "count_key_blank    : #{count_key_blank}"
      end


      desc 'vlookup MAIN_FILE ADDITIONAL_FILE', 'Enriches the MAIN_FILE with a lookup column from ADDITIONAL_FILE where values match in join columns'
      def vlookup(path_a, path_b)
        headers_a, *rows_a = read_spreadsheet(path_a)
        headers_b, *rows_b = read_spreadsheet(path_b)

        join_count = ask_natural_number('How many join columns?')

        join_indices_a = []; join_indices_b = []
        (1..join_count).each do |i|
          join_indices_a << ask_header_index(headers_a, "Pick #{i.ordinalize} join column for MAIN_FILE")
          join_indices_b << ask_header_index(headers_b, "Pick #{i.ordinalize} join column for ADDITIONAL_FILE")
        end

        lookup_index_b = ask_header_index(headers_b, "Pick lookup column from ADDITIONAL_FILE")

        # Build search index
        join_b_hash = {}
        allow_empty = nil
        rows_b.each do |row|
          key = row.values_at(*join_indices_b)

          if key.any?(&:blank?)
            allow_empty ||= yes?('Empty value in join column for ADDITIONAL_FILE. Would you like to continue anyway?')
            raise Thor::Error, 'Empty value in join column for ADDITIONAL_FILE' unless allow_empty
          end

          raise Thor::Error, "Duplicate key combination in join columns for ADDITIONAL_FILE (key: #{key})" if join_b_hash.has_key?(key)

          join_b_hash[key] = row[lookup_index_b]
        end

        count_match = 0
        count_defaults = 0

        # Generate csv file
        default_value = nil
        ask_output do |csv|

          csv << headers_a + [headers_b[lookup_index_b]]

          rows_a.each do |row|
            join_value = row.values_at(*join_indices_a)

            if join_b_hash.key?(join_value)
              count_match += 1
              lookup_value = join_b_hash[join_value]
            else
              default_value ||= begin
                                  if yes?('No join key combination was found in ADDITIONAL_FILE. Would you like to set a default value?')
                                    ask('Default value:')
                                  end
                                end
              raise Thor::Error, "No match key combination in join columns for ADDITIONAL_FILE (key: #{join_value})" if default_value.nil?

              count_defaults += 1
              lookup_value = default_value
            end

            csv << row + [lookup_value]
          end

        end

        say
        say "count_match    : #{count_match}"
        say "count_defaults : #{count_defaults}"
      end


      desc 'select MAIN_FILE ADDITIONAL_FILE', 'Select rows from MAIN_FILE where a value is also found in ADDITIONAL_FILE'
      def select(path_a, path_b)

        headers_main, *rows_main = read_spreadsheet(path_a)
        headers_dict, *rows_dict = read_spreadsheet(path_b)

        join_index_main = ask_header_index(headers_main, 'Pick a match column for MAIN_FILE')
        join_index_dict = ask_header_index(headers_dict, 'Pick a match column for ADDITIONAL_FILE')

        # Build search index
        dict = Hash.new { |h,k| h[k] = [] }
        rows_dict.each.with_index(2) do |row, line_number|
          key = row[join_index_dict]
          if key.blank?
            error('Empty value found in match column for ADDITIONAL_FILE')
          else
            dict[key] << line_number
          end
        end

        # Warn about doublets
        dict.each do |key, line_numbers|
          error("'#{key}' found in multiple lines (#{line_numbers.join(',')}") if line_numbers.size > 1
        end

        # Generate csv file
        ask_output do |csv|
          csv << headers_main
          rows_main.each do |row|
            key = row[join_index_main]
            csv << row if dict.key?(key)
          end
        end
      end

      desc 'reject MAIN_FILE ADDITIONAL_FILE', 'Select rows from MAIN_FILE where a value is not found in ADDITIONAL_FILE'
      def reject(path_a, path_b)

        headers_main, *rows_main = read_spreadsheet(path_a)
        headers_dict, *rows_dict = read_spreadsheet(path_b)

        join_index_main = ask_header_index(headers_main, 'Pick a match column for MAIN_FILE')
        join_index_dict = ask_header_index(headers_dict, 'Pick a match column for ADDITIONAL_FILE')

        # Build search index
        dict = Hash.new { |h,k| h[k] = [] }
        rows_dict.each.with_index(2) do |row, line_number|
          key = row[join_index_dict]
          if key.blank?
            error('Empty value found in match column for ADDITIONAL_FILE')
          else
            dict[key] << line_number
          end
        end

        # Warn about doublets
        dict.each do |key, line_numbers|
          error("'#{key}' found in multiple lines (#{line_numbers.join(',')}") if line_numbers.size > 1
        end

        # Generate csv file
        ask_output do |csv|
          csv << headers_main
          rows_main.each do |row|
            key = row[join_index_main]
            csv << row unless dict.key?(key)
          end
        end
      end

      desc 'reject_empty MAIN_FILE', 'Select rows from MAIN_FILE where a value is not empty'
      def reject_empty(path_a)

        headers_main, *rows_main = read_spreadsheet(path_a)

        join_index_main = ask_header_index(headers_main, 'Pick a match column for MAIN_FILE')

        # Generate csv file
        ask_output do |csv|
          csv << headers_main
          rows_main.each do |row|
            key = row[join_index_main]
            csv << row unless key.blank?
          end
        end
      end

      desc 'split CSV_FILE', 'Splits a csv file into multiple files'
      def split(path)
        headers, *rows = read_spreadsheet(path)

        lines = ask_natural_number('Pick a max length of the output files')

        extname = File.extname(path)
        basename = File.basename(path, extname)

        output_dir = ask_output_dir("#{basename}_out", mkdir: true)

        rows.each_slice(lines).each.with_index(1) do |slice, part|
          filename = File.join(output_dir, "#{basename}_part#{part}.csv")

          output(filename) do |csv|
            csv << headers
            slice.each { |row| csv << row }
          end
        end
      end

      desc 'concat CSV_FILE...', 'Concatenate multiple csv files into single csv file'
      def concat(path, *paths)
        headers, *rows = read_spreadsheet(path)

        paths.each do |_path|
          _headers, *_rows = read_spreadsheet(_path)

          unless headers == _headers
            say("Headers does not match. Ignoring file #{_path}")
            next
          end

          rows += _rows
        end

        ask_output do |csv|
          csv << headers
          rows.each do |row|
            csv << row
          end
        end
      end

      desc 'concat_csv FILE...', 'Concatenate multiple csv files into single csv file. This expects all files to be csv format.'
      def concat_csv(path, *paths)
        headers, *rows = read_csv(path)

        paths.each do |_path|
          _headers, *_rows = read_csv(_path)

          unless headers == _headers
            say("Headers does not match. Ignoring file #{_path}")
            next
          end

          rows += _rows
        end

        ask_output do |csv|
          csv << headers
          rows.each do |row|
            csv << row
          end
        end
      end

      desc 'doublets CSV_FILE', 'Detect doublets'
      def doublets(path)
        headers, *rows = read_spreadsheet(path)

        join_indexes = ask_header_indexes(headers, 'Pick column(s) for CSV_FILE')

        # Build search index
        dict = Hash.new { |h,k| h[k] = [] }
        rows.each.with_index(2) do |row, line_number|
          key = row.values_at(*join_indexes)
          dict[key] << line_number
        end

        say('')

        # Delete all keys that are only appearing once
        dict.delete_if { |_,line_numbers| line_numbers.size <= 1 }

        # Warn about doublets
        dict.each do |key, line_numbers|
          error("'#{key.inspect}' found in multiple rows (#{line_numbers.join(',')}")
        end

        if dict.empty?
          say('No doublets found for: %s' % headers.inspect)
        end
      end


      desc 'expand CSV_FILE', 'Expand a CSV file by splitting a column value'
      def expand(path)
        headers, *rows = read_spreadsheet(path)

        split_index = ask_header_index(headers, "Pick a split column for CSV_FILE")
        delimiter = ask("Pick a delimiter (default: ',' comma):")
        delimiter = ',' if delimiter.strip == ''

        include_blank = nil
        ask_output do |csv|
          csv << headers

          rows.each do |row|
            value_to_split = row[split_index]

            if value_to_split.blank?
              include_blank ||= yes?('Empty values were found. Would you like to include them?')

              csv << row if include_blank
            else
              value_to_split.split(delimiter).each do |value|
                value.strip!

                new_row = row.dup
                new_row[split_index] = value
                csv << new_row
              end
            end
          end
        end
      end
    end
  end
end
