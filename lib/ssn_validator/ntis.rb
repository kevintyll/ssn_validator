module SsnValidator
  class Ntis
    @@user_name = 'REPLACE WITH YOUR dmf.ntis.gov USER NAME'
    cattr_accessor :user_name
    
    @@password = 'REPLACE WITH YOUR dmf.ntis.gov PASSWORD'
    cattr_accessor :password
  end
end
