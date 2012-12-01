class MainController < ApplicationController
	def app
		@user = User.create(:gender=>params[:gender])
		session[:user_id] = @user.id
	end
	
	def postGraphicTag
		tagId=params[:tagId]
		#saving freeHand points
		hand=JSON.parse(params[:freeHand])
		hand.each do |elem|
			handTag = HandTag.new()
			handTag.points=elem["points"].to_s();
			handTag.view_side=elem["view"].to_s();
			handTag.tag_id=tagId
			handTag.save()
		end
									
=begin
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
=end
		render :text=>tagId.to_s+"good"
	end
	
	def postTag
		puts "*******"
		puts session[:user_id]
		user = User.find(session[:user_id])

		allTags = JSON.parse(params[:tagData])
		tagArr=[]
		returnStr=""
		allTags.each do |tagInfo|
			@tag = Tag.new()

			@tag.user_id=user.id
			@tag.annotate=tagInfo["annotate"]
			@tag.severity=tagInfo["severity"]
			@tag.layer=tagInfo["layer"]
			@tag.type=tagInfo["type"]
			@tag.posture=tagInfo["posture"]
			if @tag.valid?
				@tag.save()
				tagArr.push(@tag.id)
			else
				tagArr.push(-1)
			end
		end
		render :text=>tagArr.to_s
	end

end
