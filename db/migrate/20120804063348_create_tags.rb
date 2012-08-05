class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.integer  :view_id
      t.string  :annotate
      t.integer  :severity
      t.integer  :depth
      t.timestamps
    end
  end
end
