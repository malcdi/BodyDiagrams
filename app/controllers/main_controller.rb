class MainController < ApplicationController
	def app
		@user = User.create(:gender=>params[:gender])
		session[:user_id] = @user.id
	end

	def review
		user = User.find(params[:user_id])
		@gender = user.gender
		allTags = Tag.order("id").find(:all, :conditions=> 'user_id='+params[:user_id])
		@result_arr =[]
		allTags.each do |tag|
			gId = tag.tag_group
			if @result_arr[gId]==nil
				@result_arr[gId] = []
			end
			t ={}
			t["properties"] = {}
			t["properties"]["prop_annotation"] = tag.annotate
			t["properties"]["prop_severity"] = tag.severity
			t["properties"]["prop_posture"] = tag.posture
			t["view_side"] = tag.view_side

			if HandTag.exists?(:tag_id=>tag.id) 
				graphTag = HandTag.find(:all, :conditions=>'tag_id='+tag.id.to_s)[0]
				ar = eval(graphTag.points)
				t["data"] = ar.map do |d| 
					{"x"=>d[0], "y"=>d[1]}
				end
				t["type"] = "hand"
			elsif RegionTag.exists?(:tag_id=>tag.id) 
				graphTag = RegionTag.find(:all, :conditions=>'tag_id='+tag.id.to_s)[0]
				t["data"] = {"x"=>graphTag.x, "y"=>graphTag.y, "w"=>graphTag.w, "h"=>graphTag.h}
			
				t["type"] = "region"
			end
			@result_arr[gId].push(t)
		end
		# result:
		# [[{type, data, view_side, properties:{}}, {}, {}(tag)],[],[](frame)](all)
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
					if tagProperty["prop_annotation"]==nil
						tagProperty["prop_annotation"] = ""
					end
					if tagProperty["prop_severity"]==nil
						tagProperty["prop_severity"] = -1
					end
					if tagProperty["prop_posture"]==nil
						tagProperty["prop_posture"] = ","
					end
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
