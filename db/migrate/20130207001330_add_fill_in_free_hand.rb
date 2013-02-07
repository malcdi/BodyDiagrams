class AddFillInFreeHand < ActiveRecord::Migration
  def up
    add_column  :hand_tags,  :fill ,   :boolean
  end

  def down
    remove_column  :hand_tags,  :fill
  end
end
