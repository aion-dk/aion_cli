require 'yaml'

module AionCLI
  # Runtime configuration for the CLI.
  #
  # Values are resolved in order of precedence:
  #
  #   1. Environment variable, upper-cased (e.g. DATAFORDELER_API_KEY)
  #   2. The YAML config file (default ~/.config/aion/config.yml)
  #   3. The default supplied by the caller
  #
  # Secrets are never hardcoded. They have no default and must come from one
  # of the first two sources -- +fetch!+ raises MissingConfig with setup
  # instructions when a required value is absent.
  module Config
    class MissingConfig < StandardError; end

    DEFAULT_PATH = File.expand_path('~/.config/aion/config.yml')

    class << self
      # Returns the configured value, falling back to +default+ when the key
      # is not set anywhere.
      def fetch(key, default = nil)
        env(key) || file[key.to_s] || default
      end

      # Returns the configured value, or raises MissingConfig explaining how
      # to supply it. Use this for secrets that have no safe default.
      def fetch!(key)
        value = fetch(key)
        raise MissingConfig, missing_message(key) if blank?(value)

        value
      end

      # Path of the config file. Override with AION_CONFIG for testing or to
      # keep several environments side by side.
      def path
        ENV.fetch('AION_CONFIG') { DEFAULT_PATH }
      end

      # Parsed contents of the config file, or an empty hash when it does not
      # exist. Read once and memoised.
      def file
        @file ||= load_file
      end

      # Forget the memoised file, so the next read picks up changes on disk.
      def reload!
        @file = nil
      end

      private

      def env(key)
        value = ENV[key.to_s.upcase]
        value unless blank?(value)
      end

      def blank?(value)
        value.nil? || value.to_s.strip.empty?
      end

      def load_file
        return {} unless File.exist?(path)

        warn_about_permissions
        YAML.safe_load(File.read(path)) || {}
      rescue Psych::SyntaxError => e
        raise MissingConfig, "Could not parse #{path}\n\n  #{e.message}\n"
      end

      # The config file holds secrets, so it should not be readable by other
      # users on the machine.
      def warn_about_permissions
        return if (File.stat(path).mode & 0o077).zero?

        $stderr << "Warning: #{path} is readable by other users. " \
                   "Run: chmod 600 #{path}\n"
      end

      def missing_message(key)
        <<~MESSAGE

          Missing required configuration: #{key}

          Supply it either as an environment variable:

              export #{key.to_s.upcase}="..."

          or by adding it to #{path}:

              #{key}: "..."

          To create the file:

              mkdir -p #{File.dirname(path)}
              touch #{path} && chmod 600 #{path}

          See the Configuration section of the README for where to obtain the
          value.

        MESSAGE
      end
    end
  end
end
