class MarkAllSuitableProductsAsParts < ActiveRecord::Migration
  def self.up
    Product.all.each do |product|

      if product.assembly?
        product.can_be_part = false
      else
        product.can_be_part = true
      end

      product.save!
    end
  end

  def self.down
  end
end