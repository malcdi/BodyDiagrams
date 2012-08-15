//DM: if I'm correct, this comment is outdated. We never draw on the ZoomCanvasState, we just use it to zoom.
/* ZoomStateCanvas is an extension of CanvasState. It retains the functionalities of CanvasState, but in addition,
 * it is bound to a CanvasState object. Tags initialized on a ZoomStateCanvas are translated into the original
 * CanvasState coordinates and pushed to the CanvasState object. ZoomStateCanvas tags should be considered transient:
 * tags should be translated and saved permanently to the CanvasState
 */

function ZoomCanvasState(zoomCanvas, boundCanvasState, zoomCallback, getData, saveCallback) {

	// fixes mouse co-ordinate problems when there's a border or padding
	// see getMouse for more detail
	if (document.defaultView && document.defaultView.getComputedStyle) {
		stylePaddingLeft = parseInt(document.defaultView.getComputedStyle(zoomCanvas, null)['paddingLeft'], 10)      || 0;
		stylePaddingTop  = parseInt(document.defaultView.getComputedStyle(zoomCanvas, null)['paddingTop'], 10)       || 0;
		styleBorderLeft  = parseInt(document.defaultView.getComputedStyle(zoomCanvas, null)['borderLeftWidth'], 10)  || 0;
		styleBorderTop   = parseInt(document.defaultView.getComputedStyle(zoomCanvas, null)['borderTopWidth'], 10)   || 0;
	}

	//DM: variables we'll need to handle zooming and scaling
	this.leftMatch = 0;
	this.topMatch = 0;
	this.scaleFactor = 1;
	this.scaleFactorHeight = 1;

	this.dragging = false; // Keep track of when we are dragging
	this.needRedraw = false;
	this.ctx = zoomCanvas.getContext('2d');
	this.zoomCanvas = zoomCanvas;
	this.boundCanvasState = boundCanvasState;

	//for resizing
	// Holds the 8 tiny boxes that will be our selection handles
	// the selection handles will be in this order:
	// 0  1  2
	// 3     4
	// 5  6  7
	this.selectionHandles = [];
	this.isResizeDrag = false;
	this.resizeSide = -1; 
	
	this.allTags = [];   //graphic tags
	this.allTagData =[]; //annotated tags
	
	// Zoom related variables
	this.heightRatio=boundCanvasState.canvas.height/boundCanvasState.canvas.width;
	this.zoomRegionSelection = new RegionTagCanvasElem(5, 5, 320, 320*this.heightRatio, '#CCEEFF', true);//region element within main view.
	this.needRedraw = true;
	this.zoomCallback=zoomCallback;

	this.exportHandSelection=null;
	this.dragoffx = 0; 
	this.dragoffy = 0;
	this.cur_view_side=0;
	
	/* registering mouse events */
	var myState = this;
	this.getData=getData;
	this.saveCallback=saveCallback;
	
	//fixes a problem where double clicking causes text to get selected on the zoomCanvas
	zoomCanvas.addEventListener('selectstart', function(e) { e.preventDefault(); return false; }, false);
	
	// Up, down, and move are for dragging
	zoomCanvas.addEventListener('mousedown', function(e) {
		
		if(myState.resizeSide != -1){
			myState.isResizeDrag = true;
			return;
		}
		
		var mouse = myState.getMouse(e);
		var mx = mouse.x;
		var my = mouse.y;
		
		var mySel = myState.zoomRegionSelection;
		if (mySel.contains(mx, my)) {
			// Keep track of where in the object we clicked
			// so we can move it smoothly (see mousemove)
			myState.dragoffx = mx - mySel.x;
			myState.dragoffy = my - mySel.y;
			myState.dragging = true;
			myState.needRedraw = true;
			return;
		}
		
	}, true);
	
	//Mouse Move Event--On drag
	zoomCanvas.addEventListener('mousemove', function(e) {
		var mouse = myState.getMouse(e);
		var mx = mouse.x;
		var my = mouse.y;
		
		if (myState.dragging){
			myState.zoomRegionSelection.x = mx - myState.dragoffx;
			myState.zoomRegionSelection.y = my - myState.dragoffy;  
			myState.needRedraw = true; // Redraw flag 			
		} else if (myState.isResizeDrag){
			var oldx = myState.zoomRegionSelection.x;
			var oldy = myState.zoomRegionSelection.y;
			
			//RATIO KEPT.
			// 0  1  2
			// 3     4
			// 5  6  7
			switch (myState.resizeSide) {
				case 0:
					myState.zoomRegionSelection.x = mx;
					myState.zoomRegionSelection.y = my;
					myState.zoomRegionSelection.w += oldx - mx;
					myState.zoomRegionSelection.h=myState.zoomRegionSelection.w*myState.heightRatio;
					break;
				case 1:
					myState.zoomRegionSelection.y = my;
					myState.zoomRegionSelection.h += oldy - my;
					myState.zoomRegionSelection.w=myState.zoomRegionSelection.h/myState.heightRatio;
					break;
				case 2:
					myState.zoomRegionSelection.y = my;
					myState.zoomRegionSelection.w = mx - oldx;
					myState.zoomRegionSelection.h=myState.zoomRegionSelection.w*myState.heightRatio;
					break;
				case 3:
					myState.zoomRegionSelection.x = mx;
					myState.zoomRegionSelection.w += oldx - mx;
					myState.zoomRegionSelection.h=myState.zoomRegionSelection.w*myState.heightRatio;
					break;
				case 4:
					myState.zoomRegionSelection.w = mx - oldx;					
					myState.zoomRegionSelection.h=myState.zoomRegionSelection.w*myState.heightRatio;

					break;
				case 5:
					myState.zoomRegionSelection.x = mx;
					myState.zoomRegionSelection.w += oldx - mx;
					myState.zoomRegionSelection.h=myState.zoomRegionSelection.w*myState.heightRatio;

					break;
				case 6:
					myState.zoomRegionSelection.h = my - oldy;					
					myState.zoomRegionSelection.w=myState.zoomRegionSelection.h/myState.heightRatio;
					break;
				case 7:
					myState.zoomRegionSelection.w = mx - oldx;
					myState.zoomRegionSelection.h=myState.zoomRegionSelection.w*myState.heightRatio;
					break;
			}
			myState.needRedraw = true; // Redraw flag
		}
		
		//selection handles
		if (!myState.isResizeDrag) {
			for (var i = 0; i < 8; i++) {
				// 0  1  2
				// 3     4
				// 5  6  7
				var cur = myState.selectionHandles[i];
				
				if (mx >= cur.x && mx <= cur.x + mySelBoxSize &&
						my >= cur.y && my <= cur.y + mySelBoxSize) {
					// we found one!
					myState.resizeSide = i;
					myState.needRedraw = true;
					return;
				}
			}
			// not over a selection box, return to normal
			myState.isResizeDrag = false;
			myState.resizeSide = -1;
			this.style.cursor='auto';
		}
	}, true);
	
	zoomCanvas.addEventListener('mouseup', function(e) {
		myState.dragging = false;
		myState.isResizeDrag = false;
		myState.resizeSide = -1;
		var mouse = myState.getMouse(e);
		var mx = mouse.x;
		var my = mouse.y;
		//zoom button clicked
		if (myState.zoomRegionSelection.onZoomButton(mx, my)){
			myState.zoomCallback(myState.zoomRegionSelection.x,myState.zoomRegionSelection.y, myState.zoomRegionSelection.w, myState.zoomRegionSelection.h);
		}
	}, true);
	
	/* For Resize */
	// set up the selection handle boxes
	for (var i = 0; i < 8; i ++) {
		var rect = new RegionTagCanvasElem;
		this.selectionHandles.push(rect);
	}
	
	/* Register Rendering */
	this.interval = 30; //every 30 miliseconds
	setInterval(	function() { 
			myState.draw(); 
		}, myState.interval);
}

