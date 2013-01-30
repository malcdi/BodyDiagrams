class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.integer :user_id
      t.string :target
      t.string :action
      t.timestamps
    end
  end
end
