class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.string  :annotate
      t.integer  :severity
      t.string  :layer
      t.string  :type
      t.string  :posture
      t.timestamps
    end
  end
end