//DM: functions for translating to correct zooming resolution
ZoomCanvasState.prototype.setZoomConstants = function(_left, _top, _scale){
	//first rescale the image
	d = document.getElementById("zoom_body_view"); //DM: todo: pass this as a parameter to the ZoomCanvasState
	d.width=(337*_scale)+"";
	d.style.left=-(_left*_scale)+"px";
	d.style.top=-(_top*(d.height/750))+"px";
	
	//DM: variables we'll need to handle zooming and scaling
	this.leftMatch = _left;
	this.topMatch = _top;
	this.scaleFactor = _scale;
	this.scaleFactorHeight = d.height/750;
}

ZoomCanvasState.prototype.translateX = function(rawX){
	var transX = this.leftMatch * this.scaleFactor + rawX;//how much we need to shift left
	transX /= this.scaleFactor;
	console.log("translating X: " + rawX + " to " + transX);
	return(transX);
}

ZoomCanvasState.prototype.translateY = function(rawY){
	var transY = (this.topMatch * this.scaleFactor + rawY)/this.scaleFactor;
	console.log("translating Y: " + rawY + " to " + transY);
	return(transY);
}

ZoomCanvasState.prototype.scaleSize = function(rawVal){
	console.log("scaling " + rawVal + " to " + (rawVal / this.scaleFactor));
	return(rawVal/this.scaleFactor);
	//return(rawVal);
}
//DM: end functions for translating to correct zooming resolution

