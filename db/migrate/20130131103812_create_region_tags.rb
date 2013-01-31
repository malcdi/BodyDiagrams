class CreateRegionTags < ActiveRecord::Migration
  def change
    create_table :region_tags do |t|
      t.integer :tag_id
      t.integer :x    
      t.integer :y
      t.integer :w
      t.integer :h  
      t.timestamps
    end
  end
end
