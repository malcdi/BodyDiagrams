class MainController < ApplicationController
	def draw
		@tag = Tag.new
		#temporary.. to be changed
		@cur_view=View.find(:all)[0]
	end
	
	def get_view
		@cur_view=View.find(:all)[params[:view_num].to_i]
		render :text =>@cur_view.to_json
	end
	
	def post_tag
		if params[:id].to_i==-1
			@tag = Tag.new()
		else
			@tag=Tag.find(params[:id])
		end
		
		@tag.origin_x=params[:origin_x]
		@tag.origin_y=params[:origin_y]
		@tag.width=params[:width]
		@tag.height=params[:height]
		@tag.pain_type=params[:pain_type]
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
