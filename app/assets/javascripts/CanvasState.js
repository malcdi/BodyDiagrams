function CanvasState(canvas, options) {

	// fixes mouse co-ordinate problems when there's a border or padding
	// see getMouse for more detail
	if (document.defaultView && document.defaultView.getComputedStyle) {
		stylePaddingLeft = parseInt(document.defaultView.getComputedStyle(canvas, null)['paddingLeft'], 10)      || 0;
		stylePaddingTop  = parseInt(document.defaultView.getComputedStyle(canvas, null)['paddingTop'], 10)       || 0;
		styleBorderLeft  = parseInt(document.defaultView.getComputedStyle(canvas, null)['borderLeftWidth'], 10)  || 0;
		styleBorderTop   = parseInt(document.defaultView.getComputedStyle(canvas, null)['borderTopWidth'], 10)   || 0;
	}

	this.line = d3.svg.line()
		.x(function(d) { return d.x; })
		.y(function(d) { return d.y; })
		.interpolate("linear");
	
	//this.allTags=[];//all the tags on canvas
	this.allTags = [];   //graphic tags
	this.allTagData =[]; //annotated tags

	//for drawing
	this.dragging = false; // Keep track of when we are dragging


	this.mouseDownForFreeHand=false;
	
	//for resizing
	// Holds the 8 tiny boxes that will be our selection handles
	// the selection handles will bse in this order:
	// 0  1  2
	// 3     4
	// 5  6  7
	this.selectionHandles = [];
	
	// the current selected object.
	this.regionSelection = null;
	this.handSelection=null;
	this.dragoffx = 0; 
	this.dragoffy = 0;
	this.strokeWidth = 3;

	//recording states
	this.tagCloud = -1;
	this.highlightTagCloud = -1;
	this.recording = false;
	
	
	//SETS up using options
	this.gender = options.gender ? options.gender : "male";
	this.cur_view_side = options.view ? options.view : 0;
	this.mode = options.mode ? options.mode : "zoom";
	this.imageLoader = options.imageLoader;
	this.selectCallback = options.selectCallback;
	
	this.lastX=canvas.width/2;
	this.lastY=canvas.height/2;

	
	// Zoom related variables
	this.canvas = document.getElementById("canvasDiv");
	this.heightRatio=this.canvas.height/this.canvas.width;
	this.highlightRegion = new RegionTagCanvasElem(5, 5,0, 0, '#CCEEFF');//region element within main view.
	this.needRedraw = true;
	this.cur_view_side=0;
	
	//DEBUG
	
	console.log(document.getElementById("canvasDiv"));
	/*d3.select("#canvasDiv")
	.attr("onmouseover", "alert('x')");*/
	//DEBUG
	
	
	/* registering mouse events */
	var myState = this;
	var canvasDivW = 500;
	var canvasDivH = 730;
	this.svg= d3.select("#canvasDiv").append("svg")
		.attr("width", canvasDivW)
		.attr("height",canvasDivH);
	/*
	var markerDef = this.svg.append("defs");
	markerDef.append("marker")
			.attr("id", "numb_pattern")
			.attr("viewBox", "0 0 5 5")
			.attr("refX", 1)
			.attr("refY", 1)
			.attr("markerWidth", 3)
			.attr("markerHeight", 3)
		.append("image")
			.attr("patternUnits", "objectBoundingBox")
			.attr("xlink:href", this.imageLoader.getPainPatternImageSrc("Numb", 1))
			.attr("x", 0)
			.attr("y", 0)
			.attr("width", 3)
			.attr("height", 3);
	markerDef.append("marker")
					.attr("id", "dull_pattern")
					.attr("viewBox", "0 0 5 5")
					.attr("refX", 1)
					.attr("refY", 3)
					.attr("markerWidth", 3)
					.attr("markerHeight", 3)
				.append("image")
					.attr("patternUnits", "objectBoundingBox")
					.attr("xlink:href", this.imageLoader.getPainPatternImageSrc("Dull", 1))
					.attr("x", 0)
					.attr("y", 0)
					.attr("width", 3)
					.attr("height", 3);
	markerDef.append("marker")
					.attr("id", "sharp_pattern")
					.attr("viewBox", "0 0 5 5")
					.attr("refX", 1)
					.attr("refY", 3)
					.attr("markerWidth", 3)
					.attr("markerHeight", 3)
				.append("image")
					.attr("patternUnits", "objectBoundingBox")
					.attr("xlink:href", this.imageLoader.getPainPatternImageSrc("Sharp", 1))
					.attr("x", 0)
					.attr("y", 0)
					.attr("width", 3)
					.attr("height", 3);			
	*/
	this.strokeWidthGuider = this.svg.append("path")
		.attr("id", "strokeWidthGuider")
		.attr("d","M100,20L110,20L120,20L130,20L140,20")
		.style("stroke-width", this.strokeWidth)
		.style("fill","none")
		.style("stroke",colorSelector(2))
		.style("opacity", 0);
		
	this.svg = this.svg.append("g")
		.on('selectstart', getEventHandler('selectstart',myState))
		.on('mouseup', getEventHandler('mouseup',myState))
		.on('mousewheel', getEventHandler('mousewheel',myState))
		.on('mousedown', getEventHandler('mousedown',myState))
		.on('mousemove', getEventHandler('mousemove',myState));


		
	this.srcImg = this.svg.append("image")
		.attr("x", (canvasDivW-300)/2)
		.attr("y",(canvasDivH-700)/2)
		.attr("width",300)
		.attr("height",700)
		.attr("xlink:href",ImageLoader.getBodyImageSrc(this.gender, this.cur_view_side));
		
	this.tracker ={};
	trackSVGTransforms(this.tracker, document.createElementNS("http://www.w3.org/2000/svg","svg"));
	
		
	//fixes a problem where double clicking causes text to get selected on the canvas
	$("#canvasDiv").find("svg").bind('selectstart', getEventHandler('selectstart',myState));
	
	/* double click for making new regionTags
	canvas.addEventListener('dblclick', function(e) {
		var mouse = myState.getMouse(e);
		myState.regionSelection=new RegionTagCanvasElem(mouse.x - 10, mouse.y - 10, 20, 20,
 'rgba(0,255,0,.6)');
		myState.addRegionTagCanvasElem(myState.regionSelection);
		myState.isResizeDrag=true;
	}, true);*/
	
	/* For Resize */
	// set up the selection handle boxes
	for (var i = 0; i < 8; i ++) {
		var rect = new RegionTagCanvasElem;
		this.selectionHandles.push(rect);
	}
}

