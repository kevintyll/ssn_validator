
require 'net/http'
class SsnHighGroupCodeLoader
  def self.load_all_high_group_codes_files
    months = ['Jan','Feb','Mar','Apr','May','June','July','Aug',['Sept','Sep'],'Oct','Nov','Dec']
    run_file_date = SsnHighGroupCode.maximum(:as_of)
    run_file_date = run_file_date ? run_file_date.next_month.beginning_of_month.to_date : Date.new(2003,11,01)
    last_file_date = Date.today.beginning_of_month
    while run_file_date <= last_file_date
      file_processed = false
      run_file_month_variants = Array(months[run_file_date.month - 1])
      run_file_year =  run_file_date.year
      run_file_month_variants.each do |run_file_month|
        break if file_processed
        ['','corrected'].each do |mod|
          break if file_processed
          ['ssns','ssnvs'].each do |url_mod|
            break if file_processed
            (1..Date.today.day).each do |day|
              string_day = day.to_s
              string_day.insert(0,'0') if day < 10
              string_year = run_file_year.to_s.last(2)
              file_name = "HG#{run_file_month}#{string_day}#{string_year}#{mod}.txt"
              text = Net::HTTP.get(URI.parse("http://www.socialsecurity.gov/employer/#{url_mod}/#{file_name}"))
              unless text.include? 'File Not Found'
                create_records(parse_text(text),extract_as_of_date(text))
                file_processed = true
                break
              end
            end
          end
        end
      end
      run_file_date = run_file_date.next_month
    end
  end

  #Loads the most recent file from http://www.socialsecurity.gov/employer/ssns/highgroup.txt
  def self.load_current_high_group_codes_file
    text = Net::HTTP.get(URI.parse('http://www.socialsecurity.gov/employer/ssns/highgroup.txt'))
    create_records(parse_text(text),extract_as_of_date(text))
  end


  private

  def self.already_loaded?(file_as_of_date)
    SsnHighGroupCode.find_by_as_of(file_as_of_date)
  end

  def self.create_records(area_groups,file_as_of)
    if already_loaded?(file_as_of)
      puts "File as of #{file_as_of} has already been loaded."
    else
      area_groups.each do |area_group|
        SsnHighGroupCode.create(area_group.merge!(:as_of => file_as_of.to_s(:db)))
      end
      puts "File as of #{file_as_of} loaded."
    end
  end

  #extract the date from the file in the format mm/dd/yy
  def self.extract_as_of_date(text)
    as_of_start_index = text =~ /\d\d\/\d\d\/\d\d/
    Date.strptime($&,'%m/%d/%y') unless as_of_start_index.nil?
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
