require 'singleton'
require 'http'
require 'json'
require 'time'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/string/filters'
require 'aion_cli/helpers/config'

module AionCLI
  class DatafordelerClient
    include Singleton

    GRAPHQL_BASE_URL = Config.fetch('datafordeler_graphql_base_url', 'https://graphql.datafordeler.dk')
    ADRESSEVASK_BASE_URL = Config.fetch('adressevask_base_url', 'https://adressevaelger.dk/')
    DAR_VERSION = Config.fetch('datafordeler_dar_version', 'v3')
    DAGI_VERSION = Config.fetch('datafordeler_dagi_version', 'v2')

    URL_ADRESSEVASK = "#{ADRESSEVASK_BASE_URL.chomp('/')}/vask/"
    URL_DAR = "#{GRAPHQL_BASE_URL.chomp('/')}/DAR/#{DAR_VERSION}"
    URL_DAGI = "#{GRAPHQL_BASE_URL.chomp('/')}/DAGI/#{DAGI_VERSION}"

    # Number of DAR candidates requested per address lookup
    ADDRESS_LIMIT = 10

    # Address statuses considered current ("gældende")
    CURRENT_STATUSES = %w[1 3].freeze

    Municipality = Struct.new(:code, :name)

    def initialize; end

    # Washes an address string through Adressevask and returns the
    # canonical "adressebetegnelse", or nil if the text could not be
    # recognised as an address.
    def scrub(address_string)
      return if address_string.blank?
      raise ArgumentError, 'Supplied address is not a string' unless address_string.is_a?(String)

      result = vask(address_string)
      if result.nil?
        $stderr << "Address validation failed for: '#{address_string}'\n"
        return
      end

      return unless result.dig('vaskestatus', 'kode').to_i.positive?

      result.dig('vaskeresultat', 'adressebetegnelse')
    end

    # Returns the DAR address node for an exact, current address match.
    # Otherwise nil is returned.
    def address(address_string)
      scrubbed = scrub(address_string)
      return if scrubbed.blank?

      addresses_by_betegnelse(scrubbed).find do |address|
        address['adressebetegnelse'] == scrubbed && current?(address)
      end
    end

    # Returns the local DAR ID for an exact, current address match.
    # Otherwise nil is returned.
    def address_guid(address_string)
      _address = address(address_string)
      _address['id_lokalId'] if _address.is_a?(Hash)
    end

    # Returns a list of objects representing
    # all municipalities in Denmark.
    #
    # The list is fetched from Datafordeler's DAGI service but is cached
    # in an instance variable.
    def municipalities
      @municipalities ||= dagi_nodes('DAGI_Kommuneinddeling', 'kommunekode navn').map do |municipality|
        Municipality.new(municipality['kommunekode'], municipality['navn'])
      end
    end

    # Given an array of municipality codes, will return the name.
    # An error will be raised if a match is missing.
    #
    # @param codes array of integers
    # @return a list of names
    # @raise StandardError if a name was not found
    def municipality_names(codes)
      pairs = municipalities.to_h { |municipality| [municipality.code.to_i, municipality.name] }
      codes.map { |code| pairs.fetch(code) { raise 'Name not found' } }
    end

    private

    def current?(address)
      CURRENT_STATUSES.include?(address['status'].to_s)
    end

    def vask(address_string)
      request(URL_ADRESSEVASK, params: { token: vask_token, adresse: address_string })
    end

    def vask_token
      Config.fetch('adressevask_token', 'adressevaelger123')
    end

    def addresses_by_betegnelse(address_string)
      query = <<~GRAPHQL.squish
        query {
          DAR_Adresse(first: #{ADDRESS_LIMIT}, registreringstid: #{current_time}, virkningstid: #{current_time},
            where: { adressebetegnelse: { startsWith: #{address_string.to_json} } }) {
            nodes { id_lokalId adressebetegnelse status }
          }
        }
      GRAPHQL

      graph_ql(URL_DAR, query).to_h.dig('data', 'DAR_Adresse', 'nodes') || []
    end

    def dagi_nodes(entity, fields)
      query = <<~GRAPHQL.squish
        query {
          #{entity}(first: 100, registreringstid: #{current_time}, virkningstid: #{current_time}) {
            nodes { #{fields} }
          }
        }
      GRAPHQL

      graph_ql(URL_DAGI, query).to_h.dig('data', entity, 'nodes') || []
    end

    def graph_ql(url, query)
      body = { query: query }.to_json
      headers = { 'Accept' => 'application/graphql-response+json', 'Content-Type' => 'application/json' }
      response = request(url, params: api_params, body: body, headers: headers)
      return if response.nil?

      $stderr << "Datafordeler returned errors: #{response['errors'].to_json}\n" if response['errors'].present?
      response
    end

    def api_params
      { apiKey: Config.fetch!('datafordeler_api_key') }
    end

    def current_time
      Time.now.utc.iso8601.to_json
    end

    # Helper method for returning objects from requests
    def request(url, params: {}, body: nil, headers: {}, max_retries: 3)
      max_retries.times do
        client = HTTP.timeout(connect: 5, write: 30, read: 30)
        client = client.headers(headers) if headers.any?
        response = body.nil? ? client.get(url, params: params) : client.post(url, params: params, body: body)
        return JSON.parse(response.to_s)
      rescue JSON::ParserError => e
        $stderr << "Error occured when attempting to parse response from Datafordeler: #{e.message}\nRetrying...\n"
      rescue StandardError => e
        $stderr << "Error occured: #{e.message}\nRetrying...\n"
      end

      $stderr << "Request failed #{max_retries} times, skipping\n"
      nil
    end
  end
end
