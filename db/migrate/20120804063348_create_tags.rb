class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.string  :annotate
      t.integer  :severity
      t.integer  :depth
      t.integer  :view_side
      t.timestamps
    end
  end
end
