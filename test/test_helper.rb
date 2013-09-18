# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'

require File.expand_path('../dummy/config/environment.rb',  __FILE__)
require 'rails/test_help'

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Load fixtures from the engine
if ActiveSupport::TestCase.method_defined?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path('../fixtures', __FILE__)
end


#
#
#
#
#require 'rubygems'
#require 'test/unit'
#require 'mocks/test/death_master_file_loader'
#
#$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
#$LOAD_PATH.unshift(File.dirname(__FILE__))
#require 'ssn_validator'
#
ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => ':memory:'

def setup_high_group_codes_table
  ActiveRecord::Base.connection.tables.each { |table| ActiveRecord::Base.connection.drop_table(table) }
  create_ssn_high_group_codes_table
end

def setup_death_master_file_table
  ActiveRecord::Base.connection.tables.each { |table| ActiveRecord::Base.connection.drop_table(table) }
  create_death_master_file_table
end

private #====================================================================

def create_ssn_high_group_codes_table
  silence_stream(STDOUT) do
    ActiveRecord::Schema.define(:version => 1) do
      create_table :ssn_validator_ssn_high_group_codes do |t|
        t.date      :as_of
        t.string    :area
        t.string    :group
        t.timestamps
      end
      add_index :ssn_validator_ssn_high_group_codes, :area, name: 'idx_area'
      add_index :ssn_validator_ssn_high_group_codes, [:area, :as_of], name: 'idx_area_as_of'
    end
  end
end

def create_death_master_file_table
  silence_stream(STDOUT) do
    ActiveRecord::Schema.define(:version => 1) do
      create_table :ssn_validator_death_master_files do |t|
        t.string :social_security_number
        t.string  :last_name
        t.string  :name_suffix
        t.string :first_name
        t.string :middle_name
        t.string :verify_proof_code
        t.date  :date_of_death
        t.date  :date_of_birth
        t.string  :state_of_residence
        t.string :last_known_zip_residence
        t.string :last_known_zip_payment
        t.timestamps
        t.date :as_of
      end
      add_index :ssn_validator_death_master_files, :social_security_number, unique: true, name: 'idx_ssn'
      add_index :ssn_validator_death_master_files, :as_of, name: 'idx_as_of'
    end
  end
end