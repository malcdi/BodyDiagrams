class CreateViews < ActiveRecord::Migration
  def up
    create_table :views do |t|
      t.string :body_part
      t.integer :view_side
      t.integer :zoom_scale
      t.integer :origin_x
      t.integer :origin_y
    end
  end
  
  def down
    drop_table :views
  end
end
