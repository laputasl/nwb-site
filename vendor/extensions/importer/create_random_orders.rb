require 'pp'

# find_index method for Ruby 1.8.6 and earlier.
# Falls back to the built-in method in 1.8.7 and newer.
module Enumerable
  
  def method_missing(name, *args, &block)
    if name == :find_index
      return my_find_index(*args)
    else
      super(name, *args, &block)
    end
  end
  
  def my_find_index(value)
    self.each_with_index do |item, index|
      if item == value
        return index
      end
    end
    nil
  end
  
end

User.class_eval do
   attr_accessible :ship_address_id, :salt, :bill_address_id, :crypted_password, :id
end

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

Shipment.class_eval do
  def create_shipping_charge
  end
end

TaxCharge.class_eval do
  def calculate_tax_charge
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


class RandomOrders

  def initialize
    # setup line items
    line_items = [
      { :code => "nwb", :sku => "HT 1000", :legacy_id => "34", :all_sold => 49885, :max_sold => 18, :avg_sold => 2},
      { :code => "nwb", :sku => "HR 13025", :legacy_id => "92", :all_sold => 8804, :max_sold => 12, :avg_sold => 1},
      { :code => "nwb", :sku => "AR 3100", :legacy_id => "50", :all_sold => 3880, :max_sold => 20, :avg_sold => 2},
      { :code => "nwb", :sku => "CE 1000", :legacy_id => "230", :all_sold => 3689, :max_sold => 8, :avg_sold => 1},
      { :code => "nwb", :sku => "HR 2140", :legacy_id => "24", :all_sold => 1249, :max_sold => 10, :avg_sold => 1},
      { :code => "nwb", :sku => "HT 1625", :legacy_id => "104", :all_sold => 991, :max_sold => 6, :avg_sold => 1},
      { :code => "nwb", :sku => "HR 2100", :legacy_id => "26", :all_sold => 919, :max_sold => 12, :avg_sold => 1},
      { :code => "nwb", :sku => "LL 6100", :legacy_id => "37", :all_sold => 745, :max_sold => 20, :avg_sold => 1},
      { :code => "nwb", :sku => "HT 1210", :legacy_id => "49", :all_sold => 652, :max_sold => 8, :avg_sold => 1},
      { :code => "nwb", :sku => "LL 6250", :legacy_id => "36", :all_sold => 493, :max_sold => 10, :avg_sold => 1},
      { :code => "nwb", :sku => "SE 1530", :legacy_id => "233", :all_sold => 453, :max_sold => 3, :avg_sold => 1},
      { :code => "nwb", :sku => "HR 2350", :legacy_id => "62", :all_sold => 410, :max_sold => 20, :avg_sold => 1},
      { :code => "nwb", :sku => "HR 2130", :legacy_id => "23", :all_sold => 345, :max_sold => 4, :avg_sold => 1},
      { :code => "nwb", :sku => "HT 1050", :legacy_id => "45", :all_sold => 246, :max_sold => 2, :avg_sold => 1},
      { :code => "nwb", :sku => "SC 5000", :legacy_id => "220", :all_sold => 237, :max_sold => 6, :avg_sold => 2},
      { :code => "nwb", :sku => "HR 2120", :legacy_id => "22", :all_sold => 195, :max_sold => 4, :avg_sold => 1},
      { :code => "nwb", :sku => "HR 2375", :legacy_id => "67", :all_sold => 181, :max_sold => 5, :avg_sold => 1},
      { :code => "nwb", :sku => "HT 1225", :legacy_id => "68", :all_sold => 176, :max_sold => 5, :avg_sold => 1},
      { :code => "nwb", :sku => "HT 1510", :legacy_id => "59", :all_sold => 160, :max_sold => 6, :avg_sold => 1},
      { :code => "nwb", :sku => "HT 1200", :legacy_id => "30", :all_sold => 146, :max_sold => 3, :avg_sold => 1},
      { :code => "nwb", :sku => "HT 1212", :legacy_id => "112", :all_sold => 143, :max_sold => 4, :avg_sold => 1},
      { :code => "nwb", :sku => "HR 2208", :legacy_id => "119", :all_sold => 143, :max_sold => 15, :avg_sold => 1},
      { :code => "nwb", :sku => "PE 1000", :legacy_id => "231", :all_sold => 141, :max_sold => 20, :avg_sold => 3},
      { :code => "nwb", :sku => "HT 1240", :legacy_id => "114", :all_sold => 140, :max_sold => 4, :avg_sold => 1},
      { :code => "nwb", :sku => "AZ 1613", :legacy_id => "237", :all_sold => 137, :max_sold => 9, :avg_sold => 1},
      { :code => "nwb", :sku => "HR 2500", :legacy_id => "173", :all_sold => 117, :max_sold => 1, :avg_sold => 1},
      { :code => "nwb", :sku => "HR 2300", :legacy_id => "61", :all_sold => 114, :max_sold => 4, :avg_sold => 2},
      { :code => "nwb", :sku => "HT 1226", :legacy_id => "70", :all_sold => 112, :max_sold => 3, :avg_sold => 1},
      { :code => "nwb", :sku => "HR 2400", :legacy_id => "109", :all_sold => 103, :max_sold => 6, :avg_sold => 1},
      { :code => "nwb", :sku => "HR 2205", :legacy_id => "116", :all_sold => 96, :max_sold => 4, :avg_sold => 1},
      { :code => "nwb", :sku => "WC 9400", :legacy_id => "108", :all_sold => 92, :max_sold => 10, :avg_sold => 1},
      { :code => "nwb", :sku => "SC 5050", :legacy_id => "221", :all_sold => 85, :max_sold => 3, :avg_sold => 1},
      { :code => "nwb", :sku => "HR 2207", :legacy_id => "118", :all_sold => 84, :max_sold => 6, :avg_sold => 1},
      { :code => "nwb", :sku => "WC 9350", :legacy_id => "95", :all_sold => 78, :max_sold => 4, :avg_sold => 1},
      { :code => "nwb", :sku => "HT 1220", :legacy_id => "51", :all_sold => 77, :max_sold => 3, :avg_sold => 1},
      { :code => "nwb", :sku => "AR 3300", :legacy_id => "105", :all_sold => 75, :max_sold => 3, :avg_sold => 1},
      { :code => "nwb", :sku => "HT 1600", :legacy_id => "100", :all_sold => 72, :max_sold => 3, :avg_sold => 1},
      { :code => "nwb", :sku => "AR 1275", :legacy_id => "234", :all_sold => 66, :max_sold => 20, :avg_sold => 2},
      { :code => "nwb", :sku => "HR 13000", :legacy_id => "81", :all_sold => 62, :max_sold => 3, :avg_sold => 1},
      { :code => "nwb", :sku => "HL 1335", :legacy_id => "235", :all_sold => 61, :max_sold => 6, :avg_sold => 1},
      { :code => "nwb", :sku => "CF 4250", :legacy_id => "232", :all_sold => 58, :max_sold => 5, :avg_sold => 1},
      { :code => "nwb", :sku => "HT 1230", :legacy_id => "74", :all_sold => 57, :max_sold => 4, :avg_sold => 1},
      { :code => "nwb", :sku => "WL 7500", :legacy_id => "40", :all_sold => 57, :max_sold => 3, :avg_sold => 1},
      { :code => "nwb", :sku => "HT 1500", :legacy_id => "58", :all_sold => 56, :max_sold => 3, :avg_sold => 1},
      { :code => "nwb", :sku => "HR 2600", :legacy_id => "225", :all_sold => 54, :max_sold => 1, :avg_sold => 1},
      { :code => "nwb", :sku => "HT 1228", :legacy_id => "72", :all_sold => 53, :max_sold => 4, :avg_sold => 1},
      { :code => "nwb", :sku => "HT 1229", :legacy_id => "73", :all_sold => 52, :max_sold => 2, :avg_sold => 1},
      { :code => "nwb", :sku => "SC 9125", :legacy_id => "96", :all_sold => 50, :max_sold => 7, :avg_sold => 1},
      { :code => "nwb", :sku => "SC 5200", :legacy_id => "224", :all_sold => 50, :max_sold => 5, :avg_sold => 1},
      { :code => "nwb", :sku => "HR 2325", :legacy_id => "88", :all_sold => 48, :max_sold => 2, :avg_sold => 1},
      { :code => "nwb", :sku => "AR 3200", :legacy_id => "80", :all_sold => 44, :max_sold => 2, :avg_sold => 1},
      { :code => "nwb", :sku => "HR 2165", :legacy_id => "76", :all_sold => 43, :max_sold => 4, :avg_sold => 2},
      { :code => "nwb", :sku => "HR 2170", :legacy_id => "86", :all_sold => 40, :max_sold => 2, :avg_sold => 1},
      { :code => "nwb", :sku => "MU 4535", :legacy_id => "219", :all_sold => 40, :max_sold => 1, :avg_sold => 1},
      { :code => "nwb", :sku => "SC 5100", :legacy_id => "222", :all_sold => 37, :max_sold => 10, :avg_sold => 1},
      { :code => "nwb", :sku => "HT 1227", :legacy_id => "71", :all_sold => 37, :max_sold => 3, :avg_sold => 1},
      { :code => "nwb", :sku => "SC 4545", :legacy_id => "184", :all_sold => 36, :max_sold => 4, :avg_sold => 1},
      { :code => "nwb", :sku => "HR 2206", :legacy_id => "117", :all_sold => 35, :max_sold => 2, :avg_sold => 1},
      { :code => "nwb", :sku => "HR 2160", :legacy_id => "75", :all_sold => 35, :max_sold => 4, :avg_sold => 1},
      { :code => "nwb", :sku => "LL 6160", :legacy_id => "85", :all_sold => 33, :max_sold => 3, :avg_sold => 1},
      { :code => "nwb", :sku => "HR 2610", :legacy_id => "226", :all_sold => 30, :max_sold => 1, :avg_sold => 1},
      { :code => "nwb", :sku => "SC 4515", :legacy_id => "178", :all_sold => 29, :max_sold => 20, :avg_sold => 3},
      { :code => "nwb", :sku => "LL 6150", :legacy_id => "43", :all_sold => 28, :max_sold => 3, :avg_sold => 1},
      { :code => "nwb", :sku => "AZ 2689", :legacy_id => "244", :all_sold => 25, :max_sold => 3, :avg_sold => 1},
      { :code => "nwb", :sku => "NV 031", :legacy_id => "251", :all_sold => 24, :max_sold => 3, :avg_sold => 1},
      { :code => "nwb", :sku => "SC 5025", :legacy_id => "229", :all_sold => 24, :max_sold => 2, :avg_sold => 1},
      { :code => "nwb", :sku => "LL 6335", :legacy_id => "101", :all_sold => 18, :max_sold => 3, :avg_sold => 1},
      { :code => "nwb", :sku => "AZ 2764", :legacy_id => "245", :all_sold => 18, :max_sold => 3, :avg_sold => 1},
      { :code => "nwb", :sku => "NV 103", :legacy_id => "250", :all_sold => 18, :max_sold => 3, :avg_sold => 1},
      { :code => "nwb", :sku => "SC 4500", :legacy_id => "176", :all_sold => 17, :max_sold => 5, :avg_sold => 1},
      { :code => "nwb", :sku => "AZ 1460", :legacy_id => "243", :all_sold => 16, :max_sold => 3, :avg_sold => 1},
      { :code => "nwb", :sku => "NC 9300", :legacy_id => "93", :all_sold => 14, :max_sold => 2, :avg_sold => 1},
      { :code => "nwb", :sku => "LL 6300", :legacy_id => "83", :all_sold => 13, :max_sold => 3, :avg_sold => 1},
      { :code => "nwb", :sku => "AZ 1286", :legacy_id => "236", :all_sold => 13, :max_sold => 3, :avg_sold => 1},
      { :code => "nwb", :sku => "AZ 1453", :legacy_id => "238", :all_sold => 12, :max_sold => 4, :avg_sold => 1},
      { :code => "nwb", :sku => "SC 5150", :legacy_id => "223", :all_sold => 10, :max_sold => 1, :avg_sold => 1},
      { :code => "nwb", :sku => "SC 4565", :legacy_id => "189", :all_sold => 10, :max_sold => 1, :avg_sold => 1},
      { :code => "nwb", :sku => "WL 7600", :legacy_id => "106", :all_sold => 9, :max_sold => 2, :avg_sold => 1},
      { :code => "nwb", :sku => "NV 900", :legacy_id => "247", :all_sold => 8, :max_sold => 7, :avg_sold => 4},
      { :code => "nwb", :sku => "NV 285", :legacy_id => "253", :all_sold => 8, :max_sold => 2, :avg_sold => 1},
      { :code => "nwb", :sku => "NV 092", :legacy_id => "248", :all_sold => 7, :max_sold => 3, :avg_sold => 1},
      { :code => "nwb", :sku => "NV 289", :legacy_id => "249", :all_sold => 7, :max_sold => 3, :avg_sold => 2},
      { :code => "nwb", :sku => "SC 4540", :legacy_id => "183", :all_sold => 7, :max_sold => 1, :avg_sold => 1},
      { :code => "nwb", :sku => "LL 6400", :legacy_id => "102", :all_sold => 6, :max_sold => 2, :avg_sold => 1},
      { :code => "nwb", :sku => "SC 4525", :legacy_id => "180", :all_sold => 5, :max_sold => 1, :avg_sold => 1},
      { :code => "nwb", :sku => "SC 4560", :legacy_id => "188", :all_sold => 5, :max_sold => 3, :avg_sold => 1},
      { :code => "nwb", :sku => "MU 4530", :legacy_id => "202", :all_sold => 4, :max_sold => 1, :avg_sold => 1},
      { :code => "nwb", :sku => "SC 4555", :legacy_id => "187", :all_sold => 3, :max_sold => 1, :avg_sold => 1},
      { :code => "nwb", :sku => "NV 121", :legacy_id => "252", :all_sold => 2, :max_sold => 1, :avg_sold => 1},
      { :code => "nwb", :sku => "NV 288", :legacy_id => "254", :all_sold => 2, :max_sold => 1, :avg_sold => 1},
      { :code => "nwb", :sku => "MU 4555", :legacy_id => "207", :all_sold => 1, :max_sold => 1, :avg_sold => 1},
      { :code => "nwb", :sku => "SC 4520", :legacy_id => "179", :all_sold => 1, :max_sold => 1, :avg_sold => 1},
      { :code => "nwb", :sku => "PC 8500", :legacy_id => "107", :all_sold => 1, :max_sold => 1, :avg_sold => 1 },
      { :code => "pwb", :sku => "PH 2350", :legacy_id => "92", :all_sold => 6527, :max_sold => 6, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 2300", :legacy_id => "89", :all_sold => 5515, :max_sold => 4, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1600", :legacy_id => "28", :all_sold => 4992, :max_sold => 8, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1550", :legacy_id => "90", :all_sold => 3872, :max_sold => 4, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1550", :legacy_id => "91", :all_sold => 3197, :max_sold => 9, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1350", :legacy_id => "72", :all_sold => 3118, :max_sold => 4, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1250", :legacy_id => "10", :all_sold => 3013, :max_sold => 4, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1350", :legacy_id => "73", :all_sold => 2291, :max_sold => 10, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1600", :legacy_id => "29", :all_sold => 2116, :max_sold => 6, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1000", :legacy_id => "37", :all_sold => 1742, :max_sold => 4, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1800", :legacy_id => "31", :all_sold => 1604, :max_sold => 3, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 5600", :legacy_id => "62", :all_sold => 1323, :max_sold => 4, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1250", :legacy_id => "64", :all_sold => 1062, :max_sold => 3, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1400", :legacy_id => "75", :all_sold => 1032, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1150", :legacy_id => "71", :all_sold => 1008, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1150", :legacy_id => "70", :all_sold => 684, :max_sold => 4, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 5625", :legacy_id => "22", :all_sold => 669, :max_sold => 4, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1750", :legacy_id => "26", :all_sold => 579, :max_sold => 4, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1800", :legacy_id => "30", :all_sold => 505, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1400", :legacy_id => "74", :all_sold => 481, :max_sold => 4, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1200", :legacy_id => "77", :all_sold => 424, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1000", :legacy_id => "36", :all_sold => 395, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1450", :legacy_id => "84", :all_sold => 340, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1200", :legacy_id => "76", :all_sold => 330, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1500", :legacy_id => "87", :all_sold => 318, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1300", :legacy_id => "63", :all_sold => 297, :max_sold => 4, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 7502", :legacy_id => "48", :all_sold => 286, :max_sold => 6, :avg_sold => 2},
      { :code => "pwb", :sku => "PH 1950", :legacy_id => "65", :all_sold => 274, :max_sold => 3, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 5400", :legacy_id => "51", :all_sold => 257, :max_sold => 4, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 5875", :legacy_id => "54", :all_sold => 233, :max_sold => 4, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 5850", :legacy_id => "11", :all_sold => 189, :max_sold => 4, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1050", :legacy_id => "40", :all_sold => 174, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1450", :legacy_id => "85", :all_sold => 163, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1650", :legacy_id => "23", :all_sold => 162, :max_sold => 4, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1750", :legacy_id => "27", :all_sold => 141, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 5550", :legacy_id => "52", :all_sold => 125, :max_sold => 4, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1300", :legacy_id => "6", :all_sold => 113, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "P4", :legacy_id => "107", :all_sold => 108, :max_sold => 4, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 5800", :legacy_id => "100", :all_sold => 107, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1650", :legacy_id => "24", :all_sold => 97, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 2150", :legacy_id => "69", :all_sold => 97, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 2250", :legacy_id => "38", :all_sold => 96, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 5900", :legacy_id => "55", :all_sold => 96, :max_sold => 4, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1100", :legacy_id => "94", :all_sold => 90, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 2150", :legacy_id => "68", :all_sold => 84, :max_sold => 4, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1900", :legacy_id => "35", :all_sold => 81, :max_sold => 4, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 2250", :legacy_id => "39", :all_sold => 80, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1050", :legacy_id => "41", :all_sold => 80, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 7075", :legacy_id => "43", :all_sold => 78, :max_sold => 3, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1100", :legacy_id => "95", :all_sold => 78, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 5350", :legacy_id => "50", :all_sold => 75, :max_sold => 10, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1700", :legacy_id => "25", :all_sold => 73, :max_sold => 4, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1950", :legacy_id => "12", :all_sold => 69, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 2000", :legacy_id => "66", :all_sold => 69, :max_sold => 6, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 5500", :legacy_id => "1", :all_sold => 68, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 5300", :legacy_id => "49", :all_sold => 68, :max_sold => 4, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 2050", :legacy_id => "80", :all_sold => 68, :max_sold => 5, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 5811", :legacy_id => "103", :all_sold => 60, :max_sold => 4, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1700", :legacy_id => "5", :all_sold => 59, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1500", :legacy_id => "86", :all_sold => 51, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 6125", :legacy_id => "58", :all_sold => 50, :max_sold => 3, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 2300", :legacy_id => "88", :all_sold => 49, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "ER", :legacy_id => "110", :all_sold => 49, :max_sold => 12, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 2350", :legacy_id => "93", :all_sold => 46, :max_sold => 4, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 5362", :legacy_id => "105", :all_sold => 45, :max_sold => 10, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 6100", :legacy_id => "57", :all_sold => 43, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 5900", :legacy_id => "56", :all_sold => 42, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "VR", :legacy_id => "109", :all_sold => 38, :max_sold => 5, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 2050", :legacy_id => "81", :all_sold => 36, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "KR", :legacy_id => "111", :all_sold => 35, :max_sold => 4, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 7500", :legacy_id => "46", :all_sold => 31, :max_sold => 1, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 2200", :legacy_id => "79", :all_sold => 31, :max_sold => 5, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1900", :legacy_id => "34", :all_sold => 30, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1850", :legacy_id => "32", :all_sold => 29, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 7625", :legacy_id => "96", :all_sold => 28, :max_sold => 1, :avg_sold => 1},
      { :code => "pwb", :sku => "FR", :legacy_id => "108", :all_sold => 25, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 5364", :legacy_id => "106", :all_sold => 23, :max_sold => 3, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 1850", :legacy_id => "33", :all_sold => 16, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 7650", :legacy_id => "97", :all_sold => 16, :max_sold => 1, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 7800", :legacy_id => "117", :all_sold => 16, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 2000", :legacy_id => "67", :all_sold => 15, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 2100", :legacy_id => "83", :all_sold => 12, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 2100", :legacy_id => "82", :all_sold => 11, :max_sold => 1, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 7600", :legacy_id => "47", :all_sold => 10, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 7800", :legacy_id => "116", :all_sold => 10, :max_sold => 1, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 7500", :legacy_id => "45", :all_sold => 9, :max_sold => 1, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 7700", :legacy_id => "114", :all_sold => 9, :max_sold => 1, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 2400", :legacy_id => "98", :all_sold => 8, :max_sold => 1, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 7050", :legacy_id => "42", :all_sold => 4, :max_sold => 2, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 2200", :legacy_id => "78", :all_sold => 4, :max_sold => 1, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 2425", :legacy_id => "99", :all_sold => 4, :max_sold => 1, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 7400", :legacy_id => "44", :all_sold => 3, :max_sold => 1, :avg_sold => 1},
      { :code => "pwb", :sku => "PH 7700", :legacy_id => "115", :all_sold => 2, :max_sold => 1, :avg_sold => 1}
    ]
    item = {}
    # combine line items
    line_items.each do |line|
      sku = line[:sku]

      item[sku] ||= {
        :code => line[:code],
        :sku => sku,
        :all_sold => 0,
        :legacy => []
      }
      itm = item[sku]

      itm[:all_sold] += line[:all_sold]

      itm[:legacy] << {
        :id    => line[:legacy_id], 
        :total => line[:all_sold], 
        :max   => line[:max_sold], 
        :avg   => line[:avg_sold]
      }

    end

    @line_items = item.values
    
    
  end
  
  def line_items 
    @line_items.clone
  end
  
  def address country = :us
    addr = Address.new(
      "firstname"   => "Test",
      "lastname"    => "Name"
    )
    case country
    when :ca
     addr.city = "OAKVILLE"
     addr.address1 = "2443 HIGH MOUNT CRES"
     addr.zipcode = "L6M 4Y9"
     addr.country_id = 35
     addr.phone = "289 242 5459"
     addr.state_id = 1061493594
    when :gb
      addr.city = "Hendon London"
      addr.address1 = "Babington Rd Usher Halls"
      addr.address2 = "125 Block B"
      addr.zipcode = "NW4 4HF"
      addr.country_id = 213
      addr.phone = 07762107232
    else
      addr.city = "NEW LONDON"
      addr.address1 = "320 MONTAUK AVE"
      addr.zipcode = "06320-4722"
      addr.country_id = 214
      addr.phone = "860-367-6164"
      addr.state_id = 69870734
    end
    addr.save
    addr
  end
  
  
  def create_order
    stores = {}
    codes = %w(pwb nwb)
    codes.each do |code|
      store = Store.find_by_code(code)
      stores[code] = store.id
    end
    
    order_store = codes[rand(2)]
    
    order_number = "T%09d" % (1+rand(999999998)) #don't think we'll create a collision
    email = "adam.vandenhoven+#{order_number}@gmail.com"
    order = Order.new(
      "number" => order_number,
      "completed_at" => Time.now,
      "store_id" => stores[order_store]
    )
    order.save(false)
    order.checkout.state = "complete"
    order.checkout.email = email
    order.checkout.save(false)
    
    order_size = 1+rand(4) 
    remaining_items = line_items
    while order.line_items.reload.size < order_size
      skus, remaining_items =  pick_random(remaining_items, 1)  
      sku = skus[0]
      leg, remain = pick_random(sku[:legacy], 1)  #get a specific product for this sku
      leg = leg[0]
      prod = Product.find_by_store_id_and_legacy_id(stores[sku[:code]], leg[:id])
      unless prod.nil? # selecting a non-existant product
        quant = random_quant(leg[:avg], leg[:max])
        item = LineItem.new("order_id"    => order.id,
                            "price"       => prod.master.volume_price(quant).to_f,
                            "variant_id"  => prod.master.id,
                            "quantity"    => quant)
        item.price = prod.master.volume_price(quant).to_f
        item.save(false)
        quant.times do |i|
          InventoryUnit.create("order" => order, "variant_id"  => prod.master.id, "state" => "sold" )
        end
      end
    end
    # Set billing addresses
    countries = [:ca, :us, :gb]
    country = countries[((rand(3)+rand(3)+rand(3))/3).floor]
    order.bill_address = address(country)
    order.bill_address.save(false)
    ship_address = address(country)
    order.ship_address = ship_address
    order.ship_address.save(false)
    
    if order_store == 'nwb'
      shipment_number = "1_%09d" % (1+rand(999999998))
    else
      shipment_number = "2_%09d" % (1+rand(999999998))
    end
    shipment = Shipment.new("number"  => shipment_number,
                            "order"   => order,
                            "address" => ship_address,
                            "state"   => "pending")
    order.inventory_units.each do |unit|
      shipment.inventory_units << unit
    end

    shipment.save(false)
    shipment.reload
    
    order.adjustments << ShippingCharge.create("amount"             => (10+rand(100000)/100).to_f,
                                          "adjustment_source_id"    => order.id,
                                          "adjustment_source_type"  => "Order",
                                          "description"             => "Shipping Charge")
    order.save(false)
    order.reload.update_totals!

    legacy_payments = PaymentMethod.find_by_name("Legacy Payments")

    payment_source = Creditcard.create("first_name"     => order.bill_address.firstname,
                                        "last_name"       => order.bill_address.lastname,
                                        "number"          => "1111-1111-1111-1111",
                                        "year"            => Time.now.year,
                                        "month"           => Time.now.month)

    payment = Payment.new("payable"             => order,
                          "payment_method_id"   => legacy_payments.id,
                          "source"              => payment_source,
                          "amount"              => order.total)
                          
    payment.save(false)
    order.reload
    order.update_attribute(:state, "paid")
    order.save(false)
    order.reload

    ship_method_ids = {
      :us => 1647757468,
      :gb => 1647757472,  
      :ca => 1647757476
    }
    shipment_method = ShippingMethod.find_by_id(ship_method_ids[country])
    order.shipment.shipping_method = shipment_method
    order.shipment.state = "pending"
    order.shipment.save
    order.shipment.reload
    order.shipment.ready!
  
  
  
  end
  
  private
  def pick_random list, len
    cloned = list.clone

    total_weight = cloned.inject(0) do |weight, line|
      weight += line[:all_sold] || line[:total]
      line[:weight] = weight
      weight
    end

    pos = rand(total_weight)
    index  = cloned.index do |itm|  
      itm[:weight] >= pos  
    end

    item = list.delete_at(index)
    result = [item]
    if len > 1
      res, list = pick_random(list, len-1)
      result.concat(res)
    end
    return result, list
  end


  def random_index list
    weights = []
    total_weight = list.inject(0) do |weight, line|
      weight += line
      weights << weight
      weight
    end

    pos = rand(total_weight)
    weights.index do |itm|  
      itm >= pos  
    end
  end

  def random_quant(avg, max)
    options = []
    pre = avg - 1
    steps = (pre + 1) * pre / 2
    pre.times do |i|
      weight = (10000 * i / steps).to_i
      options << weight
    end
    options << 20000
    post = max-avg
    steps = (post + 1) * post / 2
    post.times do |j|
      i=post-j
      weight = (10000 * i / steps).to_i
      options << weight
    end

    random_index(options)+1

  end
  
end



ro = RandomOrders.new
ro.create_order