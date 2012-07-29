class LoadView < ActiveRecord::Migration
  def up
    down
    whole1= View.new(:body_part=>"whole", :view_side=>0, :zoom_scale=>1, :origin_x=>0, :origin_y=>0)
    whole1.save(:validate => false)

    whole2= View.new(:body_part=>"whole", :view_side=>1, :zoom_scale=>1, :origin_x=>0, :origin_y=>0)
    whole2.save(:validate => false)
    
    whole3= View.new(:body_part=>"whole", :view_side=>2, :zoom_scale=>1, :origin_x=>0, :origin_y=>0)
    whole3.save(:validate => false)
    
    whole4= View.new(:body_part=>"whole", :view_side=>3, :zoom_scale=>1, :origin_x=>0, :origin_y=>0)
    whole4.save(:validate => false)
  end

  def down
    View.delete_all
  end
end