//setting view side (front? left? etc)
CanvasState.prototype.setView= function(view){
	this.cur_view_side = view;
	this.srcImg.attr("xlink:href",ImageLoader.getBodyImageSrc(this.gender, this.cur_view_side));
	var highlight="HIGHLIGHTTAG";
	if(this.highlightTagCloud>=0)
		highlight="tag_"+this.highlightTagCloud;
	this.svg.selectAll("g").style("opacity",function(d){
		if(this.classList.contains("side_"+view))
			return this.classList.contains(highlight)? 1.0:0.3;
		else if(this.id=="strokeWidthGuider")
			return this.classList.contains(highlight)? 1.0:0.3;
		else return 0;
	});
	this.deHighlightCloud();
}
CanvasState.prototype.getView= function(){
	return this.cur_view_side
}

/*addint & removing tag elements from the allTags*/
CanvasState.prototype.addRegionTagCanvasElem = function(elem){
	this.allTags[this.tagCloud].allTags.push(elem);
	this.needRedraw=true;
}

CanvasState.prototype.addFreeHandTagCanvasElem = function(elem, cloud){
	var list = this.allTags[cloud];
	list.push(elem);
}

CanvasState.prototype.undoLastDrawing = function(){
	this.allTags[this.tagCloud].pop();
	var grouper = this.svg.select(".tag_"+this.tagCloud);
	if(!grouper.empty())
	{
		grouper.select(":last-child").remove();
		if(grouper.selectAll("path")[0]==null){
			grouper.remove();
			this.tagCloud-=1;
		}
	}
}

