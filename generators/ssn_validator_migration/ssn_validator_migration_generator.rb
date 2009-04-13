class SsnValidatorMigrationGenerator < Rails::Generator::Base
  def manifest 
    record do |m|
      #m.directory File.join('db')
      m.migration_template 'migration.rb', 'db/migrate' 
    end 
  end
  
  def file_name
    "create_ssn_validator_tables"
  end
end
