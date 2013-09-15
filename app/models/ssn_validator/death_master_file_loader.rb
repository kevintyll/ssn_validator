require 'net/http'
require 'net/https'
require 'ssn_validator/ntis'

module SsnValidator
  class DeathMasterFileLoader

    # path_or_url is the full path to the file to load on disk, or the url of an update file.
    # as_of is a string in the format YYYY-MM-DD for which the file data is accurate.
    def initialize(path_or_url, file_as_of)
      @file_path_or_url = path_or_url
      @file_as_of = file_as_of
      valid? { |status| yield status if block_given? }
    end

    def valid?
      raise(ArgumentError, 'path_or_url not specified') unless @file_path_or_url
      raise(ArgumentError, 'as_of not specified') unless @file_as_of
      max_as_of = DeathMasterFile.maximum(:as_of)
      raise(ArgumentError, "A more recent file has already been processed.  DB as_of date #{max_as_of}") if  max_as_of && (max_as_of >= @file_as_of.to_date)
      if File.exists?(@file_path_or_url)
        @download_file = File.open(@file_path_or_url)
      elsif URI.parse(@file_path_or_url).kind_of?(URI::HTTP)
        @download_file = File.open(get_file_from_web { |status| yield status if block_given? })
      else
        raise(Errno::ENOENT, @file_path_or_url)
      end
    end

    def load_file
      if ActiveRecord::Base.connection.instance_values['config'][:adapter].to_s.match(/mysql|jdbc/)
        puts 'Converting file to csv format for Mysql import.  This could take several minutes.'
        yield 'Converting file to csv format for Mysql import.  This could take several minutes.' if block_given?
        csv_file = convert_file_to_csv { |status| yield status if block_given? }
        bulk_mysql_update(csv_file) { |status| yield status if block_given? }
      else
        active_record_file_load { |status| yield status if block_given? }
      end
    end

    def get_file_from_web
      return mock_get_file_from_web if Rails.env.test?
      uri = URI.parse(@file_path_or_url)
      request = Net::HTTP::Get.new(uri.request_uri)
      request.basic_auth(SsnValidator::Ntis.user_name, SsnValidator::Ntis.password)
      proxy_addr, proxy_port = ENV['http_proxy'].gsub('http://', '').split(/:/) if ENV['http_proxy']
      proxy_user, proxy_pass = uri.userinfo.split(/:/) if uri.userinfo
      http = Net::HTTP::Proxy(proxy_addr, proxy_port, proxy_user, proxy_pass).new(uri.host, uri.port)
      http.use_ssl = (uri.port == 443)
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      csv_file = Tempfile.new(@file_path_or_url.split('/').last) # create temp file for the raw file.
      http.request(request) do |res|
        raise(ArgumentError, "Invalid URL: #{@file_path_or_url}") if res.kind_of?(Net::HTTPNotFound)
        raise(ArgumentError, 'Authorization Required: Invalid username or password.  Set the variables SsnValidator::Ntis.user_name and SsnValidator::Ntis.password in your environment.rb file.') if res.kind_of?(Net::HTTPUnauthorized)
        size, total = 0, res.header['Content-Length'].to_i
        res.read_body do |chunk|
          size += chunk.size
          csv_file.write chunk
          puts '%d%% done (%d of %d)' % [(size * 100) / total, size, total]
          yield('%d%% done (%d of %d)' % [(size * 100) / total, size, total]) if block_given?
        end
      end
      csv_file.rewind
      csv_file.path
    end

    def mock_get_file_from_web
      if @file_path_or_url.match(/MA\d\d\d\d\d\d/) # These are the valid urls I want to mock a response to.
        first_upload = Date.today.beginning_of_month - 2.months #based on the test, we know we are loading the last 3 months
        if @file_path_or_url =~ /MA#{first_upload.strftime('%y%m%d')}/
          csv_contents = 'A772783123UPDATED                 JUAN                          P030220091101191010'
        elsif @file_path_or_url =~ /MA#{(first_upload + 1.month).strftime('%y%m%d')}/
          csv_contents = 'A772783456UPDATED                 JUAN                          P030220091101191010'
        elsif @file_path_or_url =~ /MA#{(first_upload + 2.months).strftime('%y%m%d')}/
          csv_contents = 'A772783789UPDATED                 JUAN                          P030220091101191010'
        end
        csv_file = Tempfile.new('mock')
        csv_file.puts csv_contents
        csv_file.rewind
        csv_file.path
      else
        uri = URI.parse(@file_path_or_url)
        request = Net::HTTP::Get.new(uri.request_uri)
        request.basic_auth(SsnValidator::Ntis.user_name, SsnValidator::Ntis.password)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.port == 443)
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        response = http.request(request)
        raise(ArgumentError, "Invalid URL: #{@file_path_or_url}") if response.kind_of?(Net::HTTPNotFound)
        raise(ArgumentError, 'Authorization Required: Invalid username or password.  Set the variables SsnValidator::Ntis.user_name and SsnValidator::Ntis.password in your environment.rb file.') if response.kind_of?(Net::HTTPUnauthorized)
        response.body
      end
    end

    # Loads all the update files from dmf.ntis.gov.
    # It starts with the last file loaded, and loads each
    # missing file in sequence up to the current file.
    def self.load_update_files_from_web
      max_as_of = DeathMasterFile.maximum(:as_of)
      run_file_date = max_as_of.beginning_of_month.next_month
      last_file_date = Date.today.beginning_of_month
      while run_file_date <= last_file_date
        url = "https://dmf.ntis.gov/dmldata/monthly/MA#{run_file_date.strftime('%y%m%d')}"
        puts "Loading file #{url}"
        yield "Loading file #{url}" if block_given?
        dmf = DeathMasterFileLoader.new(url, run_file_date.strftime('%Y-%m-%d')) { |status| yield status if block_given? }
        dmf.load_file do |status|
          yield status if block_given?
        end
        run_file_date += 1.month
      end
    end

    # Processes 28 million rows in 23 minutes. Input file 2.6GB output: 2.9GB.
    # Used to convert a packed fixed-length file into csv for mysql import.
    def convert_file_to_csv
      csv_file = Tempfile.new('dmf') # create temp file for converted csv formmat.
      start = Time.now
      timenow = start.to_s(:db)
      @delete_ssns = []
      @download_file.each_with_index do |line, i|
        action = record_action(line)
        attributes_hash = text_to_hash(line)
        if  action == 'D'
          #keep track of all the records to delete.  We'll delete at the end all at once.
          @delete_ssns << attributes_hash[:social_security_number]
        else
          # empty field for id to be generated by mysql.
          newline = "``," +
              # social_security_number
              "`#{attributes_hash[:social_security_number]}`," +
              # last_name
              "`#{attributes_hash[:last_name]}`," +
              # name_suffix
              "`#{attributes_hash[:name_suffix]}`," +
              # first_name
              "`#{attributes_hash[:first_name]}`," +
              # middle_name
              "`#{attributes_hash[:middle_name]}`," +
              # verify_proof_code
              "`#{attributes_hash[:verify_proof_code]}`," +
              # date_of_death - need YYYY-MM-DD.
              "`#{attributes_hash[:date_of_death]}`," +
              # date_of_birth - need YYYY-MM-DD.
              "`#{attributes_hash[:date_of_birth]}`," +
              # state_of_residence - must be code between 01 and 65 or else nil.
              "`#{attributes_hash[:state_of_residence]}`," +
              # last_known_zip_residence
              "`#{attributes_hash[:last_known_zip_residence]}`," +
              # last_known_zip_payment
              "`#{attributes_hash[:last_known_zip_payment]}`," +
              # created_at
              "`#{timenow}`," +
              # updated_at
              "`#{timenow}`," +
              # as_of
              "`#{attributes_hash[:as_of]}`" +"\n"
          csv_file.syswrite newline
          if (i % 25000 == 0) && (i > 0)
            puts "#{i} records processed."
            yield "#{i} records processed." if block_given?
          end
        end
      end
      puts "File conversion ran for #{(Time.now - start) / 60.0} minutes."
      yield "File conversion ran for #{(Time.now - start) / 60.0} minutes." if block_given?
      csv_file
    end

    private #=============================================================================

    # Uses active record to load the data.
    # The benefit is it will work on any database.
    # The downside is it's really slow.
    def active_record_file_load
      puts 'Importing file into database. This could take many minutes.'
      yield 'Importing file into database. This could take many minutes.' if block_given?
      @download_file.each_with_index do |line, i|
        action = record_action(line)
        attributes_hash = text_to_hash(line)
        if  action == 'D'
          DeathMasterFile.destroy_all(['social_security_number = ?', attributes_hash[:social_security_number]])
        else
          # empty field for id to be generated by mysql.
          #        record_hash = {
          #          :as_of => @file_as_of.to_date.to_s(:db),
          #          :social_security_number => parse_record(line,:social_security_number),
          #          :last_name => parse_record(line,:last_name),
          #          :name_suffix => parse_record(line,:name_suffix),
          #          :first_name => parse_record(line,:first_name),
          #          :middle_name => parse_record(line,:middle_name),
          #          :verify_proof_code => parse_record(line,:verify_proof_code),
          #          :date_of_death => parse_record(line,:date_of_death),
          #          :date_of_birth => parse_record(line,:date_of_birth),
          #          # - must be code between 01 and 65 or else nil.
          #          :state_of_residence=> parse_record(line,:state_of_residence=),
          #          :last_known_zip_residence => parse_record(line,:last_known_zip_residence),
          #          :last_known_zip_payment => parse_record(line,:last_known_zip_payment)
          #        }
          case action
            when '', nil, ' '
              #the initial file leaves this field blank
              DeathMasterFile.create(attributes_hash)
            else
              dmf = DeathMasterFile.find_by_social_security_number(attributes_hash[:social_security_number])
              if dmf
                #a record already exists, update this record
                dmf.update_attributes(attributes_hash)
              else
                #create a new record
                DeathMasterFile.create(attributes_hash)
              end
          end
        end
        if (i % 2500 == 0) && (i > 0)
          puts "#{i} records processed."
          yield "#{i} records processed." if block_given?
        end
      end
      puts 'Import complete.'
      yield 'Import complete.' if block_given?
    end

    # For mysql, use:
    # LOAD DATA LOCAL INFILE 'ssdm1.csv' INTO TABLE death_master_files FIELDS TERMINATED BY ',' ENCLOSED BY "'" LINES TERMINATED BY '\n';
    # This is a much faster way of loading large amounts of data into mysql.  For information on the LOAD DATA command
    # see http://dev.mysql.com/doc/refman/5.1/en/load-data.html
    def bulk_mysql_update(csv_file)
      puts 'Importing into Mysql...'
      yield 'Importing into Mysql...' if block_given?
      #delete all the 'D' records
      DeathMasterFile.delete_all(:social_security_number => @delete_ssns)
      #This will insert new records, and replace records with existing ssns.
      #This only works because there is a unique index on social_security_number.
      mysql_command = <<-TEXT
    LOAD DATA LOCAL INFILE '#{csv_file.path}' REPLACE INTO TABLE death_master_files FIELDS TERMINATED BY ',' ENCLOSED BY "`" LINES TERMINATED BY '\n';
      TEXT
      DeathMasterFile.connection.execute(mysql_command)
      puts 'Mysql import complete.'
      yield 'Mysql import complete.' if block_given?
    end

    def record_action(line)
      line[0, 1].to_s.strip
    end

    def text_to_hash(line)
      {:as_of => @file_as_of.to_date.to_s(:db),
       :social_security_number => line[1, 9].to_s.strip,
       :last_name => line[10, 20].to_s.strip,
       :name_suffix => line[30, 4].to_s.strip,
       :first_name => line[34, 15].to_s.strip,
       :middle_name => line[49, 15].to_s.strip,
       :verify_proof_code => line[64, 1].to_s.strip,
       :date_of_death => (Date.strptime(line[65, 8].to_s.strip, '%m%d%Y') rescue nil),
       :date_of_birth => (Date.strptime(line[73, 8].to_s.strip, '%m%d%Y') rescue nil),
       # - must be code between 01 and 65 or else nil.
       :state_of_residence => (line[81, 2].to_s.strip.between?('01', '65') ? line[81, 2].to_s.strip : nil),
       :last_known_zip_residence => line[83, 5].to_s.strip,
       :last_known_zip_payment => line[88, 5].to_s.strip}
    end

  end
end