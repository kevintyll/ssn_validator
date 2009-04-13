require File.dirname(__FILE__) + '/test_helper.rb'

ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => ':memory:'

def create_ssn_high_group_codes_table
  silence_stream(STDOUT) do
    ActiveRecord::Schema.define(:version => 1) do
      create_table :ssn_high_group_codes do |t|
        t.date      :as_of
        t.string    :area
        t.string    :group
        t.timestamps
      end
    end
  end
end

class TestSsnHighGroupCode < Test::Unit::TestCase

  def setup
    ActiveRecord::Base.connection.tables.each { |table| ActiveRecord::Base.connection.drop_table(table) }
    create_ssn_high_group_codes_table
  end
  
  def test_should_load_table_with_current_file
    assert_equal(0,SsnHighGroupCode.count)
    SsnHighGroupCode.load_current_high_group_codes_file
    assert SsnHighGroupCode.count > 0
  end

  def test_should_not_load_table_if_as_of_already_in_table
    SsnHighGroupCode.load_current_high_group_codes_file
    assert SsnHighGroupCode.count > 0
    record_count = SsnHighGroupCode.count
    SsnHighGroupCode.load_current_high_group_codes_file
    assert_equal(record_count, SsnHighGroupCode.count)
  end
end
