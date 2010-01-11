class Store < ActiveRecord::Base
  has_many :products
  has_many :taxonomies
  has_many :orders
  has_many :users
  has_many :exact_target_lists
end
