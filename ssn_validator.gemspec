spec = Gem::Specification.new do |s|
  s.name = "ssn_validator"
  s.version = "0.1.0"
  s.date = "2009-09-20"
  s.author = "Rafael Lima"
  s.email = "contato@rafael.adm.br"
  s.homepage = "http://rafael.adm.br/opensource/dbdesigner_generators"
  s.platform = Gem::Platform::RUBY
  s.summary = "Generates ActiveRecord Migration files from a DB Designer 4 xml file."
  s.files = ["History.txt",
"Manifest.txt",
"PostInstall.txt",
"README.rdoc",
"Rakefile",
"generators/ssn_validator_migration/templates/migration.rb",
"generators/ssn_validator_migration/ssn_validator_migration_generator.rb",
"lib/ssn_validator.rb",
"script/console",
"script/destroy",
"script/generate"

  ]
  s.test_files = [
    "test/test_helper.rb",
"test/test_ssn_validator.rb",
"test/test_ssn_validator_generator.rb"
  ]
  s.require_paths = ["."]
  s.has_rdoc = true
  #s.extra_rdoc_files = ["README.mkdn"]
  s.add_dependency("activerecord", ["> 0.0.0"])
end