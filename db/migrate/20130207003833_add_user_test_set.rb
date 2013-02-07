class AddUserTestSet < ActiveRecord::Migration
  def up
    add_column  :users,  :test ,   :string
  end

  def down
    remove_column  :users,  :test
  end
end