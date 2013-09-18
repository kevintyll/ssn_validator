module SsnValidator
  # making this an engine gives us the rake task to copy the migrations to your application
  # as well as the rake tasks defined in this gem in your application
  class Engine < ::Rails::Engine
  end
end
