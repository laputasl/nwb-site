
def product_review(reminder, report, count)
  puts "- Starting product reviews"
  report << "\nProduct Review Request(s):"
  view = ActionView::Base.new(Spree::ExtensionLoader.view_paths)

  orders = Order.find(:all, :include => {:line_items => [{:variant => :product }, :reminder_messages], :user => {}, :store => {} },
                      :joins => "left outer join reminder_messages on orders.id = reminder_messages.remindable_id and reminder_messages.remindable_type = 'Order'and reminder_messages.reminder_id = #{reminder.id}" ,
                      :conditions => ["reminder_messages.id is null and orders.state = 'shipped' and orders.completed_at <= ?", Time.now.midnight - 22.days])

  orders.each do |order|
    if order.number[0..0] != "R"
      #not sending alert to legacy orders, so create a record to prevent reload later
      ReminderMessage.create(:remindable => order, :reminder => reminder, :user => order.user)
      next
    end

    next if order.in_progress? #just to be sure

    user = order.user
    email = user.nil? ? order.checkout.email : user.email

    products = order.line_items.inject([]) do | products, line_item |
      products << line_item.variant.product
    end

    report << "\n#{order.number}, #{email}, #{order.line_items.map {|li| li.variant.sku }.join(",")}"


    #send the frickin' message!
    begin
      count += 1
      if count >= Spree::Config[:reminders_max_send_count].to_i
        report << "\n\n MAX EMAIL SEND LIMIT REACHED, STOPPED SENDING AT #{count}"
        return
      end

      external_key = Spree::Config["#{order.store.code.upcase}_ET_product_review"]
      variables    = {:First_Name => order.bill_address.firstname,
                      :SENDTIME__CONTENT1 => view.render("order_mailer/product_review_plain", :products => products, :store => order.store),
                      :SENDTIME__CONTENT2 => view.render("order_mailer/product_review_html", :products => products, :store => order.store)}

      Delayed::Job.enqueue DelayedSend.new(Spree::Config.get(:exact_target_user), Spree::Config.get(:exact_target_password), email, external_key, variables, nil,nil,nil)

      ReminderMessage.create(:remindable => order, :reminder => reminder, :user => user)
    rescue ET::Error => error
      report << "\n#{order.number} FAILED"
      report << error.to_yaml
      count = count - 1
    end
  end

  report << "\nTotal email(s) sent for Product Review Request: #{count}"
end

def reorder_alert(reminder, report, count)
  puts "- Starting reorder alerts"
  report << "\nProduct Reorder Alert(s):"
  view = ActionView::Base.new(Spree::ExtensionLoader.view_paths)

  orders = Order.find(:all, :include => {:line_items => [{:variant => :product }, :reminder_messages], :user => {}, :store => {} },
                      :joins => "inner join line_items on line_items.order_id = orders.id left outer join reminder_messages on line_items.id = reminder_messages.remindable_id and reminder_messages.remindable_type = 'LineItem' and reminder_messages.reminder_id = #{reminder.id}" ,
                      :conditions => "reminder_messages.id is null and orders.state = 'shipped'")

  orders.each do |order|

    user = order.user
    email = user.nil? ? order.checkout.email : user.email
    products = []

    order.line_items.each do |line_item|
      next if line_item.reminder_messages.any? {|rm| rm.reminder_id == reminder.id }
      product = line_item.variant.product

      if product.reminder.to_i > 0
        reminder_days = product.reminder.to_i * line_item.quantity
        reorder_date = order.completed_at + reminder_days.days

        if reorder_date <= Time.now.midnight

          if reorder_date >= Time.parse("2010-04-30")
            #only send for reorder dates after april 30 (don't want to send alerts for old orders)
            products << product
            ReminderMessage.create!(:remindable => line_item, :reminder => reminder, :user => user)
          else
            #don't send just pretend that it was sent (to get a complete histroy for old orders)
            ReminderMessage.create!(:remindable => line_item, :reminder => reminder, :user => user)
          end
        end

      end
    end

    unless products.empty? #send the frickin' message!
      report << "\n#{order.number}, #{email}, #{products.map(&:sku).join(",")}"

      begin
        count += 1
        if count >= Spree::Config[:reminders_max_send_count].to_i
          report << "\n\n MAX EMAIL SEND LIMIT REACHED, STOPPED SENDING AT #{count}"
          return
        end

        external_key = Spree::Config["#{order.store.code.upcase}_ET_reorder_alert"]
        variables    = {:First_Name => order.bill_address.firstname,
                        :SENDTIME__CONTENT1 => view.render("order_mailer/reorder_alert_plain", :products => products, :store => order.store),
                        :SENDTIME__CONTENT2 => view.render("order_mailer/reorder_alert_html", :products => products, :store => order.store)}

        Delayed::Job.enqueue DelayedSend.new(Spree::Config.get(:exact_target_user), Spree::Config.get(:exact_target_password), email, external_key, variables, nil,nil,nil)

      rescue ET::Error => error
        report << "\n#{order.number} FAILED"
        report << error.to_yaml
        count = count - 1
      end

    end
  end

  report << "\nTotal email(s) sent for Product Reorder Alert: #{count}"
end



#-----------This is the start of the script!--------------------
now = Time.new()
Time.zone = "PST"

puts "Starting up..."
report  = "The following after-sales emails have been sent at: #{Time.zone.at(now).strftime("%B %d, %Y at %I:%M PST")}\n"

Reminder.all.each do |reminder|
  send(reminder.name.downcase.gsub(" ", "_").to_sym, reminder, report, 0)
  report << "\n\n"
end

#send reports to operations
Delayed::Job.enqueue DelayedSend.new(Spree::Config.get(:exact_target_user), Spree::Config.get(:exact_target_password), "brian@railsdog.com", "nwb-operational", { :SENDTIME__CONTENT1 => "Reminder Emails Report", :SENDTIME__CONTENT2 => report}, nil,nil,nil)
Delayed::Job.enqueue DelayedSend.new(Spree::Config.get(:exact_target_user), Spree::Config.get(:exact_target_password), "operations@naturalwellbeing.com", "nwb-operational", { :SENDTIME__CONTENT1 => "Reminder Emails Report", :SENDTIME__CONTENT2 => report}, nil,nil,nil)


