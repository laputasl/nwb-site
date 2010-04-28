ActiveRecord::Schema.define(:version => 0) do

  create_table "recipes", :force => true do |t|
    t.string "name"
  end

  create_table "xapit_changes", :force => true do |t|
    t.string "target_class"
    t.integer "target_id"
    t.string "operation"
  end

end
