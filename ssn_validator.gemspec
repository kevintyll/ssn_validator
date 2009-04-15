spec = Gem::Specification.new do |s|
  s.name = "ssn_validator"
  s.version = "0.1.2"
  s.date = "2009-04-13"
  s.author = "Kevin Tyll"
  s.email = "kevintyll@gmail.com"
  s.platform = Gem::Platform::RUBY
  s.summary = "Validates whether an SSN has likely been issued or not."
  s.files = ["History.txt",
            "Manifest.txt",
            "PostInstall.txt",
            "README.rdoc",
            "Rakefile",
            "generators/ssn_validator_migration/templates/migration.rb",
            "generators/ssn_validator_migration/ssn_validator_migration_generator.rb",
            "lib/ssn_validator/models/ssn_high_group_code.rb",
            "lib/ssn_validator/models/ssn_validator.rb",
            "lib/ssn_validator.rb",
            "lib/tasks/ssn_validator.rake",
            "script/console",
            "script/destroy",
            "script/generate",
            "test/test_helper.rb",
            "test/test_ssn_validator.rb",
            "test/test_ssn_high_group_code.rb"

  ]
  s.test_files = [
    "test/test_helper.rb",
    "test/test_ssn_validator.rb",
    "test/test_ssn_high_group_code.rb"
  ]
  s.require_paths = ["."]
  s.has_rdoc = true
  #s.extra_rdoc_files = ["README.mkdn"]
  s.add_dependency("activerecord", ["> 2.0.0"])
end