// Creates an object with x and y defined,
// set to the mouse position relative to the state's canvas
// If you wanna be super-correct this can be tricky,
// we have to worry about padding and borders
CanvasState.prototype.getMouse = function(e) {
	var element = this.canvas, offsetX = 0, offsetY = 0, mx, my;

	// Compute the total offset
	if (element.offsetParent !== undefined) {
		do {
			offsetX += element.offsetLeft;
			offsetY += element.offsetTop;
		} while ((element = element.offsetParent));
	}
	mx = e.pageX - offsetX;
	my = e.pageY - offsetY;

	// We return a simple javascript object (a hash) with x and y defined
	return {x: mx, y: my};
}


//save all the annotated tags
CanvasState.prototype.submitAll = function(gender, age){
	if(this.allTagData.length==0){
		alert("please express your symptoms!");
		return;
	}
	var self=this;
	$.ajax({
		type: "GET",
		url: "postTag",
		data: {"tagData": JSON.stringify(self.allTagData), "gender":gender, "age":age}
	}).done(function( tagIdArr ) {
		self.submitGraphicTags(JSON.parse(tagIdArr));//array of tag ids returned.
	});
}

//save graphic tag information for each tag associated.
CanvasState.prototype.submitGraphicTags = function(tagIdArr){
	var self=this;
	var l = this.allTags.length;
	if (l==0){
		self.submitComplete();
	}
	else{
		for (var j = 0; j < l; j++) {
			var tags = this.allTags[j];
			var len = tags.length;
			
			$.ajax({
				type: "POST",
				url: "postGraphicTag",
				data: {"tagId":tagIdArr[j], "freeHand":JSON.stringify(tags)}
			}).done(function( msg ) {
				//on last tag data submission
				if(j==l) self.submitComplete();
			});
		}
	}
}

//called after submission completed
CanvasState.prototype.submitComplete = function(){
	alert("complete");
	window.location="/main/complete"
}


CanvasState.prototype.startRecordingNewMsg = function(){
	this.tagCloud +=1;
	this.allTags.push([]);
	this.recording = true;
}

CanvasState.prototype.stopRecordingNewMsg = function(){
	//cur group
	var grouper = this.svg.select(".side_" + this.cur_view_side + ".tag_" + this.tagCloud);

	if(! grouper.empty()){
		grouper.style("opacity",0.3);
	}

	this.recording = false;
}

CanvasState.prototype.setStrokeWidth = function(width){
	this.strokeWidth = width;
	this.strokeWidthGuider.style("stroke-width", this.strokeWidth);
}

//flush data of current canvas state.
//called when submit button clicked, or view rotated
CanvasState.prototype.flush = function(){
	this.allTags=[];
}

CanvasState.prototype.deHighlightCloud = function(){
	var bbox = this.svg.select("#boundingBox");
	if(!bbox.empty())
		bbox.style("opacity", 0);

	//except when the recent
	if(this.recording && (this.highlightTagCloud==this.allTags.length-1)) return;

	var grouper = this.svg.select(".side_" + this.cur_view_side + ".tag_" + this.highlightTagCloud);
	if(!grouper.empty()){
		grouper.style("opacity", 0.3);
	}
	this.highlightTagCloud=-1;
}

