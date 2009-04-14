require File.dirname(__FILE__) + '/test_helper.rb'

class TestSsnValidator < Test::Unit::TestCase

  KNOWN_DUMMY_SSNS = %w(078051120 111111111 123456789 219099999 999999999)
  MISSPLACED_HYPHEN_SSNS = %w(1-2-3456789 12-345678-9 123-4-56789 123-456789 1234567-89 12-345-6789 12345-6789 1234-5-6789)
  INVALID_LENGTH_SSNS = %w(1 12 123 1234 12345 123456 1234567 13245678 1234567890)
  NONDIGIT_SSNS = %w(078051a20 078F51120 78051#20 051,20 078051m20)
  INVALID_ZEROS_SSNS = %w(166-00-1234 073-96-0000)
  GROUPS_NOT_ASSIGNED_TO_AREA_SSNS = %w(752991234 755971234 762991254)

  VALID_SSNS = %w(001021234 161-84-9876 223981111)
  VALID_INTEGER_SSNS = [115941234, 161849876, 223981111]
  
  def setup
    setup_high_group_codes_table
    SsnHighGroupCode.load_current_high_group_codes_file
  end
  
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

end
