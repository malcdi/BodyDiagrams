function CommentController (){

	this.cvState = null;

	this.setCVState = function(cvState){
		this.cvState =cvState;
	}

	

	this.saveTagAnnotations = function(tags, severity, type, posture, depth, text)
	{
		for (var i =0; i<tags.length; i++){
			tags[i].saveTagAnnotation(severity, type, posture, depth, text);
		}
	}

	this.edit = function(index){
		//highlight or giving full widget to the element with index
		//transition animation

	}

	this.editDone = function(index){
		//highlight or giving full widget to the element with index
		//transition animation
		
	}
	this.createNew = function(index){
		var tags = this.cvState.allTags[index];
		
		var severity = $(".pain_severity").slider("value")/20+1;
		var typeText = $(".pain_type>#pain_type_tags").val();
		var posture = $(".pain_posture>.tag-selected")[0].innerText;
		var depth = $(".pain_depth").slider("value")/20+1;
		var text = $("#annotator").find(".pain_annotation").val();
		
		$(".pain_severity").slider("value", 0);
		$(".pain_depth").slider("value",0);
		$("#annotator").find(".pain_annotation").val("");
		
		this.saveTagAnnotations(tags, severity, typeText, posture, depth, text);
		
		var newTagContainer = $('<li><div class="annotator-widget annotator-list" style="position:static;"><ul class="annotator-listing"> <li class="annotator-item"><div class="symptom_id"></div></li><li class="annotator-item"><div class="pain_type"> </div></li><li class="annotator-item"><textarea class="pain_annotation" placeholder="Comments…" rows= "4"></textarea> </li> </ul></div></li>');

		var newTextArea = newTagContainer.find(".pain_annotation");
		newTextArea[0].value = text;

		$(".pain_severity").slider("value", 3);
		$(".pain_severity").find("a")[0].style.backgroundColor="#FCBBA1";

		$(".pain_depth").slider("value",0);
		$("#pain_type_tags").val("");
		$("#annotator").find(".pain_annotation").val("");
		$("#pain_annotation_list").prepend(newTagContainer);
		newTagContainer.ready(function(){
			newTagContainer.find(".pain_annotation").attr("id", "tag_"+index);
			newTagContainer.find(".pain_type").text("Symptom Type: "+typeText);
			newTagContainer.find(".pain_annotation")[0].value = text;
			newTagContainer.find(".symptom_id").text("Symptom "+index); 

			newTagContainer.find(".pain_annotation").focus(function(obj){
				var index = this.id.match("tag_([0-9]+)")[1];
				this.tagSelectionUpdate(index,true);

				//EXPAND
			});
			newTagContainer.find(".pain_annotation").focusout(function(obj){
				var index = this.id.match("tag_([0-9]+)")[1];
				this.tagSelectionUpdate(index,false);

				//COLLAPSE
			});

		});
		
	}
}