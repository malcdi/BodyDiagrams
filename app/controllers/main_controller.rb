class MainController < ApplicationController
	def app
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
	
	def postTag
		@user = User.create(:gender=>params[:gender], :age=>params[:age])
		allTags = JSON.parse(params[:tagData])
		tagArr=[]
		returnStr=""
		allTags.each do |tagInfo|
			@tag = Tag.new()
			@tag.user_id=@user.id
			@tag.annotate=tagInfo["annotate"]
			@tag.severity=tagInfo["severity"]
			@tag.depth=tagInfo["depth"]
			@tag.view_side=tagInfo["view_side"]
			if @tag.valid?
				@tag.save()
				tagArr.push(@tag.id)
			else
				tagArr.push(-1)
			end
		end
		render :text=>tagArr.to_s
	end
	
	#### NOT USED ANYMORE ######
	def submitDraw
		#temporary.. to be changed
		@cur_view={:body_part=>"whole", :view_side=>0}
		@user = User.new()
		@user.saved=false
	end
	
	def draw
		@tag = Tag.new
		#temporary.. to be changed
		@cur_view={:body_part=>"whole", :view_side=>0}
	end
	
	def get_view
		@cur_view=View.find(:all)[params[:view_num].to_i]
		render :text =>@cur_view.to_json
	end
	
	def get_tags
		@tags = Tag.find(:all ,:conditions=>"view_id=="+params[:view_id])
		render :text => @tags.to_json
	end
	
	def remove_tags
		Tag.delete(params[:id].to_i)
		render :text =>""
	end
	########################

end
