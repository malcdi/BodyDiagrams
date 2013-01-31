class MainController < ApplicationController
	def app
		@user = User.create(:gender=>params[:gender])
		session[:user_id] = @user.id
	end
	
	def postTag
		puts "*******"
		puts session[:user_id]
		user = User.find(session[:user_id])
		allTags = JSON.parse(params[:tagData])

		allTags.each_index do |tagGroupIndex|
			tagGroup = allTags[tagGroupIndex]
			tagGroup.each do |tagInfo|
				puts tagInfo
				@tag = Tag.new()
				@tag.user_id=user.id

				tagProperty = tagInfo["property"]
				if !tagProperty.empty?
					@tag.annotate=tagProperty["prop_annotation"]
					@tag.severity=tagProperty["prop_severity"]
					@tag.posture=tagProperty["prop_posture"].join(",")
				end

				@tag.view_side=tagInfo["view"]
				@tag.tag_group=tagGroupIndex
				if @tag.valid?
					@tag.save()
					type = tagInfo["type"]
					if type=="hand"
						#save points
						handTag = HandTag.new()
						handTag.points=tagInfo["points"].to_s()
						handTag.tag_id=@tag.id
						handTag.save()
					elsif type=="region"
						rectTag = RegionTag.new()
						rect = tagInfo["rect"]
						rectTag.x = rect["x"]
						rectTag.y = rect["y"]
						rectTag.w = rect["w"]
						rectTag.h = rect["h"]
						rectTag.tag_id=@tag.id
						rectTag.save()
					end
				end
			end
		end
		render :text=> "success"
	end

	def logEvent
		user = User.find(session[:user_id])
		event = Event.new()
		event.target = params[:targetName]
		event.action = params[:actionName]
		event.user_id = user.id
		event.save()

		render :text=>"success"
	end

end
