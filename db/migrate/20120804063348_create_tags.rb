class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      # property related
      t.string  :annotate
      t.integer  :severity
      t.string  :posture
      
      # view related
      t.integer  :view_side
      t.integer  :tag_group
      t.timestamps
    end
  end
end
