class CreateTags < ActiveRecord::Migration
  def up
    create_table :tags do |t|
      t.integer  :view_id
      t.integer  :origin_x
      t.integer  :origin_y
      t.integer  :width
      t.integer  :height
      t.string  :annotate
    end
  end
  
  def down
    drop_table :tags
  end
end
