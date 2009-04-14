require 'stringio'
require 'test/unit'
require File.dirname(__FILE__) + '/../lib/ssn_validator'

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

      add_index :ssn_high_group_codes, [:area]
      add_index :ssn_high_group_codes, [:area, :as_of]
    end
  end
end

def setup_high_group_codes_table
	ActiveRecord::Base.connection.tables.each { |table| ActiveRecord::Base.connection.drop_table(table) }
  create_ssn_high_group_codes_table
end