CanvasState.prototype.highlightCloud = function(index){

	if(index<0) index = this.allTags.length-1;

	var cloudElems = this.allTags[index];
	if(!cloudElems || cloudElems.length<1) return;
	//ignore if in diff view
	if(cloudElems[0].view!=this.cur_view_side) return;

	this.deHighlightCloud();

	this.highlightTagCloud = index;
	var grouper = this.svg.select(".side_" + this.cur_view_side + ".tag_" + this.highlightTagCloud);
	if(!grouper.empty()){
		grouper.style("opacity", 0.7);
	}


	var boundingBox = {"x1":1000,"y1":1000,"x2":0,"y2":0};
	//find bounding region for this cloud
	for(var i=0; i<cloudElems.length; i++){
		var tagElem = cloudElems[i];
		if(tagElem.minX<boundingBox["x1"])
			boundingBox["x1"] = tagElem.minX;
		if(tagElem.minY<boundingBox["y1"])
			boundingBox["y1"] = tagElem.minY;
		if(tagElem.maxX>boundingBox["x2"])
			boundingBox["x2"] = tagElem.maxX;
		if(tagElem.maxY>boundingBox["y2"])
			boundingBox["y2"] = tagElem.maxY;
	}
	var bbox = this.svg.select("#boundingBox");
	if(bbox.empty())
		bbox = this.svg.append("rect").attr("id", "boundingBox");

	bbox.attr("x", boundingBox["x1"])
		.attr("y", boundingBox["y1"])
		.attr("width", boundingBox["x2"] - boundingBox["x1"])
		.attr("height", boundingBox["y2"] - boundingBox["y1"])
		.style("fill", "#7BCCC4")
		.style("stroke", "#43A2CA")
		.style("stroke-width", 3)
		.style("fill-opacity", "0.05")
		.style("opacity", 1.0);
}

CanvasState.prototype.highlightAllTags = function(index){
	//if(index<0) this.highlightTagCloud = this.allTags.length -1;
	if(index!=-1) this.regionSelection = null;
	if(index==-2) this.highlightTagCloud = this.allTags.length -1;
	else this.highlightTagCloud = index;
}

CanvasState.prototype.setMode = function(modeName){
	this.mode=modeName;
	if(this.mode=="zoom"){
		this.canvas.style.cursor="url('/assets/dragHand.png'), auto";
		this.strokeWidthGuider.style("opacity",0);
	
	}
	else if(this.mode=="draw"){
		this.canvas.style.cursor="url('/assets/drawHand.png'), auto";
		this.strokeWidthGuider.style("opacity",1.0);
	}
}

CanvasState.prototype.updateGraphics = function(index, severity, type){
	var grouper = this.svg.select(".side_" + this.cur_view_side + ".tag_" + index);
	var col = colorSelector(severity);
	if(!grouper.empty()){
		grouper.selectAll("path").style("stroke", col);
	}

	return col;
	/*
	var newPattern = this.ctx.createPattern(this.imageLoader.getPainPatternImage(type, severity), "repeat");
	theTag.setStyle(newPattern);*/
}

CanvasState.prototype.saveTagAnnotation = function(index, severity, type, posture, layer, annotation){
	var tagInfo= {
		"severity":severity,
		"annotate": annotation,
		"layer": layer,
		"type":type,
		"posture":posture
	}
	this.allTagData[index]=tagInfo;
}

CanvasState.prototype.setZoomPan = function(deltaX, deltaY, deltaZoom){
	this.tracker.translate(deltaX, deltaY);
	this.lastX = this.canvas.width/2;
	this.lastY = this.canvas.height/2;
	zoom(deltaZoom, this);
}

function getEventHandler(name, myState){
	
 	return function(e){
		if(myState.mode=="draw")	
			CanvasDrawEventHandler[name](d3.event, myState);
		else if(myState.mode=="zoom")	
			CanvasZoomEventHandler[name](d3.event, myState);
	};
}

