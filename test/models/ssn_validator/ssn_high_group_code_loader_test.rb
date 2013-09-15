require 'test_helper'

module SsnValidator
  class SsnHighGroupCodeLoaderTest < ActiveSupport::TestCase

    def test_should_load_table_with_current_file
      assert_equal(0, SsnHighGroupCode.count)
      SsnHighGroupCodeLoader.load_current_high_group_codes_file
      assert SsnHighGroupCode.count > 0
    end

    def test_should_not_load_table_if_as_of_already_in_table
      SsnHighGroupCodeLoader.load_current_high_group_codes_file
      assert SsnHighGroupCode.count > 0
      record_count = SsnHighGroupCode.count
      SsnHighGroupCodeLoader.load_current_high_group_codes_file
      assert_equal(record_count, SsnHighGroupCode.count)
    end

    def setup
      setup_high_group_codes_table
    end
  end
end
