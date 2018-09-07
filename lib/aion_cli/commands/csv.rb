require 'aion_cli/helpers/csv_helper'

module AionCLI
  module CLI
    class Csv < Thor
      include AionCLI::CsvHelper

      desc 'uniform CSV_FILE', 'Convert to semi-colon separated UTF-8 csv file'
      long_desc <<-LONG_DESC
        Guesses the encoding and column separator of CSV_FILE.\n
        Outputs the file as a semi-colon separated UTF-8 CSV file.
      LONG_DESC

      def uniform(path)
        absolute_path = File.absolute_path(path)
        rows = read_csv(absolute_path)

        $stdout << CSV.generate(col_sep: ';') do |out|
          rows.each do |row|
            out << row
          end
        end
      end

      desc 'slice CSV_FILE [SELECTION]', 'Filter columns for csv file'
      long_desc <<-LONG_DESC
        Guesses the encoding and column separator of CSV_FILE.\n
        Outputs the file as a semi-colon separated UTF-8 CSV file, with only selected columns.
      LONG_DESC


      def slice(path, columns = nil)
        absolute_path = File.absolute_path(path)
        rows = read_csv(absolute_path)

        if columns and columns =~ /^\d+(,\d+)*$/
          column_indexes = columns.split(',').map(&:to_i)
          $stdout << CSV.generate(col_sep: ';') do |out|
            rows.each do |row|
              out << column_indexes.map {|i| row[i]}
            end
          end

        else
          $stderr << "Columns selection missing. Define selected Fx. 1,2,0\n"
          rows.first.each_with_index do |name, index|
            $stderr << "#{index}) #{name}\n"
          end
        end
      end

      desc 'join CSV_FILE_1 CSV_FILE_2 [JOIN_EXPRESSION]', 'join two CSV files into one'
      long_desc <<-LONG_DESC
        Guesses the encoding and column separator of CSV_FILE_1 and CSV_FILE_2.\n
        Outputs a new CSV file as a semi-colon separated UTF-8 CSV file.

        Values from CSV_FILE_1 will be mixed into CSV_FILE_2 based on a JOIN_EXPRESSION.

        A JOIN_EXPRESSION is a pair of indexes for the join columns in CSV_FILE_1 and CSV_FILE_2 respectively.

        Fx. 0=1 will combine rows where value in first column of CSV_FILE_1 and second column of CSV_FILE_2 match.

        Fail if any of join values in CSV_FILE_1 appear more than once.
        Fail if any of the join values in CSV_FILE_2 are missing in CSV_FILE_1.
      LONG_DESC

      def join(path_a, path_b, join_expression = nil)
        absolute_path_a = File.absolute_path(path_a)
        absolute_path_b = File.absolute_path(path_b)

        rows_a = read_csv(absolute_path_a)
        rows_b = read_csv(absolute_path_b)

        if join_expression && join_expression =~ /^\d+=\d+$/
          join_index_a, join_index_b = join_expression.split('=').map(&:to_i)

          join_hash = {}

          headers_a = rows_a.shift

          rows_a.each do |values|
            key = values[join_index_a]
            raise Thor::Error, 'Duplicate keys in join column for CSV_FILE_1' if join_hash.has_key?(key)
            join_hash[key] = values
          end

          output = CSV.generate(col_sep: ';') do |out|

            # Join header rows discarding duplicate from b
            headers_b = rows_b.shift

            out << headers_a + headers_b

            rows_b.each do |values_b|
              join_value = values_b[join_index_b]
              values_a = join_hash[join_value]
              if values_a.nil?
                $stderr << "Join value: #{join_value}\n"
                raise Thor::Error, 'Error! Join value missing in CSV_FILE_1'
              end

              out << values_a + values_b
            end

          end

          puts output

        else

          $stderr << "\nColumn headers for CSV_FILE_1\n"
          rows_a.first.each_with_index do |name, index|
            $stderr << "#{index}) #{name}\n"
          end

          $stderr << "\nColumn headers for CSV_FILE_2\n"
          rows_b.first.each_with_index do |name, index|
            $stderr << "#{index}) #{name}\n"
          end

          $stderr << "\nCompose a join expression with an index from each csv. Fx. 1=2\n"

        end

      end


      desc 'count CSV_FILE GROUP_BY SUM', 'Count votes with weights'

      long_desc '...'

      def count(path, group_by = nil, sum = nil)
        absolute_path = File.absolute_path(path)
        rows = read_csv(absolute_path)

        if group_by =~ /^\d+(,\d+)+$/ and sum =~ /^\d+$/

          group_by_indexes = group_by.split(',').map(&:to_i)
          sum_index = sum.to_i

          headers = rows.shift

          result = {}
          rows.each do |row|
            key = group_by_indexes.map {|i| row[i]}

            sum_value = row[sum_index]
            raise Thor::Error, 'Non num value in sum' unless sum_value =~ /^\d+$/

            result[key] ||= 0
            result[key] += sum_value.to_i
          end


          $stdout << CSV.generate(col_sep: ';') do |csv|

            new_headers = group_by_indexes.map {|i| headers[i]}
            new_headers << 'sum of votes'

            csv << new_headers

            result.each do |key, sum|
              csv << key + [sum]
            end

          end

        else

          headers = rows.shift
          headers.each_with_index do |name, index|
            puts "#{index}) #{name}"
          end

          raise Thor::RequiredArgumentMissingError, 'Invalid values for GROUP_BY and/or SUM'
        end

      end

      desc 'sort CSV_FILE [SORT_INDEXES]', 'Sorts a CSV file given a list of indexes'

      def sort(path, sort_by = nil)
        absolute_path = File.absolute_path(path)
        rows = read_csv(absolute_path)

        if sort_by =~ /^\d+(,\d+)+$/
          sort_by_indexes = sort_by.split(',').map(&:to_i)
          headers = rows.shift
          new_rows = rows.sort_by {|row| sort_by_indexes.map {|i|
            value = row[i]
            value =~ /^\d+$/ ? value.to_i : value
          }}

          $stdout << CSV.generate(col_sep: ';') do |csv|
            csv << headers
            new_rows.each do |row|
              csv << row
            end
          end

        else
          headers = rows.shift
          headers.each_with_index do |name, index|
            puts "#{index}) #{name}"
          end

          puts 'SORT_BY is missing. Specify the columns to sort by. Fx. 0,3,2'
        end
      end

      desc 'filter_cpr CSV_FILE_1 CPR_FILE CPR_COLUMN_NO', 'Filter records from CSV_FILE_1 of CPRs found in CPR_FILE'
      long_desc <<-LONG_DESC
        Guesses the encoding and column separator of CSV_FILE_1 and CPR_FILE.\n
        Outputs a new CSV file as a semi-colon separated UTF-8 CSV file.

        Filter records from CSV_FILE_1 if CPR found in CPR_FILE.
        CPRs in CPR_FILE is cleaned
        CPR column in file 2 is guessed
      LONG_DESC

      def filter_cpr(path_a, path_b, cpr_column)

        cpr_regex = /\d{6}-?\d{4}/
        clean_up_fn = lambda {|x| cpr_regex.match(x)[0].sub('-', '')}

        absolute_path_a = File.absolute_path(path_a)
        absolute_path_b = File.absolute_path(path_b)

        rows_a = read_csv(absolute_path_a)
        rows_b = read_csv(absolute_path_b)

        cprs_set = Set.new rows_b.map { |x| clean_up_fn.call(x[0]) if x[0].size }

        headers_a = rows_a.shift

        output = CSV.generate(col_sep: ';') do |out|

          out << headers_a

          rows_a.each do |recs|
            cpr = recs[cpr_column.to_i]
            unless cprs_set.include?(clean_up_fn.call(cpr))
              out << recs
            end
          end

        end

        puts output

      end

      desc 'split CSV_FILE LINES', 'Splits a csv file into multiple files'

      def split(path, lines_s)
        absolute_path = File.absolute_path(path)
        rows = read_csv(absolute_path)

        lines = lines_s.to_i
        raise 'LINES must be greater than zero' unless lines > 0

        dirname = File.dirname(absolute_path)
        extname = File.extname(absolute_path)
        basename = File.basename(absolute_path, extname)
        target_folder = File.join(dirname, "#{basename}_split_#{Time.now.to_i}")

        Dir.mkdir(target_folder)

        rows.each_slice(lines).each_with_index do |slice, index|
          filename = File.join(target_folder, "slice_#{index}.csv")
          CSV.open(filename, 'wb', col_sep: ';') do |csv|
            slice.each { |row| csv << row }
          end
        end
      end

    end
  end
end