var CanvasZoomEventHandler={
	'mousedown': function(e, myState) {
		e.preventDefault();
		var mouse = myState.getMouse(e);
		var globalPoint = myState.tracker.transformedPoint(mouse.x, mouse.y);
		
		//see if selection occured
		
		var selectedCloud = -1;
		for (var i = 0; i < myState.allTags.length; i++) {
			var curTagL = myState.allTags[i];
			var l = curTagL.length;
			for(var j=0; j<l; j++){
				if (curTagL[j].cur_view_side ==myState.cur_view_side && curTagL[j].contains(globalPoint.x, globalPoint.y)) 			
				{
					myState.selectCallback(curTagL.indexOf(myState.regionSelection),false);
					myState.regionSelection = curTagL[j];	
					myState.selectCallback(i,true);

					myState.dragging = true;
					myState.dragoffx = globalPoint.x;
					myState.dragoffy = globalPoint.y;
					return;
				}

			}
		}
		myState.selectCallback(selectedCloud,false);
		myState.regionSelection = null;
		
		myState.lastX = e.offsetX || (e.pageX - myState.canvas.offsetLeft);
		myState.lastY = e.offsetY || (e.pageY - myState.canvas.offsetTop);
		myState.dragStart = myState.tracker.transformedPoint(myState.lastX,myState.lastY);
	},
	'mousemove': function(e, myState) {
		e.preventDefault();
		myState.lastX = e.offsetX || (e.pageX - canvas.offsetLeft);
		myState.lastY = e.offsetY || (e.pageY - canvas.offsetTop);
		if (myState.dragStart){
			var pt = myState.tracker.transformedPoint(myState.lastX,myState.lastY);
			var newMat = myState.tracker.translate(pt.x-myState.dragStart.x,pt.y-myState.dragStart.y);
			myState.svg.attr("transform", "matrix("+newMat.a+","+newMat.b+","+newMat.c+","+newMat.d+","+newMat.e+","+newMat.f+")");
		}
		
		/* Non Free Hand */
		if (myState.dragging){
			var mouse = myState.getMouse(e);
			var globalPoint =myState.tracker.transformedPoint(mouse.x, mouse.y);
			
			myState.regionSelection.moveAll(globalPoint.x - myState.dragoffx, globalPoint.y - myState.dragoffy);
			myState.dragoffx = globalPoint.x;
			myState.dragoffy = globalPoint.y;		
		}
	},
	'mouseup': function(e, myState) {
		myState.dragStart = null;
		myState.dragging = false;
	},
	'mousewheel':function(e,myState) { 
		var delta = e.originalEvent.wheelDelta ? e.originalEvent.wheelDelta/40 : e.originalEvent.detail ? e.originalEvent.detail : 0;
		if (delta) zoom(delta,myState);
		return e.preventDefault() && false;
	}
}

var CanvasDrawEventHandler={
	'mousedown': function(e, myState) {
		if(! myState.recording) return;
		myState.regionSelection = null;
		
		e.preventDefault();
		
		var mouse = myState.getMouse(e);
		
		/* Free Hand Drawing */

		myState.mouseDownForFreeHand = true;
		myState.handSelection=new FreeHandTagCanvasElem('#F89393', myState.cur_view_side);
		
		var globalPoint = myState.tracker.transformedPoint(mouse.x, mouse.y);
		myState.handSelection.addPoint(globalPoint.x, globalPoint.y);
		
		var tagCloudGroup = myState.tagCloud;
		if(myState.highlightTagCloud>=0)
			tagCloudGroup = myState.highlightTagCloud;

		myState.addFreeHandTagCanvasElem(myState.handSelection, tagCloudGroup);

		var grouper = myState.svg.select(".tag_" + tagCloudGroup);

		var strokeColor = colorSelector(2);
		if(grouper.empty())
			grouper = myState.svg.append("svg:g")
				.attr("class", "side_" + myState.cur_view_side + " tag_" + tagCloudGroup)
				.attr("opacity", 0.7);
		else{
			strokeColor = grouper.select("path").style("stroke");
		}

		myState.deHighlightCloud();

		myState.curElemG = grouper.append("svg:path")
				.style("stroke-width", myState.strokeWidth)
				.style("fill","none")
				.style("stroke",strokeColor)
				.attr("d", myState.line(myState.handSelection.points));
		}
		,
		
	'mousemove': function(e, myState) {
			var mouse = myState.getMouse(e);
			e.preventDefault();
			/*Free Hand Drawing*/
			if(myState.mouseDownForFreeHand){
				var globalPoint = myState.tracker.transformedPoint(mouse.x, mouse.y);
				myState.handSelection.addPoint(globalPoint.x, globalPoint.y);

				myState.curElemG.attr("d",myState.line(myState.handSelection.points));
				return;
			}
		},
	'mouseup': function(e, myState) {
			
			if(myState.mouseDownForFreeHand){
				myState.mouseDownForFreeHand = false;
				
				if(!myState.handSelection.isValidElem()){
					myState.undoLastDrawing();
					//take out from the svg. myState.curElemG
				}
				else {
					myState.regionSelection = myState.handSelection;
					//myState.selectCallback(myState.tagCloud, true);
					myState.curElemG.attr("d",myState.line(myState.handSelection.points));
				}				
				var mouse = myState.getMouse(e);
				return;
			}
			myState.dragging = false;
		},
		'mousewheel':function(e,myState) {
			return false;
		},
	'selectstart': function(e,myState) { 
			e.preventDefault(); return false; }
};


