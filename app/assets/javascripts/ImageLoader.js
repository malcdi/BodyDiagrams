var ImageLoader = new function(){
	this.bodyImages = {};
	this.gender = ["female", "male"];
	this.views = [0,1, 2, 3];
	for (var i in this.views){
		for (var j in this.gender){
			var key = this.gender[j] + "_"+this.views[i];
			this.bodyImages[key] = new Image();
			this.bodyImages[key].src= "/assets/"+key+".png";
		}
	}
	
	this.getBodyImage = function(gender, index){
		return this.bodyImages[gender+"_"+index];
	}
	
	this.getBodyImageSrc = function(gender, index){
		return this.bodyImages[gender+"_"+index].src;
	}
	
	this.painPatterns = {};
	this.painTypes = ["Sharp", "Dull", "Numb"];
	this.painSeverity = [1, 2, 3,4,5]
	for (var i in this.painSeverity){
		for (var j in this.painTypes){
			var key = this.painTypes[j] + "_"+this.painSeverity[i];
			this.painPatterns[key] = new Image();
			var pngName = "";
			if(this.painTypes[j]=="Sharp")
				pngName="cross";
			else if(this.painTypes[j]=="Numb")
				pngName="dot";
			else if(this.painTypes[j]=="Dull")
				pngName="cross";
			this.painPatterns[key].src = "/assets/pain_type/"+pngName+"_"+this.painSeverity[i]+".png";
		}
	}
	
	this.getPainPatternImage = function(type, severity){
		return this.painPatterns[type+"_"+severity];
	}
};
