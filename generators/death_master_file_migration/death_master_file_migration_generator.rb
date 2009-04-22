class DeathMasterFileMigrationGenerator < Rails::Generator::Base
  def manifest 
    record do |m|
      #m.directory File.join('db')
      m.migration_template 'migration.rb', 'db/migrate' 
    end 
  end
  
  def file_name
    "create_death_master_file_table"
  end
end
