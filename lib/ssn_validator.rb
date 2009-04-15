$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
  
require 'ssn_validator/models/ssn_high_group_code'
require 'ssn_validator/models/ssn_validator'
require 'rake'

# Load rake file
import "#{File.dirname(__FILE__)}/tasks/ssn_validator.rake"

module SsnValidator
  VERSION = '0.1.1'
end