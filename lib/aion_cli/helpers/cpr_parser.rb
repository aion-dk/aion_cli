class CPRParser
  SUPPORTED_RECORD_TYPES = [
      '001',  # Personoplysninger
      '002',  # Aktuelle adresseoplysninger (med adresse UUID)
      '003',  # Adrnvn og klarskriftadresse
      '008'   # Aktuelle navneoplysninger
  ].freeze

  RECORD_STRUCTURES = {
      # Personoplysninger
      '001' => {
          # recordtype:         { length: 3,  description: "Lig tre sidste cifre i recordtype" },
          # pnr:                { length: 10, description: "Personnummer" },
          pnr_gaeld:            { length: 10, description: "Gældende personnummer" },
          status:               { length: 2,  description: "Status" },
          statushaenstart:      { length: 12, description: "Statusdato ÅÅÅÅMMDDTTMM - TTMM leveres altid som 0000 - TTMM leveres altid som 0000" },
          statusdto_umrk:       { length: 1,  description: "Statusdato usikkerhedsmarkering" },
          koen:                 { length: 1,  description: "Køn Værdisæt: M = mænd K = kvinder" },
          foed_dt:              { length: 10, description: "Fødselsdato ÅÅÅÅ-MM-DD" },
          foed_dt_umrk:         { length: 1,  description: "Fødselsdato usikkerhedsmarkering" },
          start_dt_person:      { length: 10, description: "Person startdato ÅÅÅÅ-MM-DD" },
          start_dt_umrk_person: { length: 1,  description: "Startdato usikkerhedsmarkering" },
          slut_dt_person:       { length: 10, description: "Person slutdato ÅÅÅÅ-MM-DD" },
          slut_dt_umrk_person:  { length: 1,  description: "Slutdato usikkerhedsmarkering" },
          stilling:             { length: 34, description: "Stilling" }
      },
      # Aktuelle adresseoplysninger
      '002' => {
          # recordtype:         { length: 3,  description: "Lig tre sidste cifre i recordtype" },
          # pnr:                { length: 10, description: "Personnummer" },
          komkod:               { length: 4,  description: "Kommunekode" },
          vejkod:               { length: 4,  description: "Vejkode" },
          husnr:                { length: 4,  description: "Husnummer" },
          etage:                { length: 2,  description: "Etage" },
          sidedoer:             { length: 4,  description: "Sidedør nummer" },
          bnr:                  { length: 4,  description: "Bygningsnummer" },
          convn:                { length: 34, description: "C/O navn" },
          tilflydto:            { length: 12, description: "Tilflytningsdato ÅÅÅÅMMDDTTMM - TTMM leveres altid som 0000" },
          tilflydto_umrk:       { length: 1,  description: "Tilflytningsdato usikkerhedsmarkering" },
          tilflykomdto:         { length: 12, description: "Tilflytning kommune dato ÅÅÅÅMMDDTTMM - TTMM leveres altid som 0000" },
          tilflykomdt_umrk:     { length: 1,  description: "Tilflytning kommune dato usikkerhedsmarkering" },
          fraflykomkod:         { length: 4,  description: "Fraflytning kommunekode" },
          fraflykomdto:         { length: 12, description: "Fraflytning kommune dato ÅÅÅÅMMDDTTMM - TTMM leveres altid som 0000" },
          fraflykomdt_umrk:     { length: 1,  description: "Fraflytning kommune dato usikkerhedsmarkering" },
          start_mynkod_adrtxt:  { length: 4,  description: "Start myndighed" },
          adr1_supladr:         { length: 34, description: "1. linie af supplerende adr" },
          adr2_supladr:         { length: 34, description: "2. linie af supplerende adr" },
          adr3_supladr:         { length: 34, description: "3. linie af supplerende adr" },
          adr4_supladr:         { length: 34, description: "4. linie af supplerende adr" },
          adr5_supladr:         { length: 34, description: "5. linie af supplerende adr" },
          start_dt_adrtxt:      { length: 10, description: "Startdato ÅÅÅÅ-MM-DD" },
          slet_dt_adrtxt:       { length: 10, description: "Slettedato ÅÅÅÅ-MM-DD" }
      },
      # Aktuelle adresseoplysninger med adresse UUID
      '002B' => {
          # recordtype:         { length: 3,  description: "Lig tre sidste cifre i recordtype" },
          # pnr:                { length: 10, description: "Personnummer" },
          komkod:               { length: 4,  description: "Kommunekode" },
          vejkod:               { length: 4,  description: "Vejkode" },
          husnr:                { length: 4,  description: "Husnummer" },
          etage:                { length: 2,  description: "Etage" },
          sidedoer:             { length: 4,  description: "Sidedør nummer" },
          bnr:                  { length: 4,  description: "Bygningsnummer" },
          convn:                { length: 34, description: "C/O navn" },
          tilflydto:            { length: 12, description: "Tilflytningsdato ÅÅÅÅMMDDTTMM - TTMM leveres altid som 0000" },
          tilflydto_umrk:       { length: 1,  description: "Tilflytningsdato usikkerhedsmarkering" },
          tilflykomdto:         { length: 12, description: "Tilflytning kommune dato ÅÅÅÅMMDDTTMM - TTMM leveres altid som 0000" },
          tilflykomdt_umrk:     { length: 1,  description: "Tilflytning kommune dato usikkerhedsmarkering" },
          fraflykomkod:         { length: 4,  description: "Fraflytning kommunekode" },
          fraflykomdto:         { length: 12, description: "Fraflytning kommune dato ÅÅÅÅMMDDTTMM - TTMM leveres altid som 0000" },
          fraflykomdt_umrk:     { length: 1,  description: "Fraflytning kommune dato usikkerhedsmarkering" },
          start_mynkod_adrtxt:  { length: 4,  description: "Start myndighed" },
          adr1_supladr:         { length: 34, description: "1. linie af supplerende adr" },
          adr2_supladr:         { length: 34, description: "2. linie af supplerende adr" },
          adr3_supladr:         { length: 34, description: "3. linie af supplerende adr" },
          adr4_supladr:         { length: 34, description: "4. linie af supplerende adr" },
          adr5_supladr:         { length: 34, description: "5. linie af supplerende adr" },
          start_dt_adrtxt:      { length: 10, description: "Startdato ÅÅÅÅ-MM-DD" },
          slet_dt_adrtxt:       { length: 10, description: "Slettedato ÅÅÅÅ-MM-DD" },
          vejnvn:               { length: 40, description: "Vejnavn" },
          adresse_uuid:         { length: 36, description: "Adresse UUID fx. c6db48f3-f834-4776-b6fe03127e3ec1b2" }
      },
      # Adrnvn og klarskriftadresse
      '003' => {
          # recordtype: { length: 3,  description: "Lig tre sidste cifre i recordtype" },
          # pnr:        { length: 10, description: "Personnummer" },
          adrnvn:       { length: 34, description: "Adresseringsnavn" },
          convn:        { length: 34, description: "C/O navn" },
          lokalitet:    { length: 34, description: "Lokalitet" },
          standardadr:  { length: 34, description: "Vejadrnvn,husnr,etage,sidedoer bnr. Etiketteadresse" },
          bynavn:       { length: 34, description: "Bynavn" },
          postnr:       { length: 4,  description: "Postnummer" },
          postdisttxt:  { length: 20, description: "Postdistrikt tekst" },
          komkod:       { length: 4,  description: "Kommunekode" },
          vejkod:       { length: 4,  description: "Vejkode" },
          husnr:        { length: 4,  description: "Husnummer" },
          etage:        { length: 2,  description: "Etage" },
          sidedoer:     { length: 4,  description: "Sidedør nummer" },
          bnr:          { length: 4,  description: "Bygningsnummer" },
          vejadrnvn:    { length: 20, description: "Vejadresseringsnavn" }
      },
      # Aktuelle navneoplysninger
      '008' => {
          # recordtype:         { length: 3,  description: "Lig tre sidste cifre i recordtype" },
          # pnr:                { length: 10, description: "Personnummer" },
          fornvn:               { length: 50, description: "Fornavn(e)" },
          fornvn_mrk:           { length: 1,  description: "Fornavn markering" },
          melnvn:               { length: 40, description: "Mellemnavn" },
          melnvn_mrk:           { length: 1,  description: "Mellemnavn markering" },
          efternvn:             { length: 40, description: "Efternavn" },
          efternvn_mrk:         { length: 1,  description: "Efternavn markering" },
          nvnhaenstart:         { length: 12, description: "Navne startdato ÅÅÅÅMMDDTTM - TTMM leveres altid som 0000" },
          haenstart_umrk_navne: { length: 1,  description: "Navne startdato usikkerhedsmarkering" },
          adrnvn:               { length: 34, description: "Adresseringsnavn" }
      },
  }.freeze

  def initialize
    @existent_record_type = Set.new
  end

  def parse_line(line)
    offset = 0
    record_type = line[offset, 3]; offset += 3
    record_type = '002B' if record_type == '002' && line.length > 306
    cpr_no = line[offset, 10]; offset += 10

    @existent_record_type << record_type

    record = {}
    # I already read :record_type and :pnr (cpr number)
    RECORD_STRUCTURES[record_type]
        .each do |attr_name, attr|
          record[attr_name] = line[offset, attr[:length]]
          offset += attr[:length]
        end

    [cpr_no, record]
  end

  def available_attributes
    attributes = {}

    @existent_record_type.sort.each do |record_type|
      RECORD_STRUCTURES[record_type].each do |attr_name, attr|
        attributes[attr_name] = attr[:description]
      end
    end

    attributes
  end

  def supported_record_types
    SUPPORTED_RECORD_TYPES
  end

end
