class Store < ActiveRecord::Base
  has_many :products
  has_many :taxonomies
  has_many :orders
end
