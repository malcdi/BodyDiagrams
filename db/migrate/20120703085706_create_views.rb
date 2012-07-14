class CreateViews < ActiveRecord::Migration
  def up
    create_table :views do |t|
      t.string :img_name
      t.string :body_part
      t.integer :view_side
    end
  end
  
  def down
    drop_table :views
  end
end
