class MainController < ApplicationController
	def app
		#temporary.. to be changed
		@cur_view=View.find(:all)[0]
		
	end
	
	def postGraphicTag
		tagId=params[:tagId]
		#saving freeHand points
		hand=JSON.parse(params[:freeHand])
		hand.each do |elem|
			handTag = HandTag.new()
			handTag.points=elem.to_s();
			handTag.tag_id=tagId
			handTag.save()
		end
		
		#saving region points
		region=JSON.parse(params[:region])
		region.each do |elem|
			regionTag = RegionTag.new()
			regionTag.origin_x=elem["origin_x"]
			regionTag.origin_y=elem["origin_y"]
			regionTag.height=elem["height"]
			regionTag.width=elem["width"]
			regionTag.tag_id=tagId
			regionTag.save()
		end
		render :text=>tagId.to_s+"good"
	end
	
	def draw
		@tag = Tag.new
		#temporary.. to be changed
		@cur_view=View.find(:all)[0]
	end
	
	def get_view
		@cur_view=View.find(:all)[params[:view_num].to_i]
		render :text =>@cur_view.to_json
	end
	
	def postTag
		@tag = Tag.new()
		@tag.annotate=params[:annotate]
		@tag.severity=params[:severity]
		@tag.depth=params[:depth]
		@tag.view_id=params[:view_id]
		if @tag.valid?
			@tag.save()
			flash[:notice] = "Tag saved successfully!"
			render :text=>@tag.id
		else
			render :text=>"-1"
		end
	end
	
	def get_tags
		@tags = Tag.find(:all ,:conditions=>"view_id=="+params[:view_id])
		render :text => @tags.to_json
	end
	
	def remove_tags
		Tag.delete(params[:id].to_i)
		render :text =>""
	end
	
end
