require 'ssn_validator/models/death_master_file_loader'

class DeathMasterFileLoader

  def get_file_from_web
    case @file_path_or_url
    when /MA\d\d\d\d\d\d/ #these are the valid urls I want to mock a response to.
      first_upload = Date.today.beginning_of_month - 2.months #based on the test, we know we are loading the last 3 months
      if @file_path_or_url =~ /MA#{first_upload.strftime("%y%m%d")}/
        return ['A772783123UPDATED                 JUAN                          P030220091101191010']
      elsif @file_path_or_url =~ /MA#{(first_upload + 1.month).strftime("%y%m%d")}/
        return ['A772783456UPDATED                 JUAN                          P030220091101191010']
      elsif @file_path_or_url =~ /MA#{(first_upload + 2.months).strftime("%y%m%d")}/
        return ['A772783789UPDATED                 JUAN                          P030220091101191010']
      end
    else
      uri = URI.parse(@file_path_or_url)

      request = Net::HTTP::Get.new(uri.request_uri)
      request.basic_auth(SsnValidator::Ntis.user_name,SsnValidator::Ntis.password)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.port == 443)
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      
      response = http.request(request)
      
      raise(ArgumentError, "Invalid URL: #{@file_path_or_url}") if response.kind_of?(Net::HTTPNotFound)
      raise(ArgumentError, "Authorization Required: Invalid username or password.  Set the variables SsnValidator::Ntis.user_name and SsnValidator::Ntis.password in your environment.rb file.") if response.kind_of?(Net::HTTPUnauthorized)

      return response.body
    end
  end

end
