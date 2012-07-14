class Tag < ActiveRecord::Base
	belongs_to :view
	validates :width, :presence=>true 
	validates :height, :presence=>true
end
