require 'activerecord'
require 'net/http'
class SsnHighGroupCode < ActiveRecord::Base

  ###############
  #class mehtods#
  ###############

  def self.load_historical_high_group_codes_file
    ['Jan','Feb','Mar','Apr','May','June','July','Aug','Sept','Oct','Nov','Dec'].each do |month|
      (1..10).each do |day|
        string_day = day.to_s
        string_day.insert(0,'0') if day < 10
        current_year = Date.today.year
        #(1932..current_year).each do |year|
        [2003].each do |year|
          string_year = year.to_s.last(2)
          ['','corrected'].each do |mod|
            ['ssns','ssnvs'].each do |url_mod|
              file_name = "HG#{month}#{string_day}#{string_year}#{mod}.txt"
              text = Net::HTTP.get(URI.parse("http://www.socialsecurity.gov/employer/#{url_mod}/#{file_name}"))
              puts file_name.inspect
              puts '@@@@@@@@@ found file_name = ' + file_name.inspect unless text.include? 'File Not Found'
            end
          end
          
        end
      end
      
    end
  end

  #Loads the most recent file from http://www.socialsecurity.gov/employer/ssns/highgroup.txt
  def self.load_current_high_group_codes_file
    text = Net::HTTP.get(URI.parse('http://www.socialsecurity.gov/employer/ssns/highgroup.txt'))
    create_records(parse_text(text),extract_as_of_date(text))
  end

  def self.already_loaded?(file_as_of_date)
    self.find_by_as_of(file_as_of_date)
  end
  ###################
  #end class mehtods#
  ###################

  ##################
  #instance mehtods#
  ##################

  

  ######################
  #end instance mehtods#
  ######################
  private

  def self.create_records(area_groups,file_as_of)
    if already_loaded?(file_as_of)
      "File as of #{file_as_of} has already been loaded."
    else
      area_groups.each do |area_group|
        self.create(area_group.merge!(:as_of => file_as_of.to_s(:db)))
      end
      "File as of #{file_as_of} loaded."
    end
  end

  #extract the date from the file in the format mm/dd/yy
  def self.extract_as_of_date(text)
    as_of_start_index = text =~ /\d\d\/\d\d\/\d\d/
    ::Date.new(*::Date._parse($&,true).values_at(:year, :mon, :mday)) unless as_of_start_index.nil?
  end

  #The formatting of the file is a little bit messy. Sometimes tabs are
  #used as delimiters and sometimes spaces are used as delimiters. Also, the asterisks indicating recent changes are not
  #necessary for our purposes
  #Returns an array of hashes.
  def self.parse_text(text)
    text.gsub!('*',' ')
    text.gsub!(/\t/, ' ')
    text_array = text.split(/\n/).compact
    area_groups = []
    text_array.each do |t|
      t.gsub!(/\s+/,' ')
      next if t =~ /[[:alpha:]]/ #skip over the header lines

      if t =~ /\d\d\d \d\d/ #we want the lines with area group pairs
        t.gsub(/\d\d\d \d\d/) do |s|
          area_group = s.split(' ')
          area_groups << {:area => area_group.first, :group => area_group.last}
        end
      end
    end
    return area_groups
  end
end
