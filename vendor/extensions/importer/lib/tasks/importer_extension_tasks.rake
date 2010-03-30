namespace :spree do
  namespace :extensions do
    namespace :importer do

      desc "Imports stuff"
      task :import => :environment do
        require 'rubygems'
        require 'fastercsv'

        LineItem.class_eval do
          attr_accessible :price
        end

        Creditcard.class_eval do
          def create_payment_profile
          end
        end

        Order.protected_attributes.clear

        Order.class_eval do
          def create_shipment
          end

          def create_tax_charge
          end
        end

        ActionMailer::Base.class_eval do
          def self.method_missing(method_symbol, *parameters) #:nodoc:
            false
          end
        end

        ETOrderObserver.class_eval do
          def after_update(order)
            false
          end

          def after_hold(order, transition)
            false
          end

          def after_ship(order, transition)
            false
          end
        end

        ETUserObserver.class_eval do
           def after_create(user)
             false
           end

           def after_create(user)
             false
           end
        end

        SiteShipmentObserver.class_eval do
          def after_transmit(shipment, transition)
            false
          end
        end

        Spree::Config.set :exact_target_user => "blakblak"
        Spree::Config.set :exact_target_password => "notapassword"

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

        # import_product_meta("pwb")
        # import_product_meta("nwb")


        def import_users(code)
          store = Store.find_by_code code
          states = {}
          FasterCSV.foreach("#{RAILS_ROOT}/vendor/extensions/importer/data/#{code}-provinces.csv" ) do |row|
            states[row[0]] = row
          end

          countries = {}
          FasterCSV.foreach("#{RAILS_ROOT}/vendor/extensions/importer/data/#{code}-countries.csv" ) do |row|
            countries[row[0]] = row
          end

          FasterCSV.foreach("#{RAILS_ROOT}/vendor/extensions/importer/data/#{code}-customers.csv" ) do |row|

            user = User.find_by_email_and_legacy_id_and_store_id row[1], row[0], store.id
            next unless user.nil?

            bill_state = State.find_by_abbr(states[row[11]][1]) unless row[11].blank?
            bill_country = Country.find_by_name(countries[row[14]][2]) unless row[14].blank?
            if bill_country.nil?
              puts "-----------No bill country---------#{row[14]}----------------------------"
            end

            if bill_state.nil? && !bill_country.nil? && !row[11].blank?
              bill_state = State.create(:name => states[row[11]][2], :abbr => states[row[11]][1], :country_id => bill_country.id) unless states[row[11]][1] == "--"
              puts "-----------new bill state--#{bill_state.inspect}-----------------------------------"
            end

            bill_address = Address.new("firstname"   => row[4],
                                      "lastname"    => row[6],
                                      "address1"    => row[8],
                                      "address2"    => row[9],
                                      "city"        => row[10],
                                      "state_id"    => bill_state.nil? ? nil : bill_state.id,
                                      "zipcode"     => row[12],
                                      "country_id"  => bill_country.nil? ? nil : bill_country.id,
                                      "phone"       => row[14])
            bill_address.save(false)


            ship_state = State.find_by_abbr(states[row[22]][1]) unless row[22].blank?
            ship_country = Country.find_by_name(countries[row[24]][2]) unless row[24].blank?
            if ship_country.nil?
              puts "-----------No ship country---------#{row[24]}----------------------------"
            end

            if ship_country.nil? && !ship_country.nil? && !row[22].blank?
              ship_country = State.create(:name => states[row[22]][2], :abbr => states[row[22]][1], :country_id => ship_country.id) unless states[row[22]][1] == "--"
              puts "-----------new ship state--#{ship_country.inspect}-----------------------------------"
            end

            ship_address = Address.new("firstname"   => row[16],
                                      "lastname"    => row[18],
                                      "address1"    => row[19],
                                      "address2"    => row[20],
                                      "city"        => row[21],
                                      "state_id"    => ship_state.nil? ? nil : ship_state.id,
                                      "zipcode"     => row[23],
                                      "country_id"  => ship_country.nil? ? nil : ship_country.id,
                                      "phone"       => row[14])
            ship_address.save(false)



            user = User.new(:store_id => store.id, :email => row[1], :bill_address_id => bill_address.id, :ship_address_id => ship_address.id)
            user.password = row[2]
            user.password_confirmation = row[2]
            user.legacy_id = row[0]
            user.save(false)


          end
        end

        import_users("pwb")
        import_users("nwb")

        def import_orders(code)
          store = Store.find_by_code code
          admin = User.find_by_email "spree@naturalwellbeing.com"

          line_items = {}
          FasterCSV.foreach("#{RAILS_ROOT}/vendor/extensions/importer/data/#{code}-order-details.csv", :headers => true ) do |row|
            unless line_items.has_key? row[0]
              line_items[row[0]] = []
            end

            line_items[row[0]] << row
          end


          FasterCSV.foreach("#{RAILS_ROOT}/vendor/extensions/importer/data/#{code}-orders.csv", :headers => true ) do |row|
            next unless row[29].to_s == "1" #skips incomplete orders
            next if row[22].to_s == "No Data" #skips orders without payments

            order_number = code == "pwb" ? "LP#{row[0]}" : "LN#{row[0]}"
            order = Order.find_by_number(order_number)
            next unless order.nil?

            begin
              puts "Processing #{order_number}"

              user = User.find_by_store_id_and_legacy_id(store.id, row[1])
              if user.nil?
                puts "Order: #{order_number} NOT IMPORTED - Failed to find user with legacy_id: #{row[1]}"
                next
              end

              unless line_items.has_key? row[0]
                puts "Order: #{order_number} NOT IMPORTED - Has no line items"
                next
              end

              order = Order.new("user_id"         => user.id,
                              "state"           => "new",
                              "completed_at"    => row[24],
                              "created_at"      => row[24],
                              "updated_at"      => row[21])
              order.save(false)
              order.checkout.state = "complete"

              line_items[row[0]].each do |li|
                product = Product.find_by_store_id_and_legacy_id(store.id, li[1].to_i)
                if product.nil?
                  puts "Order: #{order_number} LINE ITEM NOT IMPORTED - Failed to find product with legacy_id: #{li[1]}"
                  next
                end

                item = LineItem.new("order_id"    => order.id,
                                   "variant_id"  => product.master.id,
                                   "price"       => li[3].to_f,
                                   "quantity"    => li[2].to_i)

                item.save(false)

                li[2].to_i.times do
                  InventoryUnit.create("order"      => order,
                                      "variant_id"  => product.master.id,
                                      "state"       => "sold")

                end
              end

              if order.line_items.reload.size == 0
                puts "Order: #{order_number} NOT IMPORTED - It has no line items"
                order.destroy
                next
              end

              bill_state = State.find_by_abbr(row[8])
              bill_country = Country.find_by_name(row[9].titleize)
              if bill_country.nil?
                puts "-----------No bill state---------#{row[8]}----------------------------"
              end
              if bill_country.nil?
                puts "-----------No bill country---------#{row[9]}----------------------------"
              end


              bill_address = Address.new("firstname"   => row[3],
                                        "lastname"    => row[4],
                                        "address1"    => row[5],
                                        "address2"    => row[6],
                                        "city"        => row[7],
                                        "state_id"    => bill_state.nil? ? nil : bill_state.id,
                                        "zipcode"     => row[10],
                                        "country_id"  => bill_country.nil? ? nil : bill_country.id,
                                        "phone"       => row[11])
              bill_address.save(false)
              order.bill_address = bill_address

              ship_state = State.find_by_abbr(row[18])
              ship_country = Country.find_by_name(row[19].titleize)
              if ship_state.nil?
                puts "-----------No ship state---------#{row[18]}----------------------------"
              end
              if bill_country.nil?
                puts "-----------No shio country---------#{row[19]}----------------------------"
              end


              ship_address = Address.new("firstname"   => row[13],
                                        "lastname"    => row[14],
                                        "address1"    => row[15],
                                        "address2"    => row[16],
                                        "city"        => row[17],
                                        "state_id"    => ship_state.nil? ? nil : ship_state.id,
                                        "zipcode"     => row[20],
                                        "country_id"  => ship_country.nil? ? nil : ship_country.id,
                                        "phone"       => row[11])
              ship_address.save(false)
              order.bill_address = ship_address

              if code == "pwd"
                shipment_number = "2_" + Array.new(6){rand(10)}.join
              else
                shipment_number = "1_" + Array.new(6){rand(10)}.join
              end


              shipment = Shipment.new("number"  => shipment_number,
                                      "order"   => order,
                                      "address" => ship_address,
                                      "state"   => "pending")
              order.inventory_units.each do |unit|
                shipment.inventory_units << unit
              end

              shipment.save(false)

              order.adjustments << ShippingCharge.create("amount"             => row[32].to_f,
                                                    "adjustment_source_id"    => order.id,
                                                    "adjustment_source_type"  => "Order",
                                                    "description"             => "Shipping Charge: (#{row[32]})")

              order.adjustments << TaxCharge.create("amount"                 => row[35].to_f,
                                                    "adjustment_source_id"    => order.id,
                                                    "adjustment_source_type"  => "Order",
                                                    "description"             => "Tax Charge")

              unless row[26] == "0"
                order.adjustments << Credit.create("amount"                 => row[26].to_f,
                                                    "adjustment_source_id"    => order.id,
                                                    "adjustment_source_type"  => "Order",
                                                    "description"             => "Coupon")
              end

              if row[37].to_f > 0
                order.adjustments << Charge.create("amount"                 => row[37].to_f,
                                                    "adjustment_source_id"    => order.id,
                                                    "adjustment_source_type"  => "Order",
                                                    "description"             => "Surcharge")
              end

              order.checkout.email = row[12]
              order.checkout.ip_address = row[38]
              order.save(false)

              #payment details
              payment_source = nil
              if ["American Express", "Credit Card", "Discover", "MasterCard", "Other", "Visa"].include? row[22]
                payment_source = Creditcard.create("first_name"     => order.bill_address.firstname,
                                                    "last_name"       => order.bill_address.lastname,
                                                    "number"          => "1111-1111-1111-1111",
                                                    "year"            => Time.now.year,
                                                    "month"           => Time.now.month)
              elsif row[22] == "PayPal"
                payment_source = PaypalAccount.create(:email => order.checkout.email)
              elsif row[22] == "Google Checkout"
                payment_source = GoogleAccount.create(:email => order.checkout.email)
              else
                puts "-----------NO PAYMENT SOURCE----#{row[22]}---------------------------------"
              end

              order.reload.update_totals!

              payment = Payment.new("payable"   => order,
                                    "source"     => payment_source,
                                    "amount"     => order.total)
              payment.save(false)

              #force order state
              order.update_attribute(:state, "legacy")
              order.reload
              order.shipment.state = "pending"
              order.shipment.ready!
              order.shipment.ship!

              if row[37] < 0
                rma = ReturnAuthorization.new("order" => order, "amount" => row[37])
                rma.save(false)
                order.reload
                order.inventory_units.each do |unit|
                  unit.return_authorization = rma
                  unit.save!
                end

                rma.receive!
                payment = Payment.new("payable"   => order,
                              "source"     => creditcard,
                              "amount"     => rma.amount * -1)
                payment.save(false)
              end

              orders.comments.create(:title => "Import Comment", :comment => row[28])

              order.reload
              puts "Spree Total: #{number_to_currency(order.total)} NWB Total: #{number_to_currency(row[37])}"

            rescue Exception => e
              puts "ERROR Processing #{order_number}"
              puts e.to_yaml

              order.destroy
            end

          end
        end

       # import_orders("pwb")

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