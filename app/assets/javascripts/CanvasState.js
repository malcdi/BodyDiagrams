function CanvasState(canvas, tagButton, getData, saveCallback) {

	// fixes mouse co-ordinate problems when there's a border or padding
	// see getMouse for more detail
	if (document.defaultView && document.defaultView.getComputedStyle) {
		stylePaddingLeft = parseInt(document.defaultView.getComputedStyle(canvas, null)['paddingLeft'], 10)      || 0;
		stylePaddingTop  = parseInt(document.defaultView.getComputedStyle(canvas, null)['paddingTop'], 10)       || 0;
		styleBorderLeft  = parseInt(document.defaultView.getComputedStyle(canvas, null)['borderLeftWidth'], 10)  || 0;
		styleBorderTop   = parseInt(document.defaultView.getComputedStyle(canvas, null)['borderTopWidth'], 10)   || 0;
	}

	// Keeping track of states.
	// the collection of things to be drawn
	this.regionTags = {"tmp":[]};  
	this.freeHandTags={"tmp":[]};
	this.currentId=-1;
	this.dragging = false; // Keep track of when we are dragging
	this.needRedraw = false;
	this.ctx = canvas.getContext('2d');
	this.canvas = canvas;
	
	this.mouseDownForFreeHand=false;
	
	//for resizing
	// Holds the 8 tiny boxes that will be our selection handles
	// the selection handles will be in this order:
	// 0  1  2
	// 3     4
	// 5  6  7
	this.selectionHandles = [];
	this.isResizeDrag = false;
	this.resizeSide = -1; 
	
	// the current selected object.
	// In the future we could turn this into an array for multiple selection
	this.regionSelection = null;
	this.handSelection=null;
	this.dragoffx = 0; 
	this.dragoffy = 0;
	
	/* registering mouse events */
	var myState = this;
	
	/*for submitting information to the server*/
	document.getElementById(tagButton).onclick=function(){
		myState.submitTagInfo(myState);
	};
	this.getData=getData;
	this.saveCallback=saveCallback;
	
	
	//fixes a problem where double clicking causes text to get selected on the canvas
	canvas.addEventListener('selectstart', function(e) { e.preventDefault(); return false; }, false);
	
	// Up, down, and move are for dragging
	canvas.addEventListener('mousedown', function(e) {
		
		if(myState.resizeSide != -1){
			myState.isResizeDrag = true;
			return;
		}
		
		var mouse = myState.getMouse(e);
		var mx = mouse.x;
		var my = mouse.y;
		//can only edit ones not submitted yet
		var regionTags = myState.regionTags.tmp;
		var l = regionTags.length;
		for (var i = 0; i < l; i++) {
			if (regionTags[i].contains(mx, my)) {
				var mySel = regionTags[i];
				// Keep track of where in the object we clicked
				// so we can move it smoothly (see mousemove)
				myState.dragoffx = mx - mySel.x;
				myState.dragoffy = my - mySel.y;
				myState.dragging = true;
				myState.regionSelection = mySel;
				myState.needRedraw = true;
				return;
			}
		}
		
		// havent returned means we have failed to select anything.
		// If there was an object selected, we deselect it
		if (myState.regionSelection) {
			myState.regionSelection = null;
			myState.needRedraw = true; // Need to clear the old selection border
		}
		
		/* Free Hand Drawing */
		myState.mouseDownForFreeHand = true;
		myState.handSelection=new FreeHandTagCanvasElem('#AAAAAA');
		myState.handSelection.addPoint(mx,my);
		myState.addFreeHandTagCanvasElem(myState.handSelection);
	}, true);
	
	//Mouse Move Event--On drag
	canvas.addEventListener('mousemove', function(e) {
		var mouse = myState.getMouse(e);
		var mx = mouse.x;
		var my = mouse.y;
		/*Free Hand Drawing*/
		if(myState.mouseDownForFreeHand){
			myState.handSelection.addPoint(mx, my);
			myState.needRedraw=true;
			return;
		}
		
		if (myState.regionSelection ==null) return;
		
		/* Non Free Hand */
		if (myState.dragging){
			myState.regionSelection.x = mx - myState.dragoffx;
			myState.regionSelection.y = my - myState.dragoffy;  
			myState.needRedraw = true; // Redraw flag 			
		} else if (myState.isResizeDrag){
			var oldx = myState.regionSelection.x;
			var oldy = myState.regionSelection.y;
			
			// 0  1  2
			// 3     4
			// 5  6  7
			switch (myState.resizeSide) {
				case 0:
					myState.regionSelection.x = mx;
					myState.regionSelection.y = my;
					myState.regionSelection.w += oldx - mx;
					myState.regionSelection.h += oldy - my;
					break;
				case 1:
					myState.regionSelection.y = my;
					myState.regionSelection.h += oldy - my;
					break;
				case 2:
					myState.regionSelection.y = my;
					myState.regionSelection.w = mx - oldx;
					myState.regionSelection.h += oldy - my;
					break;
				case 3:
					myState.regionSelection.x = mx;
					myState.regionSelection.w += oldx - mx;
					break;
				case 4:
					myState.regionSelection.w = mx - oldx;
					break;
				case 5:
					myState.regionSelection.x = mx;
					myState.regionSelection.w += oldx - mx;
					myState.regionSelection.h = my - oldy;
					break;
				case 6:
					myState.regionSelection.h = my - oldy;
					break;
				case 7:
					myState.regionSelection.w = mx - oldx;
					myState.regionSelection.h = my - oldy;
					break;
			}
			myState.needRedraw = true; // Redraw flag
		}
		
		// if there's a selection see if we grabbed one of the selection handles
		if (myState.regionSelection != null && !myState.isResizeDrag) {
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
	
	canvas.addEventListener('mouseup', function(e) {
		if(myState.mouseDownForFreeHand){
			myState.mouseDownForFreeHand = false;
			myState.needRedraw=true;
			myState.removeInvalidFreeHandTag(myState.handSelection);
			return;
		}
		myState.dragging = false;
		myState.isResizeDrag = false;
		myState.resizeSide = -1;
	}, true);
	
	// double click for making new regionTags
	canvas.addEventListener('dblclick', function(e) {
		var mouse = myState.getMouse(e);
		myState.regionSelection=new RegionTagCanvasElem(mouse.x - 10, mouse.y - 10, 20, 20,
 'rgba(0,255,0,.6)');
		myState.addRegionTagCanvasElem(myState.regionSelection);
		myState.isResizeDrag=true;
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

CanvasState.prototype.clear = function(ctx){
	ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
}

CanvasState.prototype.addRegionTagCanvasElem = function(elem){
	this.regionTags.tmp.push(elem);
	this.needRedraw=true;
}

CanvasState.prototype.addFreeHandTagCanvasElem = function(elem){
	this.freeHandTags.tmp.push(elem);
}
CanvasState.prototype.removeInvalidFreeHandTag = function(elem){
	if(!elem.isValidElem()){
		this.freeHandTags.tmp.pop();
	}
}

CanvasState.prototype.draw = function() {
	// if our state is invalid, redraw and validate!
	if (this.needRedraw) {
		var ctx = this.ctx;
		this.clear(ctx);
		// ** Add stuff you want drawn in the background all the time here **

		// draw all Tags
		for (var tagId in this.regionTags) {
			var regionTags = this.regionTags[tagId];
			var l = regionTags.length;
			var fillColor="#DDDDDD";
			if(tagId=="tmp") fillColor="#F89393";
			for (var i = 0; i < l; i++) {
				var tagElem = regionTags[i];
				// We can skip the drawing of elements that have moved off the screen:
				if (tagElem.x > this.width || tagElem.y > this.height ||
						tagElem.x + tagElem.w < 0 || tagElem.y + tagElem.h < 0) continue;
				regionTags[i].draw(ctx, this.canvas.width, this.canvas.height, (this.regionSelection==regionTags[i]), this.selectionHandles, fillColor);
			}
		}
		
		for (var tagId in this.freeHandTags) {
			var freeHandTags = this.freeHandTags[tagId];
			var fillColor="#DDDDDD";
			if(tagId=="tmp") fillColor="#F89393";
			var fl = freeHandTags.length;
			for (var i = 0; i < fl; i++) {
				freeHandTags[i].draw(ctx, fillColor);
			}
		}
		this.needRedraw = false;
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

	// Add padding and border style widths to offset
	// Also add the <html> offsets in case there's a position:fixed bar
	//offsetX += this.stylePaddingLeft + this.styleBorderLeft + this.htmlLeft;
	//offsetY += this.stylePaddingTop + this.styleBorderTop + this.htmlTop;

	mx = e.pageX - offsetX;
	my = e.pageY - offsetY;

	// We return a simple javascript object (a hash) with x and y defined
	return {x: mx, y: my};
}

CanvasState.prototype.submitTagInfo = function(myState){
	var tagData = myState.getData();
	$.ajax({
		type: "POST",
		url: "postTag",
		data: tagData
	}).done(function( msg ) {
		console.log( "Data Saved: " + msg);
		myState.submitGraphicTagInfo(msg);
	});
}

CanvasState.prototype.submitGraphicTagInfo = function(tagId){
	this.freeHandTags.tagId=this.freeHandTags.tmp;
	this.regionTags.tagId=this.regionTags.tmp;
	var myState=this;
	var graphicTags={};
	graphicTags.tagId=tagId;
	graphicTags.freeHand=JSON.stringify(this.freeHandTags.tagId);
	graphicTags.region=JSON.stringify(this.regionTags.tagId);
	$.ajax({
		type: "POST",
		url: "postGraphicTag",
		data: graphicTags
	}).done(function( msg ) {
		console.log( "Graphic Data Saved: " + msg );
		myState.saveCallback();
	});
	
	//flush
	this.freeHandTags.tmp=[];
	this.regionTags.tmp=[];
}
