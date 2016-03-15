require_relative "../../test_helper"

module SmartAnswer
  module Calculators
    class OverseasPassportsCalculatorTest < ActiveSupport::TestCase
      context '#current_location' do
        setup do
          @calculator = OverseasPassportsCalculator.new
        end

        should 'allow current_location to be written and read' do
          @calculator.current_location = 'springfield'
          assert_equal @calculator.current_location, 'springfield'
        end
      end

      context '#book_appointment_online?' do
        setup do
          @calculator = OverseasPassportsCalculator.new
        end

        should 'be true if current_location is in BOOK_APPOINTMENT_ONLINE_COUNTRIES countries' do
          OverseasPassportsCalculator::BOOK_APPOINTMENT_ONLINE_COUNTRIES.each do |country|
            @calculator.current_location = country
            assert @calculator.book_appointment_online?
          end
        end

        should 'be false if current_location is not in BOOK_APPOINTMENT_ONLINE_COUNTRIES' do
          @calculator.current_location = 'antarctica'
          refute @calculator.book_appointment_online?
        end
      end

      context '#uk_visa_application_centre?' do
        setup do
          @calculator = OverseasPassportsCalculator.new
        end

        should 'be true if current_location is in UK_VISA_APPLICATION_CENTRE_COUNTRIES countries' do
          OverseasPassportsCalculator::UK_VISA_APPLICATION_CENTRE_COUNTRIES.each do |country|
            @calculator.current_location = country
            assert @calculator.uk_visa_application_centre?
          end
        end

        should 'be false if current_location is not in UK_VISA_APPLICATION_CENTRE_COUNTRIES' do
          @calculator.current_location = 'antarctica'
          refute @calculator.uk_visa_application_centre?
        end
      end


      context '#uk_visa_application_with_colour_pictures?' do
        setup do
          @calculator = OverseasPassportsCalculator.new
        end

        should 'be true if current_location is in UK_VISA_APPLICATION_WITH_COLOUR_PICTURES_COUNTRIES' do
          OverseasPassportsCalculator::UK_VISA_APPLICATION_WITH_COLOUR_PICTURES_COUNTRIES.each do |country|
            @calculator.current_location = country
            assert @calculator.uk_visa_application_with_colour_pictures?
          end
        end

        should 'be false if current_location is not in UK_VISA_APPLICATION_WITH_COLOUR_PICTURES_COUNTRIES' do
          @calculator.current_location = 'antarctica'
          refute @calculator.uk_visa_application_with_colour_pictures?
        end
      end


      context '#non_uk_visa_application_with_colour_pictures?' do
        setup do
          @calculator = OverseasPassportsCalculator.new
        end

        should 'be true if current_location is in NON_UK_VISA_APPLICATION_WITH_COLOUR_PICTURES_COUNTRIES' do
          OverseasPassportsCalculator::NON_UK_VISA_APPLICATION_WITH_COLOUR_PICTURES_COUNTRIES.each do |country|
            @calculator.current_location = country
            assert @calculator.non_uk_visa_application_with_colour_pictures?
          end
        end

        should 'be false if current_location is not in NON_UK_VISA_APPLICATION_WITH_COLOUR_PICTURES_COUNTRIES' do
          @calculator.current_location = 'antarctica'
          refute @calculator.non_uk_visa_application_with_colour_pictures?
        end
      end

      context '#ineligible_country?' do
        setup do
          @calculator = OverseasPassportsCalculator.new
        end

        should 'be true if current_location is in INELIGIBLE_COUNTRIES' do
          OverseasPassportsCalculator::INELIGIBLE_COUNTRIES.each do |country|
            @calculator.current_location = country
            assert @calculator.ineligible_country?
          end
        end

        should 'be false if current_location is not in INELIGIBLE_COUNTRIES' do
          @calculator.current_location = 'antarctica'
          refute @calculator.ineligible_country?
        end
      end

      context '#apply_in_neighbouring_countries?' do
        setup do
          @calculator = OverseasPassportsCalculator.new
        end

        should 'be true if current_location is in APPLY_IN_NEIGHBOURING_COUNTRIES' do
          OverseasPassportsCalculator::APPLY_IN_NEIGHBOURING_COUNTRIES.each do |country|
            @calculator.current_location = country
            assert @calculator.apply_in_neighbouring_countries?
          end
        end

        should 'be false if current_location is not in APPLY_IN_NEIGHBOURING_COUNTRIES' do
          @calculator.current_location = 'antarctica'
          refute @calculator.apply_in_neighbouring_countries?
        end
      end

      context '#alternate_embassy_location' do
        setup do
          @calculator = OverseasPassportsCalculator.new
        end

        should 'return a alt location if the location is in PassportAndEmbassyDataQuery::ALT_EMBASSIES' do
          PassportAndEmbassyDataQuery::ALT_EMBASSIES.each do |location, alternate_location|
            assert_equal @calculator.alternate_embassy_location(location), alternate_location
          end
        end

        should 'return nil if the location is not in PassportAndEmbassyDataQuery::ALT_EMBASSIES' do
          assert_nil @calculator.alternate_embassy_location('antarctica')
        end
      end

      context '#world_location' do
        setup do
          @calculator = OverseasPassportsCalculator.new
          @calculator.current_location = 'some location'
        end

        context 'given alternate_embassy_location is nil' do
          setup do
            @calculator.stubs(:alternate_embassy_location).returns(nil)
          end

          should 'return the world location for the location' do
            WorldLocation.stubs(:find).with('location').returns('world_location')

            assert_equal 'world_location', @calculator.world_location('location')
          end

          should 'return nil if a world location cannot be found for the location' do
            WorldLocation.stubs(:find).with('location').returns(nil)

            assert_nil @calculator.world_location('location')
          end
        end

        context 'given alternate_embassy_location is present' do
          setup do
            @calculator.stubs(:alternate_embassy_location).returns('another location')
          end

          should 'return the world location for alternate_embassy_location' do
            WorldLocation.stubs(:find).with(@calculator.alternate_embassy_location).returns('world_location')

            assert_equal 'world_location', @calculator.world_location('another location')
          end

          should 'return nil if a world location cannot be found for the alternate_embassy_location' do
            WorldLocation.stubs(:find).with(@calculator.alternate_embassy_location).returns(nil)

            assert_nil @calculator.world_location('another location')
          end
        end

        context '#world_location_name' do
          setup do
            @calculator = OverseasPassportsCalculator.new
          end

          should 'return the name of the world location associated with the location' do
            @calculator.stubs(:world_location).with('location').returns(stub(name: 'world-location-name'))

            assert_equal 'world-location-name', @calculator.world_location_name('location')
          end
        end
      end
    end
  end
end
