
namespace :ssn_validator do
  desc "Loads the current file from http://www.socialsecurity.gov/employer/ssns/highgroup.txt if it hasn't already been loaded."
  task :update_data => :environment do
    puts SsnHighGroupCode.load_current_high_group_codes_file
  end
  
end