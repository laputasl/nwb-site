module NwbThemeHelper 
  def self.volume_levels prod
    volume_prices = prod.master.volume_prices
    re_rng = /(\d+)(\D+)(\d*)/
    Struct.new("Level", :price, :first, :last, :display)
    volume_prices.map do |price|
      mtch = re_rng.match(price.range)
      first = mtch[1].to_i
      last = mtch[3].to_i
      case mtch[2]
      when "..."
        last += -1
      when "+"
        last = nil
      end
      Struct::Level.new(price.amount.to_f, first, last, price.display)
    end
  end
end
