require 'ssn_validator/engine'

module SsnValidator

  class Engine < Rails::Engine
    isolate_namespace SsnValidator
  end

end