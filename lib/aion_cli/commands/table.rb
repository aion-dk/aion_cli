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
            csv << row.values_at(indexes)
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
          key = row.values_at(group_by_indexes)

          sum_value = row[sum_index]
          raise Thor::Error, 'Non num value in sum' unless sum_value =~ /^\d+$/

          result[key] += sum_value.to_i
        end

        ask_output do |csv|
          new_headers = headers.values_at(group_by_indexes)
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

        sort_by_indexes = ask_header_indexes(headers, 'Pick the columns to sort by')

        new_rows = rows.sort_by { |row| sort_by_indexes.map { |i|
          value = row[i]
          value =~ /^\d+$/ ? value.to_i : value
        }}

        ask_output do |csv|
          csv << headers

          new_rows.each do |row|
            csv << row
          end
        end
      end


      desc 'join MAIN_FILE ADDITIONAL_FILE', 'Adds the columns of ADDITIONAL_FILE by joining where a vasluer match is found'
      def join(path_a, path_b)
        headers_a, *rows_a = read_spreadsheet(path_a)
        headers_b, *rows_b = read_spreadsheet(path_b)

        join_index_a = ask_header_index(headers_a, 'Pick a join column for MAIN_FILE')
        join_index_b = ask_header_index(headers_b, 'Pick a join column for ADDITIONAL_FILE')

        # Build search index
        join_b_hash = {}
        rows_b.each do |values|
          key = values[join_index_b]
          raise Thor::Error, 'Empty value in join column for ADDITIONAL_FILE' if key.nil? or key.strip == ''
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


      desc 'select MAIN_FILE ADDITIONAL_FILE', 'Select rows from MAIN_FILE where a value is also found in ADDITIONAL_FILE'
      def select(path_a, path_b)

        headers_main, *rows_main = read_spreadsheet(path_a)
        headers_dict, *rows_dict = read_spreadsheet(path_b)

        join_index_main = ask_header_index(headers_main, 'Pick a match column for MAIN_FILE')
        join_index_dict = ask_header_index(headers_dict, 'Pick a match column for ADDITIONAL_FILE')

        # Build search index
        dict = Hash.new { |h,k| h[k] = [] }
        rows_dict.each.with_index(2) do |values, line_number|
          key = values[join_index_dict]
          if key.blank?
            alert_warning('empty value found in match column for ADDITIONAL_FILE')
          else
            dict[key] << line_number
          end
        end

        # Warn about doublets
        dict.each do |key, line_numbers|
          alert_warning("'#{key}' found in multiple lines (#{line_numbers.join(',')}") if line_numbers.size > 1
        end

        # Generate csv file
        ask_output do |csv|
          csv << headers_main

          rows_main.each do |row|
            match_value = row[join_index_main]
            next unless dict[match_value]
            csv << row
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
        rows_dict.each.with_index(2) do |values, line_number|
          key = values[join_index_dict]
          if key.blank?
            alert_warning('empty value found in match column for ADDITIONAL_FILE')
          else
            dict[key] << line_number
          end
        end

        # Warn about doublets
        dict.each do |key, line_numbers|
          alert_warning("'#{key}' found in multiple lines (#{line_numbers.join(',')}") if line_numbers.size > 1
        end

        # Generate csv file
        ask_output do |csv|
          csv << headers_main

          rows_main.each do |row|
            match_value = row[join_index_main]
            next if dict[match_value]
            csv << row
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
          alert_warning("'#{key.inspect}' found in multiple rows (#{line_numbers.join(',')}")
        end

        if dict.empty?
          say('No doublets found for: %s' % headers.inspect)
        end


      end

    end
  end
end