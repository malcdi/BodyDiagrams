/* ZoomStateCanvas is an extension of CanvasState. It retains the functionalities of CanvasState, but in addition,
 * it is bound to a CanvasState object. Tags initialized on a ZoomStateCanvas are translated into the original
 * CanvasState coordinates and pushed to the CanvasState object. ZoomStateCanvas tags should be considered transient:
 * tags should be translated and saved permanently to the CanvasState
 */

function ZoomCanvasState(zoomCanvas, boundCanvasState, zoomCallback) {

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
	
	//saved tags
	this.regionTags = {"tmp":[]};  
	this.freeHandTags={"tmp":[]};
	
	// the current selected object.
	// In the future we could turn this into an array for multiple selection
	this.heightRatio=boundCanvasState.canvas.height/boundCanvasState.canvas.width;
	this.zoomRegionSelection = new RegionTagCanvasElem(100, 100, 100, 100*this.heightRatio, '#CCEEFF', true);
	this.needRedraw = true;
	this.zoomCallback=zoomCallback;

	this.exportHandSelection=null;
	this.dragoffx = 0; 
	this.dragoffy = 0;
	
	/* registering mouse events */
	var myState = this;
	
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

		/* Free Hand Drawing */
/*
		myState.exportHandSelection = new FreeHandTagCanvasElem('#AABBAA');
		myState.exportHandSelection.addPoint(myState.translateX(mx), myState.translateY(my));
		boundCanvasState.addFreeHandTagCanvasElem(myState.exportHandSelection);
		// DM: push to bound canvas
		// DM: TODO: handle scaling
		// boundCanvasState.addFreeHandTagCanvasElem(myState.handSelection);*/
		
	}, true);
	
	//Mouse Move Event--On drag
	zoomCanvas.addEventListener('mousemove', function(e) {
		var mouse = myState.getMouse(e);
		var mx = mouse.x;
		var my = mouse.y;
		
		/* Non Free Hand */
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
		
		// if there's a selection see if we grabbed one of the selection handles
		if (!myState.isResizeDrag) {
			for (var i = 0; i < 8; i++) {
				// 0  1  2
				// 3     4
				// 5  6  7
				var cur = myState.selectionHandles[i];
				
				// we dont need to use the ghost context because
				// selection handles will always be rectangles
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
		if (myState.zoomRegionSelection.onZoomButton(mx, my)){
			myState.zoomCallback(myState.zoomRegionSelection.x,myState.zoomRegionSelection.y, myState.zoomRegionSelection.w, myState.zoomRegionSelection.h);
		}
	}, true);
	
	/*double click for making new regionTags
	zoomCanvas.addEventListener('dblclick', function(e) {
		var mouse = myState.getMouse(e);
		myState.regionSelection=new RegionTagCanvasElem(mouse.x - 10, mouse.y - 10, 20, 20,
 'rgba(0,255,0,.6)');
		myState.addRegionTagCanvasElem(myState.regionSelection);
		//DM: add to bound canvas, too. TODO: translate
		myState.regionSelectionExport=new RegionTagCanvasElem(myState.translateX(mouse.x - 10), myState.translateY(mouse.y - 10), myState.scaleSize(20), myState.scaleSize(20),
 'rgba(0,0,255,.6)');
		boundCanvasState.addRegionTagCanvasElem(myState.regionSelectionExport);
		myState.isResizeDrag=true;
	}, true);*/
	
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

ZoomCanvasState.prototype.addRegionTagCanvasElem = function(elem){
	this.regionTags.push(elem);
	this.needRedraw=true;
}

ZoomCanvasState.prototype.addFreeHandTagCanvasElem = function(elem){
	this.freeHandTags.push(elem);
}

ZoomCanvasState.prototype.draw = function() {
	// if our state is invalid, redraw and validate!
	if (this.needRedraw) {
		var ctx = this.ctx;
		this.clear(ctx);

		// ** Add stuff you want drawn in the background all the time here **

		// draw all SAVED Tags
		for (var tagId in this.regionTags) {
			var regionTags = this.regionTags[tagId];
			var l = regionTags.length;
			var fillColor="#FFDD22";
			for (var i = 0; i < l; i++) {
				var tagElem = regionTags[i];
				// We can skip the drawing of elements that have moved off the screen:
				if (tagElem.x > this.width || tagElem.y > this.height ||
						tagElem.x + tagElem.w < 0 || tagElem.y + tagElem.h < 0) continue;
				regionTags[i].draw(ctx, this.zoomCanvas.width, this.zoomCanvas.height, (this.regionSelection==regionTags[i]), this.selectionHandles, fillColor);
			}
		}
		
		for (var tagId in this.freeHandTags) {
			var freeHandTags = this.freeHandTags[tagId];
			var fillColor="#FFDD22";
			var fl = freeHandTags.length;
			for (var i = 0; i < fl; i++) {
				freeHandTags[i].draw(ctx, fillColor);
			}
		}
		
		//zoom box		
		var tagElem = this.zoomRegionSelection;
		// We can skip the drawing of elements that have moved off the screen:
		if (!(tagElem.x > this.width || tagElem.y > this.height ||
				tagElem.x + tagElem.w < 0 || tagElem.y + tagElem.h < 0)){
			tagElem.draw(ctx, this.zoomCanvas.width, this.zoomCanvas.height, true, this.selectionHandles, '#CCEEFF');
		}
		this.needRedraw = false;
	}
}
ZoomCanvasState.prototype.appendRegionTags=function(tagId, regionTags){
	this.regionTags[tagId]=regionTags;
	this.needsRedraw=true;
}
ZoomCanvasState.prototype.appendFreeHandTags=function(tagId, freeHandTags){
	this.freeHandTags[tagId]=freeHandTags;
	this.needsRedraw=true;
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