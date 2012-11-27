function ModeStateHandler (commentController, cvState){
	this.newSymptom = false; //new symptom initialized.
	this.zoomMode = true;
	this.zoomElem = $("#zoom");
	this.drawElem = $("#draw");
	this.drawSetElem = $("#drawSet");
	this.newSymptomElem = $("#newDraw");
	this.symptomTitleElem = $("#symptomTitle");
	this.annotatorBoxElem = $("#annotator");
	this.doneElem = $("#done_button");
	this.commentController = commentController;
	this.cvState = cvState;


	this.handleEvents = function (clickedName, arg){
		if(clickedName=="zoom"){
			this.zoomMode = true;
			this.cvState.setMode("zoom");

			this.zoomElem[0].src = '/assets/dragHand.png';
			this.zoomElem[0].style.border ="solid 2px rgb(108, 204, 128)";

			this.drawElem[0].src = '/assets/drawIconInactive.png';
			this.drawElem[0].style.border ="solid 2px rgb(108, 204, 128)";
			this.drawElem[0].style.border ="";

			if(!this.newSymptom){
				this.drawSetElem.css("opacity", 0.0);
			}

		}
		if(clickedName =="draw"){
			this.zoomMode = false;
			this.cvState.setMode("draw");
			this.drawElem[0].src = '/assets/drawIcon.png';
			this.drawElem[0].style.border ="solid 2px rgb(108, 204, 128)";

			this.zoomElem[0].src = '/assets/dragHandInactive.png';
			this.zoomElem[0].style.border ="";

			this.drawSetElem.css("opacity", 1.0);
		}
		else if(clickedName =="newDraw"){
			if (this.newSymptom){
				//was drawing: done -> new 
				this.doneElem.trigger("click");
			}
			this.zoomMode = false;
			this.newSymptom = true;

			this.annotatorBoxElem.css("opacity",1.0);
			this.symptomTitleElem.css("display", "inline-block");
			this.symptomTitleElem.text("Symptom "+arg); //arg=cvState.tagCloud+1
			this.doneElem.css("display", "block");


			var handler = this;
			this.drawElem.bind('click', function(){
				return handler.handleEvents("draw", this.cvState);
			});
			this.drawElem.trigger("click");

			this.cvState.startRecordingNewMsg();
			this.cvState.deHighlightCloud();

			//creates new element in the list
			this.commentController.edit(arg);//selecting the index to be edited
			

			this.newSymptomElem[0].src = '/assets/plus.png';
			
		}
		else if(clickedName =="done"){
			this.newSymptom = false;
			this.drawElem.unbind('click');

			//this.commentController.updateAnnotations(this.cvState.allTags[arg], arg);
			this.commentController.createNew(arg);
			this.commentController.editDone(arg);

			this.doneElem.css("display", "none");
			this.symptomTitleElem.css("display", "none");
			this.annotatorBoxElem.css("opacity",0.0);

			this.cvState.stopRecordingNewMsg();
			this.cvState.deHighlightCloud();

			this.zoomElem.trigger("click");
		}
	}

}