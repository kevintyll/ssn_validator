Rails.application.routes.draw do

  mount SsnValidator::Engine => '/ssn_validator'

end