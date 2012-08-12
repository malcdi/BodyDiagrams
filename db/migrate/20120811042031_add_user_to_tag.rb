class AddUserToTag < ActiveRecord::Migration
  def up
    add_column  :tags,  :user_id ,   :string
  end
  
  def down
    remove_column  :tags,  :user_id
  end
end
