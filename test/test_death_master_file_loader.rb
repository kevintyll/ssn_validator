require File.dirname(__FILE__) + '/test_helper.rb'

class TestDeathMasterFileLoader < Test::Unit::TestCase

  def setup
    setup_death_master_file_table
  end

  def test_validations_for_load_file
    exception = assert_raise ArgumentError do
      DeathMasterFileLoader.new(nil,nil)
    end
    assert_equal "path_or_url not specified", exception.message

    exception = assert_raise ArgumentError do
      DeathMasterFileLoader.new('some/path.txt',nil)
    end
    assert_equal "as_of not specified", exception.message

    exception = assert_raise Errno::ENOENT do
      DeathMasterFileLoader.new('some/path.txt','2009-01-01')
    end
    assert_equal "No such file or directory - some/path.txt", exception.message

    exception = assert_raise URI::InvalidURIError do
      DeathMasterFileLoader.new('https://dmf.bad_url.gov/dmldata/monthly/bad_url','2009-01-01')
    end
    assert_equal "the scheme https does not accept registry part: dmf.bad_url.gov (or bad hostname?)", exception.message

    exception = assert_raise ArgumentError do
      DeathMasterFileLoader.new('https://dmf.ntis.gov/bad_url','2009-01-01')
    end
    assert_equal "Invalid URL: https://dmf.ntis.gov/bad_url", exception.message

    exception = assert_raise ArgumentError do
      DeathMasterFileLoader.new('https://dmf.ntis.gov/dmldata/monthly/bad_url','2009-01-01')
    end
    assert_equal "Authorization Required: Invalid username or password.  Set the variables SsnValidator::Ntis.user_name and SsnValidator::Ntis.password in your environment.rb file.", exception.message
  end

  def test_should_load_table_from_file
    assert_equal(0,DeathMasterFile.count)
    DeathMasterFileLoader.new(File.dirname(__FILE__) + '/files/test_dmf_initial_load.txt','2009-01-01').load_file
    assert DeathMasterFile.count == 5

    #load update file
    #update file adds 1 record, deletes 2 records, and changes 2 records
    DeathMasterFileLoader.new(File.dirname(__FILE__) + '/files/test_dmf_update_load.txt','2009-02-01').load_file
    assert DeathMasterFile.count == 4
    assert 1, DeathMasterFile.count(:conditions => {:last_name => 'NEW'})
    assert 2, DeathMasterFile.count(:conditions => {:last_name => 'CHANGED'})
  end

  def test_should_not_load_table_if_as_of_already_in_table_for_load_file
    DeathMasterFileLoader.new(File.dirname(__FILE__) + '/files/test_dmf_initial_load.txt','2009-01-01').load_file
    assert DeathMasterFile.count > 0
    record_count = DeathMasterFile.count
    
    exception = assert_raise ArgumentError do
      DeathMasterFileLoader.new(File.dirname(__FILE__) + '/files/test_dmf_update_load.txt','2008-01-01').load_file
    end
    assert_equal "A more recent file has already been processed.  DB as_of date 2009-01-01", exception.message

    assert_equal(record_count, DeathMasterFile.count)
  end

  def test_should_load_all_unloaded_updates
    #initial load was 3 months ago
    initial_run = Date.today.beginning_of_month - 3.months
    DeathMasterFileLoader.new(File.dirname(__FILE__) + '/files/test_dmf_initial_load.txt',initial_run.strftime('%Y-%m-%d')).load_file
    assert DeathMasterFile.count == 5

    #this will load the last 3 months of files
    #this has been mocked, not really hitting the web site for this
    DeathMasterFileLoader.load_update_files_from_web
    assert DeathMasterFile.count == 8
    assert DeathMasterFile.find_by_as_of(initial_run.to_s(:db))
    assert DeathMasterFile.find_by_as_of((initial_run += 1.month).to_s(:db))
    assert DeathMasterFile.find_by_as_of((initial_run += 1.month).to_s(:db))
    assert DeathMasterFile.find_by_as_of((initial_run += 1.month).to_s(:db))
  end

  def test_should_load_file_with_funky_data
    DeathMasterFileLoader.new(File.dirname(__FILE__) + '/files/test_dmf_funky_data_load.txt','2009-04-01').load_file
    assert DeathMasterFile.count == 6
    DeathMasterFile.find(:all).each do |dmf|
      # this is more of an issue with the bulk mysql load, but since, I'm using
      #sqlight3 for it's in memory db, I can't test the mysql load.
      assert_not_nil dmf.as_of
    end
  end

  def test_should_create_csv_file_for_mysql_import
    #since, I'm using sqlight3 for it's in memory db, I can't test the mysql load
    #but I can test the csv file creation.
    loader = DeathMasterFileLoader.new(File.dirname(__FILE__) + '/files/test_dmf_funky_data_load.txt','2009-11-30')
    csv = loader.create_csv_file #this method was created in the mock only to call the private convert_file_to_csv method
    correctly_formatted_csv = File.open(File.dirname(__FILE__) + '/files/valid_csv_from_funky_data_file.txt')
    #csv is open and at the end of the file, so we need to reopen it so we can read the lines.
    generated_file = File.open(csv.path).readlines
    #compare the values of each csv line, with the correctly formated "control file"
    correctly_formatted_csv.each_with_index do |line,i|
      csv_line = generated_file[i]
      correctly_formatted_record_array = line.split(',')
      csv_record_array = csv_line.split(',')
      comparable_value_indices = (0..11).to_a << 14 #skip indices 12 and 13, they are the created_at and updated_at fields, they will never match.
      comparable_value_indices.each do |i|
        assert_equal correctly_formatted_record_array[i], csv_record_array[i]
      end
    end
  end

end
