require 'roo'
require 'csv'
require 'aion_cli/helpers/application_helper'
require 'aion_cli/helpers/dawa_client'

module AionCLI
  module CLI
    class Validate < Thor
      include AionCLI::ApplicationHelper

      desc 'multiple CSV_FILE', 'Select multiple data validation commands and perform them on a CSV file'
      def multiple(path)
        headers, *rows = read_spreadsheet(path)

        # Select validation commands
        command_headers = ['CPR validation','EMAIL validation','ADDRESS validation','EMPTY values check']
        validation_types = ask_header_indexes(command_headers, 'Specify the validations you want to perform')
        say

        # Variables used to generate result, based on selected validation commands
        counts_validation = Hash.new(0)
        counts_empty_check = Hash.new(0)

        index_cpr, index_addr, index_email, indexes_empty_check = nil
        sample = false
        n_headers = headers

        # Get column indexes of each selected validation type
        validation_types.each do |type|
          case type
          when 0
            index_cpr = ask_header_index(headers, 'Specify the CPR column')
            n_headers += ['cpr_valid']
          when 1
            index_email = ask_header_index(headers, 'Specify the EMAIL column')
            n_headers += ['email_valid']
          when 2
            index_addr = ask_header_index(headers, 'Specify the ADDRESS column')
            say
            say 'Address validation is very time consuming, consider using only a sample!'
            sample = yes?('Do you want to use a sample (25) of the addresses when validating?', :yellow)
            n_headers += ['addr_found']
          when 3
            indexes_empty_check = ask_header_indexes(headers, 'Specify which columns you want to check for empty values')
          end

          say
        end

        dawa_client = AionCLI::DAWAClient.instance

        # Iterate through selected validations and perform validation --> output to csv
        ask_output do |csv|
          csv << n_headers

          # CPR validation
          if validation_types.include?(0)

            # Build doublet index
            dict = Hash.new { |h,k| h[k] = [] }
            rows.each.with_index(2) do |row, line_number|
              key = row[index_cpr]
              unless key.blank?
                dict[key] << line_number
              end
            end

            rows.each do |row|
              cpr = row[index_cpr]
              if cpr.blank?
                counts_validation[:cpr_empty] += 1
                result = "false empty"
              elsif dict[cpr].size > 1
                counts_validation[:cpr_doublets] += 1
                result = "false doublet"
              else
                valid = validate_cpr(cpr)
                valid ? result = "true" : result = "false format"
                counts_validation[:cpr_invalid] += 1 unless valid
              end
              row << result
            end
          end

          #EMAIL validation
          if validation_types.include?(1)
            rows.each do |row|
              email = row[index_email]
              if email.blank?
                counts_validation[:email_empty] += 1
                result = "false empty"
              else
                valid = validate_email(email)
                valid ? result = "true" : result = "false format"
                counts_validation[:email_invalid] += 1 unless valid
              end
              row << result
            end
          end

          #ADDRESS validation
          if validation_types.include?(2)
            addr_tested = 0
            rows.each do |row|
              result = ""    # bedre måde?
              addr = row[index_addr]
              if addr.blank?
                counts_validation[:addr_empty] += 1
                result = "false empty"
              else
                unless addr_tested > 25 && sample
                  valid = validate_addr(addr, dawa_client)
                  valid ? result = "true" : result = "false format"
                  counts_validation[:addr_not_found] += 1 unless valid
                  addr_tested += 1
                end
              end
              row << result
            end
          end
          rows.each do |row|
            csv << row
          end

          #EMPTY check
          if validation_types.include?(3)
            indexes_empty_check.each do |index|
              rows.each do |row|
                if row[index].blank?
                  counts_empty_check[headers[index]] += 1
                end
              end
            end
          end
        end

        #RESULTS
        say '------------------------'
        say
        say 'Validation result:'
        if counts_validation.length > 0
          counts_validation.each {|key, value| say "#{key} = #{value}", :red}
        else
          say
          say 'No problems detected in validation of selected columns.', :green
        end

        if validation_types.include?(3) #Empty check
          say
          say 'Empty check result:'

          if counts_empty_check.length > 0
            counts_empty_check.each {|key, value| say "#{key} has #{value} empty values", :yellow}
          else
            say 'No empty values detected in selected columns.', :green
          end
        end
        say
        say '------------------------'

      end

      private

      def validate_cpr(cpr)
        cpr_regex = /^(?:(?:31(?:0[13578]|1[02])|(?:30|29)(?:0[13-9]|1[0-2])|(?:0[1-9]|1[0-9]|2[0-8])(?:0[1-9]|1[0-2]))[0-9]{2}-?[0-9]|290200-?[4-9]|2902(?:(?!00)[02468][048]|[13579][26])-?[0-3])[0-9]{3}|000000-?0000$/
        !!cpr.match(cpr_regex)
      end

      def validate_addr(addr, client)
        address = client.address(addr)
        address.present?
      end

      def validate_email(email)
        email_regex = URI::MailTo::EMAIL_REGEXP
        !!email.match(email_regex)
      end
    end
  end
end
