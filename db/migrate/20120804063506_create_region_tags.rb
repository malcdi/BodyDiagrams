class CreateRegionTags < ActiveRecord::Migration
  def change
    create_table :region_tags do |t|
      t.integer  :tag_id
      t.integer  :origin_x
      t.integer  :origin_y
      t.integer  :width
      t.integer  :height
      t.timestamps
    end
  end
end