var colorSelector = function(severity){
	if(severity==0)
		return "#FFF5F0";
	else if(severity==1)
		return "#FEE0D2";
	else if(severity==2)
		return "#FCBBA1";
	else if(severity==3)
		return "#FC9272";
	else if(severity==4)
		return "#FB6A4A";
	else if(severity==5)
		return "#EF3B2C";
	else if(severity==6)
		return "#CB181D";
	else if(severity==7)
		return "#A50F15";
	else if(severity==8)
		return "#67000D";
	else if(severity==9)
		return "#67000D";

}

var zoom = function(clicks, myState){
	var pt = myState.tracker.transformedPoint(myState.lastX,myState.lastY);
	//myState.tracker.translate(pt.x,pt.y);
	var factor = Math.pow(1.1,clicks);
	myState.tracker.scale(factor,factor);
	//myState.tracker.translate(-pt.x,-pt.y);
	var newMat = myState.tracker.getTransform();
	myState.svg.attr("transform", "matrix("+newMat.a+","+newMat.b+","+newMat.c+","+newMat.d+","+newMat.e+","+newMat.f+")");
}

function trackSVGTransforms(tracker, svg){
	var xform = svg.createSVGMatrix();
	var getTransform = tracker.getTransform;
	tracker.getTransform = function(){ return xform; };
	
	var scale = 1;
	var scale = tracker.scale;
	tracker.scale = function(sx,sy){
		xform = xform.scaleNonUniform(sx,sy);
		return xform;
	};
	var rotate = tracker.rotate;
	tracker.rotate = function(radians){
		xform = xform.rotate(radians*180/Math.PI);
		return xform;
	};
	var translate = tracker.translate;
	tracker.translate = function(dx,dy){
		xform = xform.translate(dx,dy);
		return xform;
	};
	var transform = tracker.transform;
	tracker.transform = function(a,b,c,d,e,f){
		var m2 = svg.createSVGMatrix();
		m2.a=a; m2.b=b; m2.c=c; m2.d=d; m2.e=e; m2.f=f;
		xform = xform.multiply(m2);
		return xform;
	};
	var setTransform = tracker.setTransform;
	tracker.setTransform = function(a,b,c,d,e,f){
		xform.a = a;
		xform.b = b;
		xform.c = c;
		xform.d = d;
		xform.e = e;
		xform.f = f;
		return xform;
	};
	
	var pt = svg.createSVGPoint();
	tracker.transformedPoint = function(x,y){
		pt.x=x; pt.y=y;
		return pt.matrixTransform(xform.inverse());
	}
}



