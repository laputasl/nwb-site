namespace :db do
  DATA_DIRECTORY = File.dirname(__FILE__) + "/../../test/fixtures"
  namespace :sample_data do
    TABLES = %w(gwo_tests)
    MIN_ID = 1000    # Starting user id for the sample data

    desc "Load sample data"
    task :load => :environment do |t|
      class_name = nil    # let Rails to figure out the class.
      TABLES.each do |table_name|
        fixture = Fixtures.new(ActiveRecord::Base.connection,
                               table_name, class_name,
                               File.join(DATA_DIRECTORY, table_name.to_s))
        fixture.insert_fixtures
        puts "Loaded data from #{table_name}.yml"
      end
    end

    desc "Remove sample data"
    task :delete => :environment do |t|
      GwoTest.delete_all("id      >= #{MIN_ID}")
    end
  end
end
