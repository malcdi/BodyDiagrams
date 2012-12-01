function CommentController (callback){

	this.cvState = null;
	this.annotatorBoxElem = $("#annotator");
	this.callback = callback;

	this.setCVState = function(cvState){
		this.cvState =cvState;
	}

	

	this.saveTagAnnotations = function(newTagContainer, index)
	{

		var severity = newTagContainer.find(".pain_severity").slider("value")/20+1;
		var typeText = newTagContainer.find(".pain_type>#pain_type_tags").val();
		var posture = newTagContainer.find(".pain_posture>.tag-selected")[0].innerText;
		var layer = newTagContainer.find(".pain_layer>.tag-selected")[0].innerText;
		var text = newTagContainer.find(".pain_annotation").val();

		this.cvState.saveTagAnnotation(index, severity, typeText, posture, layer, text);
	}

	this.editDone = function(index){
		//highlight or giving full widget to the element with index
		//transition animation

		//first one
		var newTagContainer = $("#pain_annotation_list>li:nth-child(1)>div");
		
		this.saveTagAnnotations(newTagContainer, index);

		newTagContainer.find(".symptom_id").text(index);

		var listIndex = this.cvState.allTags.length-(index+1);
		this.animateControl(listIndex, false);

		var self=this;
	}
	this.createNew = function(index){
		var newTagContainer = $("#annotator>div").clone();
		var self=this;

		newTagContainer.find(".pain_severity").slider({
			min: 1,
			max: 10,
			value: 3,
			slide: function(event, ui) {
				var painType = newTagContainer.find(".pain_type>.tag-selected").text();
				var newCol = cvState.updateGraphics(index, ui.value-1 ,painType);
				$(this).find("a")[0].style.backgroundImage="none";
				$(this).find("a")[0].style.backgroundColor= newCol;
				cvState.highlightCloud(index);
				self.saveTagAnnotations(newTagContainer, index);
			}
		});

		newTagContainer.find(".annotator-tag").click(function(){
			var children = this.parentElement.children;
			for (var id in children){
				var classes=children[id].classList;
				if(classes!=undefined && classes.contains("annotator-tag") &&
					(classes.contains("tag-selected") || children[id]==this))
				{
					$(children[id]).toggleClass("tag-selected");
				}
			}

			self.saveTagAnnotations(newTagContainer, index);
		});

		newTagContainer.find(".annotator-type-tag").click(function(){
			var pastStr = newTagContainer.find(".pain_type_tags").val();
			if(pastStr.indexOf($(this).text())<0){
				pastStr+=$(this).text() +", ";
				newTagContainer.find(".pain_type_tags").val(pastStr);
			}
		});

		newTagContainer.find(".pain_severity").slider("value", 3);
		newTagContainer.find(".pain_severity").find("a")[0].style.backgroundColor="#FCBBA1";
		newTagContainer.find(".symptom_id").text(index);

		$("#pain_annotation_list").prepend("<li></li>");
		$("#pain_annotation_list>li:nth-child(1)").append(newTagContainer);
		

		var self= this;
		self.collapseAll();

		newTagContainer.ready(function(){
			self.animateControl(0, true);
			newTagContainer.attr("id", "tag_"+index);
		});

		var self = this;
		newTagContainer.click(function(obj){
			//collapse other if any
			self.collapseAll();
			cvState.deHighlightCloud();

			//EXPAND
			var index = parseInt(this.id.match("tag_([0-9]+)")[1]);
			
			var listIndex = self.cvState.allTags.length-(index+1);
			self.animateControl(listIndex, true);
			cvState.highlightCloud(index);

		});
	}
	this.collapseAll = function(){
		//collapse all others
		for(var i=0; i<self.cvState.allTags.length; i++){
			this.animateControl(i, false);
		}
			
	}
	this.animateControl = function(index, expand){
		var elemId = "#pain_annotation_list>li:nth-child("+(index+1)+")>div";
		var listElem = $(elemId);
		var expanding = expand?'block':'none';

		listElem.find(".pain_severity").css({
			'display': expanding
		});
		listElem.find(".pain_type").css({
			'display': expanding
		});
		listElem.find(".pain_layer").parent().css({
			'display': expanding
		});
		listElem.find(".pain_posture").parent().css({
			'display': expanding
		});

		listElem.find(".pain_severity_collapsed").css({
			'display': expand?'none':'block'
		});

		listElem.css({
			'opacity': expand? 1.0:0.4
		});

	}
}