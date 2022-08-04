require 'singleton'
require 'http'
require 'json'

module AionCLI
  class DAWAClient
    include Singleton

    URL_MUNICIPALITIES = 'https://api.dataforsyningen.dk/kommuner'
    URL_SCRUB_ADDRESS = 'https://api.dataforsyningen.dk/datavask/adresser'
    URL_PREFIX_ADDRESS = 'https://api.dataforsyningen.dk/adresser/'

    def initialize; end

    def scrub(address_string)
      dawa_response = request(URL_SCRUB_ADDRESS, params: { betegnelse: prepare_address_string(address_string) })
      $stderr << "Address validation failed for: '#{address_string}'\n" if dawa_response.nil?
      dawa_response
    end

    def address(address_string)
      scrub_object = scrub(address_string)
      return if scrub_object.nil?
      return unless %w[A B].include?(scrub_object['kategori'])

      a = scrub_object['resultater'][0]['aktueladresse']
      a = scrub_object['resultater'][0]['adresse'] if a.nil?
      [1, 3].include?(a['status']) ? a : nil
    end

    def address_by_guid(address_guid)
      request(URL_PREFIX_ADDRESS + address_guid)
    end

    def address_string(address_guid)
      object = address_by_guid(address_guid)
      object['adressebetegnelse'] if object.is_a?(Hash)
    end

    # If an address has kategori A or B it is considered a match, and the guid is returned
    # Otherwise nil is returned
    def address_guid(address_string)
      _address = address(address_string)
      _address['id'] if _address.is_a?(Hash)
    end

    def address_object_to_s(address_object)
      return unless address_object
      out = StringIO.new
      out << address_object['vejnavn'] << ' ' << address_object['husnr'] << ', '
      if address_object['etage'] || address_object['dør']
        out << address_object['etage'] << '.'
        out << ' ' << address_object['dør'] if address_object['dør']
        out << ', '
      end
      out << address_object['supplerendebynavn'] << ', ' if address_object['supplerendebynavn']
      out << address_object['postnr'] << ' ' << address_object['postnrnavn']
      out.string
    end


    # Returns a list of objects representing
    # all municipalities in Denmark.
    #
    # The list is fetched from the DAWA service but is cached
    # in an instance variable.
    def municipalities
      @municipalities ||= request(URL_MUNICIPALITIES)
    end


    # Given an array of municipality codes, will return the name.
    # An error will be raised if a match is missing.
    #
    # @param codes array of integers
    # @return a list of names
    # @raise StandardError if a name was not found
    def municipality_names(codes)
      pairs = Hash[ municipalities.map { |o| [o['kode'].to_i, o['navn']] } ]
      codes.map { |code| pairs[code] or raise 'Name not found' }
    end


    # Helper method for returning objects from requests
    def request(url, params: {}, max_retries: 3)
      max_retries.times do
        dawa_response = HTTP.timeout(connect: 5, write: 30, read: 30).get(url, params: params).to_s
        return JSON.parse(dawa_response)
      rescue JSON::ParserError => e
        $stderr << "Error occured when attempting to parse response from DAWA: #{e.message}\nRetrying...\n"
      rescue => e
        $stderr << "Error occured: #{e.message}\nRetrying...\n"
      end

      $stderr << "Request failed #{max_retries} times, skipping\n"
      nil
    end

    private

    def prepare_address_string(address_string)
      raise ArgumentError, 'Supplied address is not a string' unless address_string.is_a? String

      # DAWA service does not handle leading zeroes that well
      # address_string.gsub(/ 0+/, ' ')

      address_string
    end

  end
end