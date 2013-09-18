$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'ssn_validator/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'ssn_validator'
  s.version     = SsnValidator::VERSION
  s.authors     = ['Kevin Tyll']
  s.email       = ['kevintyll@gmail.com']
  s.homepage    = 'http://kevintyll.git.com/ssn_validator'
  s.summary     = 'Validates whether an SSN has likely been issued or not.'
  s.description = 'Validates whether an SSN has likely been issued or not.'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'rails', '>= 3.0.0'

  s.add_development_dependency 'sqlite3'
end