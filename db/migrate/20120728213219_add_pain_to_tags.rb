class AddPainToTags < ActiveRecord::Migration
  def change
    add_column :tags, :severity, :integer
    add_column :tags, :depth,  :integer
  end
end
