module SmartAnswer::Calculators
  class OverseasPassportsCalculator
    APPLY_IN_NEIGHBOURING_COUNTRIES = %w(
      british-indian-ocean-territory north-korea south-georgia-and-south-sandwich-islands
    )

    BOOK_APPOINTMENT_ONLINE_COUNTRIES = %w(
      kyrgyzstan tajikistan turkmenistan uzbekistan
    )

    UK_VISA_APPLICATION_CENTRE_COUNTRIES = %w(
      afghanistan algeria azerbaijan bangladesh belarus burundi burma cambodia
      china gaza georgia india indonesia kazakhstan kyrgyzstan laos lebanon
      mauritania morocco nepal pakistan russia tajikistan thailand turkmenistan
      ukraine uzbekistan western-sahara vietnam venezuela
    )

    UK_VISA_APPLICATION_WITH_COLOUR_PICTURES_COUNTRIES = %w(
      afghanistan azerbaijan algeria bangladesh belarus burma cambodia china
      georgia india indonesia kazakhstan laos lebanon mauritania morocco nepal
      pakistan tajikistan thailand turkmenistan ukraine uzbekistan russia
      vietnam venezuela western-sahara
    )

    EXCLUDE_COUNTRIES = %w(
      holy-see british-antarctic-territory
    )

    INELIGIBLE_COUNTRIES = %w(
      iran libya syria yemen
    )

    NON_UK_VISA_APPLICATION_WITH_COLOUR_PICTURES_COUNTRIES = %w(
      burma cuba sudan tajikistan turkmenistan uzbekistan
    )

    attr_accessor :current_location
    attr_accessor :birth_location
    attr_accessor :application_action

    def initialize(data_query: nil)
      @data_query = data_query || PassportAndEmbassyDataQuery.new
    end

    def book_appointment_online?
      BOOK_APPOINTMENT_ONLINE_COUNTRIES.include?(current_location)
    end

    def uk_visa_application_centre?
      UK_VISA_APPLICATION_CENTRE_COUNTRIES.include?(current_location)
    end

    def uk_visa_application_with_colour_pictures?
      UK_VISA_APPLICATION_WITH_COLOUR_PICTURES_COUNTRIES.include?(current_location)
    end

    def non_uk_visa_application_with_colour_pictures?
      NON_UK_VISA_APPLICATION_WITH_COLOUR_PICTURES_COUNTRIES.include?(current_location)
    end

    def ineligible_country?
      INELIGIBLE_COUNTRIES.include?(current_location)
    end

    def apply_in_neighbouring_countries?
      APPLY_IN_NEIGHBOURING_COUNTRIES.include?(current_location)
    end

    def alternate_embassy_location(location = current_location)
      PassportAndEmbassyDataQuery::ALT_EMBASSIES[location]
    end

    def world_location(location = current_location)
      search_location = alternate_embassy_location(location) || location

      WorldLocation.find(search_location)
    end

    def world_location_name(location = current_location)
      world_location(location).name
    end

    def fco_organisation(location = current_location)
      world_location(location).fco_organisation
    end

    def cash_only_country?
      @data_query.cash_only_countries?(current_location)
    end

    def renewing_country?
      @data_query.renewing_countries?(current_location)
    end
  end
end
