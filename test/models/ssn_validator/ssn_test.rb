require 'test_helper'

module SsnValidator
  class SsnTest < ActiveSupport::TestCase

    KNOWN_DUMMY_SSNS = %w(078051120 111111111 123456789 219099999 999999999)
    MISSPLACED_HYPHEN_SSNS = %w(1-2-3456789 12-345678-9 123-4-56789 123-456789 1234567-89 12-345-6789 12345-6789 1234-5-6789)
    INVALID_LENGTH_SSNS = %w(1 12 123 1234 12345 123456 1234567 13245678 1234567890)
    NONDIGIT_SSNS = %w(078051a20 078F51120 78051#20 051,20 078051m20)
    INVALID_ZEROS_SSNS = %w(166-00-1234 073-96-0000)
    GROUPS_NOT_ASSIGNED_TO_AREA_SSNS = %w(752991234 755971234 762991254)
    AREA_NOT_ASSIGNED_SSNS = %w(666991234)

    VALID_SSNS = %w(001021234 161-84-9876 223981111)
    VALID_INTEGER_SSNS = [115941234, 161849876, 223981111]

    def test_ssn_validations
      KNOWN_DUMMY_SSNS.each do |ssn|
        validator = SsnValidator::Ssn.new(ssn)
        assert !validator.valid?
        assert validator.errors.include?('Known dummy SSN.'), "Errors: #{validator.errors}"
      end

      MISSPLACED_HYPHEN_SSNS.each do |ssn|
        validator = SsnValidator::Ssn.new(ssn)
        assert !validator.valid?
        assert validator.errors.include?('Hyphen misplaced.'), "Errors: #{validator.errors}"
      end

      INVALID_LENGTH_SSNS.each do |ssn|
        validator = SsnValidator::Ssn.new(ssn)
        assert !validator.valid?
        assert validator.errors.include?('SSN not 9 digits long.'), "Errors: #{validator.errors}"
      end

      NONDIGIT_SSNS.each do |ssn|
        validator = SsnValidator::Ssn.new(ssn)
        assert !validator.valid?
        assert validator.errors.include?('Non-digit found.'), "Errors: #{validator.errors}"
      end

      INVALID_ZEROS_SSNS.each do |ssn|
        validator = SsnValidator::Ssn.new(ssn)
        assert !validator.valid?
        assert validator.errors.include?('Invalid group or serial number.'), "Errors: #{validator.errors}"
      end

      AREA_NOT_ASSIGNED_SSNS.each do |ssn|
        validator = SsnValidator::Ssn.new(ssn)
        assert !validator.valid?
        assert validator.errors.include?("Area '#{validator.area}' has not been assigned."), "Errors: #{validator.errors}"
      end

      GROUPS_NOT_ASSIGNED_TO_AREA_SSNS.each do |ssn|
        validator = SsnValidator::Ssn.new(ssn)
        assert !validator.valid?
        assert validator.errors.include?("Group '#{validator.group}' has not been assigned yet for area '#{validator.area}'"), "Errors: #{validator.errors}"
      end

      (VALID_SSNS + VALID_INTEGER_SSNS).each do |ssn|
        validator = SsnValidator::Ssn.new(ssn)
        assert validator.valid?, "Errors: #{validator.errors}"
      end

    end

    def test_death_master_file_hit
      create_death_master_file_table
      DeathMasterFileLoader.new(File.dirname(__FILE__) + '/../../files/test_dmf_initial_load.txt','2009-01-01').load_file

      validator = SsnValidator::Ssn.new('772781978') # ssn from file
      assert DeathMasterFile, validator.death_master_file_record.class
      assert validator.death_master_file_hit?

      validator = SsnValidator::Ssn.new('666781978') # ssn not in file
      assert_nil validator.death_master_file_record
      assert !validator.death_master_file_hit?
    end

    def test_death_master_file_hit_with_date
      create_death_master_file_table
      DeathMasterFileLoader.new(File.dirname(__FILE__) + '/../../files/test_dmf_initial_load.txt','2009-01-01').load_file

      ssn = SsnValidator::Ssn.new('666781978', (Date.today - 5))
      assert_equal (Date.today - 5), ssn.validation_date

      ssn = SsnValidator::Ssn.new('666781978', (Date.today - 5).to_s)
      assert_equal (Date.today - 5), ssn.validation_date

      ssn = SsnValidator::Ssn.new('666781978', 'not a date')
      assert_equal Date.today, ssn.validation_date

      validator = SsnValidator::Ssn.new('772781978', '2008-01-01') # ssn from file with DMF date 2009
      puts validator.inspect
      assert !validator.death_master_file_hit?

      validator = SsnValidator::Ssn.new('666781978', '2011-01-01') # ssn not in file
      assert_nil validator.death_master_file_record
      assert !validator.death_master_file_hit?
    end

    def setup
      setup_high_group_codes_table
      SsnValidator::SsnHighGroupCodeLoader.load_current_high_group_codes_file
    end

  end
end
