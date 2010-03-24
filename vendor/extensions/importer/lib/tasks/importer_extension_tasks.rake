namespace :spree do
  namespace :extensions do
    namespace :importer do

      desc "Imports stuff"
      task :import => :environment do
        require 'rubygems'
        require 'fastercsv'

        def import_product_meta(code)
          store = Store.find_by_code code
          FasterCSV.foreach("#{RAILS_ROOT}/vendor/extensions/importer/data/#{code}-meta.csv", :headers => true ) do |row|
            product = Product.find_by_legacy_id_and_store_id row[0].to_i, store.id

            if product.nil?
              puts "Missing  #{store.code}: #{row[0]}"
            else
              product.page_title = row[1]
              product.meta_description = row[2]
              product.meta_keywords = row[3]
              product.save!
              #puts product.name
            end
          end
        end

        import_product_meta("pwb")
        import_product_meta("nwb")

      end








      desc "Copies public assets of the Importer to the instance public/ directory."
      task :update => :environment do
        is_svn_git_or_dir = proc {|path| path =~ /\.svn/ || path =~ /\.git/ || File.directory?(path) }
        Dir[ImporterExtension.root + "/public/**/*"].reject(&is_svn_git_or_dir).each do |file|
          path = file.sub(ImporterExtension.root, '')
          directory = File.dirname(path)
          puts "Copying #{path}..."
          mkdir_p RAILS_ROOT + directory
          cp file, RAILS_ROOT + path
        end
      end
    end
  end
end