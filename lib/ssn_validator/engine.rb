module SsnValidator
  class Engine < ::Rails::Engine
    isolate_namespace SsnValidator if Rails.version >= '3.1'
  end
end
