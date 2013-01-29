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

				tagProperty = tagInfo["property"]
				@tag.user_id=user.id
				@tag.annotate=tagProperty["prop_annotation"]
				@tag.severity=tagProperty["prop_severity"]
				@tag.posture=tagProperty["prop_freq"].join(",")
				debugger

				@tag.view_side=tagInfo["view"]
				@tag.tag_group=tagGroupIndex
				if @tag.valid?
					@tag.save()
					#save points
					handTag = HandTag.new()
					handTag.points=tagInfo["points"].to_s()
					handTag.tag_id=@tag.id
					handTag.save()
				end
			end
		end
		render :text=> "success"
	end

end
