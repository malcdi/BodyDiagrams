class CreateHandTags < ActiveRecord::Migration
  def change
    create_table :hand_tags do |t|
      t.integer :tag_id
      t.text  :points      
      t.integer  :view_side
      t.timestamps
    end
  end
end