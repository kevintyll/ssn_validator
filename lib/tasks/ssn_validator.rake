
namespace :ssn_validator do
  desc "Loads the current file from http://www.socialsecurity.gov/employer/ssns/highgroup.txt if it hasn't already been loaded."
  task :update_data => :environment do
    SsnHighGroupCodeLoader.load_all_high_group_codes_files
  end

  namespace :death_master_file do
    desc "Loads a death master file.  Specify the path of the file: PATH=path.  Specify the date of the data: AS_OF=YYYY-MM-DD.  Optimized for Mysql databases."
    task :load_file => :environment do
      if ENV["PATH"] && ENV["AS_OF"]
        DeathMasterFileLoader.new(ENV["PATH"],ENV["AS_OF"]).load_file
      else
        puts "You must specify the PATH and AS_OF variables:  rake ssn_validator:death_master_file:load_file PATH='path/to/file' AS_OF='2009-03-01'"
      end
    end

    desc "Determines the most recent file that has been loaded, and loads all subsequent files in order from the dmf.ntis.gov website.  Optimized for Mysql databases."
    task :update_data => :environment do
      DeathMasterFileLoader.load_update_files_from_web
    end
  end

end