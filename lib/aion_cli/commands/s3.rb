require 'aion-s3'

module AionCLI
  module CLI
    class S3 < Thor
      include AionCLI::ApplicationHelper

      desc 'unpack PATH', 'Decrypts and decompresses a file'
      def unpack(path)
        data = File.read(path, mode: 'rb')

        password = ask("Password:")
        packer = AionS3::Packer.new(password)

        output_path = ask_output_path
        File.open(output_path, 'wb') do |io|
          io.write(packer.unpack(data))
        end
        say("Done! Output stored in #{output_path}", :green)
      end

      desc 'pack PATH', 'Compresses and encrypts a file'
      def pack(path)
        data = File.read(path, mode: 'rb')

        password = ask("Password [leave blank to generate random]:")

        if password.present?
          packer = AionS3::Packer.new(password)
        else
          packer = AionS3::Packer.new
          say("Password set to #{packer.password}")
        end

        output_path = ask_output_path
        File.open(output_path, 'wb') do |io|
          io.write(packer.pack(data))
        end
        say("Done! Output stored in #{output_path}", :green)
      end

    end
  end
end
