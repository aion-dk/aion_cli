require 'aion_cli/helpers/application_helper'

module AionCLI
  module CLI
    class STRIDE < Thor
      include AionCLI::ApplicationHelper

      desc 'threat_model Entity_csv_file Data_Flow_csv_file Data_Store_csv_file Process_csv_file', 'Generate Threat Model document out of diagram artifacts'
      def threat_model(entity_path, data_flow_path, data_store_path, process_path)
        threats_headers = ['Item', 'Type', 'Interaction', 'Threat', 'Description', 'Mitigation']
        threats_rows = []

        headers, *rows = read_spreadsheet(entity_path)
        raise Thor::Error, "Corrupt entity headers: #{headers.join(', ')}" unless headers == ['Item', 'Interaction']
        threats_rows.concat(generate_entity_threats(rows))

        headers, *rows = read_spreadsheet(data_flow_path)
        raise Thor::Error, "Corrupt data flow headers: #{headers.join(', ')}" unless headers == ['Item', 'From', 'To', 'Trust boundary']
        threats_rows.concat(generate_data_flow_threats(rows))

        headers, *rows = read_spreadsheet(data_store_path)
        raise Thor::Error, "Corrupt data store headers: #{headers.join(', ')}" unless headers == ['Item', 'Environment']
        threats_rows.concat(generate_data_store_threats(rows))

        headers, *rows = read_spreadsheet(process_path)
        raise Thor::Error, "Corrupt process headers: #{headers.join(', ')}" unless headers == ['Item', 'Environment']
        threats_rows.concat(generate_process_threats(rows))


        # Generate csv file
        ask_output do |csv|
          csv << threats_headers

          threats_rows.each do |row|
            csv << row
          end
        end
      end

      private

      def generate_entity_threats(entities)
        entity_threats = ['Spoofing', 'Repudiation']
        threats = []

        entities.each do |entity|
          entity_threats.each do |et|
            item = entity[0]
            type = 'Entity'
            interaction = "#{entity[0]} towards #{entity[1]}"
            threat = et
            description = ''
            mitigation = ''

            threats << [item, type, interaction, threat, description, mitigation]
          end
        end

        threats
      end

      def generate_data_flow_threats(data_flows)
        data_flow_threats = ['Tampering', 'Information disclosure', 'Denial of service']
        threats = []

        data_flows.each do |data_flow|
          data_flow_threats.each do |dft|
            item = data_flow[0]
            type = 'Data flow'
            interaction = "#{data_flow[1]} towards #{data_flow[2]}"
            threat = dft
            description = ''
            mitigation = data_flow[3]

            threats << [item, type, interaction, threat, description, mitigation]
          end
        end

        threats
      end

      def generate_data_store_threats(data_stores)
        data_store_threats = ['Tampering', 'Repudiation', 'Information disclosure', 'Denial of service']
        threats = []

        data_stores.each do |data_store|
          data_store_threats.each do |dst|
            item = data_store[0]
            type = 'Data store'
            interaction = "local to #{data_store[1]}"
            threat = dst
            description = ''
            mitigation = ''

            threats << [item, type, interaction, threat, description, mitigation]
          end
        end

        threats
      end

      def generate_process_threats(processes)
        process_threats = ['Spoofing', 'Tampering', 'Repudiation', 'Information disclosure', 'Denial of service', 'Elevation of privilege']
        threats = []

        processes.each do |process|
          process_threats.each do |dst|
            item = process[0]
            type = 'Process'
            interaction = "local to #{process[1]}"
            threat = dst
            description = ''
            mitigation = ''

            threats << [item, type, interaction, threat, description, mitigation]
          end
        end

        threats
      end
    end
  end
end
