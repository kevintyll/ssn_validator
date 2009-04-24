$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
  
require 'ssn_validator/models/ssn_high_group_code'
require 'ssn_validator/models/ssn_high_group_code_loader'
require 'ssn_validator/models/ssn_validator'
require 'ssn_validator/models/death_master_file'
require 'ssn_validator/models/death_master_file_loader'
require 'rake'

# Load rake file
import "#{File.dirname(__FILE__)}/tasks/ssn_validator.rake"
