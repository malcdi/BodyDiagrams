class LoadView < ActiveRecord::Migration
  def up
    down
    whole1= View.new(:img_name=>"front.png", :body_part=>"whole", :view_side=>0)
    whole1.save(:validate => false)

    whole2= View.new(:img_name=>"left.png", :body_part=>"whole", :view_side=>1)
    whole2.save(:validate => false)
    
    whole3= View.new(:img_name=>"back.png", :body_part=>"whole", :view_side=>2)
    whole3.save(:validate => false)
    
    whole4= View.new(:img_name=>"right.png", :body_part=>"whole", :view_side=>3)
    whole4.save(:validate => false)
  end

  def down
    View.delete_all
  end
end