ZoomCanvasState.prototype.clear = function(ctx){
	ctx.clearRect(0, 0, this.zoomCanvas.width, this.zoomCanvas.height);
}

ZoomCanvasState.prototype.setCurViewSide = function(view_side) {
	this.cur_view_side=view_side;
	this.needRedraw=true;
	this.draw();
}


ZoomCanvasState.prototype.draw = function() {
	// if our state is invalid, redraw and validate!
	if (this.needRedraw) {
		var ctx = this.ctx;
		this.clear(ctx);

		// draw all SAVED Tags
		var l = this.allTags.length;
		for (var j = 0; j< l; j++) {
			var tags = this.allTags[j];
			var len = tags.length;
			var fillColor="#FFDD22";
			//only display tags with the same view side
			if(this.allTagData[j].view_side==this.cur_view_side){
				for (var i = 0; i < len; i++) {
					var tagElem = tags[i];
					if(tagElem instanceof RegionTagCanvasElem){
						tagElem.draw(ctx, (this.regionSelection==tagElem), this.selectionHandles, fillColor);
					}
					else {
						tagElem.draw(ctx, fillColor);
					}
				}
			}
		}
		
		//zooming box		
		var tagElem = this.zoomRegionSelection;
		// We can skip the drawing of elements that have moved off the screen:
		if (!(tagElem.x > this.width || tagElem.y > this.height ||
				tagElem.x + tagElem.w < 0 || tagElem.y + tagElem.h < 0)){
			tagElem.draw(ctx, true, this.selectionHandles, '#CCEEFF');
		}
		this.needRedraw = false;
	}
}

//called after "done" button clicked for each tag
ZoomCanvasState.prototype.saveTagInfo = function(cur_view_side){
	var myState=this;
	var tagData = myState.getData(); 
	myState.allTagData.push(tagData); //saves annnotated tag info
	this.allTags.push(this.boundCanvasState.packGraphicTagInfo()); //saves graphic tag info
	this.needRedraw=true;
	this.draw();
	myState.saveCallback(); //callback after saving done.
}

//save all the annotated tags
ZoomCanvasState.prototype.submitAll = function(){
	var self=this;
	$.ajax({
		type: "GET",
		url: "postTag",
		data: {"tagData": JSON.stringify(self.allTagData)}
	}).done(function( tagIdArr ) {
		self.submitGraphicTags(JSON.parse(tagIdArr));//array of tag ids returned.
	});
}

//save graphic tag information for each tag associated.
ZoomCanvasState.prototype.submitGraphicTags = function(tagIdArr){
	var self=this;
	var l = this.allTags.length;
	for (var j = 0; j < l; j++) {
		var tags = this.allTags[j];
		var len = tags.length;
		var freeHandTags=[];
		var regionTags=[];
		/*separate tags in region/freehand */
		for (var i = 0; i < len; i++) {
			var tagElem = tags[i];
			if(tagElem instanceof RegionTagCanvasElem){
				regionTags.push(tagElem);
			}
			else {
				freeHandTags.push(tagElem);
			}
		}
		
		$.ajax({
			type: "POST",
			url: "postGraphicTag",
			data: {"tagId":tagIdArr[j], "freeHand":JSON.stringify(freeHandTags), "region":JSON.stringify(regionTags)}
		}).done(function( msg ) {
			console.log( "Graphic Data Saved: " + msg);
			//on last tag data submission
			if(j==l-1) self.submitComplete();
		});
	}
}

//called after submission completed
ZoomCanvasState.prototype.submitComplete = function(){
	alert("complete");
}

// Creates an object with x and y defined,
// set to the mouse position relative to the state's zoomCanvas
// If you wanna be super-correct this can be tricky,
// we have to worry about padding and borders
ZoomCanvasState.prototype.getMouse = function(e) {
	var element = this.zoomCanvas, offsetX = 0, offsetY = 0, mx, my;

	// Compute the total offset
	if (element.offsetParent !== undefined) {
		do {
			offsetX += element.offsetLeft;
			offsetY += element.offsetTop;
		} while ((element = element.offsetParent));
	}

	// Add padding and border style widths to offset
	// Also add the <html> offsets in case there's a position:fixed bar
	//offsetX += this.stylePaddingLeft + this.styleBorderLeft + this.htmlLeft;
	//offsetY += this.stylePaddingTop + this.styleBorderTop + this.htmlTop;

	mx = e.pageX - offsetX;
	my = e.pageY - offsetY;

	// We return a simple javascript object (a hash) with x and y defined
	return {x: mx, y: my};
}