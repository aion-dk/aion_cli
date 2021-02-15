
module AionCLI
  module PreparationHelper

    protected

    def validate_cpr(cpr)

      # OLD CPR REGEX
      # For some reason it only allowed leap year cprs with 4-9 7th digit when the year is 00. I do not understand why.
      # /^(?:(?:31(?:0[13578]|1[02])|(?:30|29)(?:0[13-9]|1[0-2])|(?:0[1-9]|1[0-9]|2[0-8])(?:0[1-9]|1[0-2]))[0-9]{2}-?[0-9]|290200-?[4-9]|2902(?:(?!00)[02468][048]|[13579][26])-?[0-3])[0-9]{3}|000000-?0000$/

      cpr_regex = /^(?:(?:(?:31(?:0[13578]|1[02])|(?:30|29)(?:0[13-9]|1[0-2])|(?:0[1-9]|1[0-9]|2[0-8])(?:0[1-9]|1[0-2]))[0-9]{2}-?[0-9]|2902(?:[02468][048]|[13579][26])-?[0-9])[0-9]{3}|000000-?0000)$/
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

    def validate_phone_number(phone_number)
      dk_phone_regex = /^(?:(?:00\s?|\+\s?)?45\s?)?(?:\d{2}\s?){3}\d{2}$/
      !!phone_number.match(dk_phone_regex)
    end

    def clean_cpr(cpr)
      cpr.tr('^0-9','')
    end

    def clean_phone(phone)
      phone_cleaned = phone.tr('^0-9','')
      phone_cleaned if phone_cleaned.length == 8 || phone_cleaned.length == 10 && phone_cleaned[0..1] == '45'
    end

    def clean_dob(date,format)
      begin Date.strptime(date, format).strftime('%d%m%y') rescue nil end
    end

    def slice_file(rows, indexes, prefix, suffix)
      file_name = "#{prefix}_#{suffix}.csv"
      output_path = File.expand_path(file_name)

      if File.exists?(output_path)
        if yes?("The file #{file_name} already exists. Would you like to overwrite?", :yellow)
          File.unlink(output_path)
        else
          say "Skipped generation of #{suffix} file.", :yellow
          return
        end
      end

      output output_path  do |csv|
        rows.each do |row|
          csv << row.values_at(*indexes)
        end
        say "Generated file for #{suffix}.", :green
      end
    end

  end
end