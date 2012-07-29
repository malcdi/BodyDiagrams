function CanvasState(canvas, subcanvas) {
	
	this.isZoomCanvas=true;
	if(subcanvas==null){
		this.isZoomCanvas=false;
	}
	
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
	this.regionTags = [];  
	this.freeHandTags=[];
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
	
	//Zooming scale factors --> moved to main scope
	//this.zoom_to_main_left_offset = 0;
	//this.zoom_to_main_top_offset = 0;
	//this.zoom_to_main_scale_factor_width = 1; //1:1 is our original scale
	//this.zoom_to_main_scale_factor_height = 1;
	
	// the current selected object.
	// In the future we could turn this into an array for multiple selection
	this.regionSelection = null;
	this.handSelection=null;
	this.dragoffx = 0; 
	this.dragoffy = 0;
	
	/* registering mouse events */
	var myState = this;
	
	//Handling zooming. Sorry if this is messy. Feel free to refactor :-)
	var isZoomCanvas = this.isZoomCanvas;
	var zoom_start_x, zoom_start_y, zoom_end_x, zoom_end_y; //captures the region we want to zoom into

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
		
		if(inZoom && !isZoomCanvas){
			console.log("Mousedown and in zoom");
			zoom_start_x = mx;
			zoom_start_y = my;
			return;
		}
		
		var regionTags = myState.regionTags;
		var l = regionTags.length;
		for (var i = l-1; i >= 0; i--) {
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
		
		if(isZoomCanvas){
			
			var otherState = subcanvas;
			
			if(otherState.resizeSide != -1){
				otherState.isResizeDrag = true;
				return;
			}

			var mxOther = mx * zoom_to_main_scale_factor_width + zoom_to_main_left_offset;
			var myOther = my * zoom_to_main_scale_factor_height + zoom_to_main_top_offset;

			var regionTags = otherState.regionTags;
			var l = regionTags.length;
			for (var i = l-1; i >= 0; i--) {
				if (regionTags[i].contains(mxOther, myOther)) {
					var mySel = regionTags[i];
					// Keep track of where in the object we clicked
					// so we can move it smoothly (see mousemove)
					otherState.dragoffx = mxOther - mySel.x;
					otherState.dragoffy = myOther - mySel.y;
					otherState.dragging = true;
					otherState.regionSelection = mySel;
					otherState.needRedraw = true;
					return;
				}
			}
			// havent returned means we have failed to select anything.
			// If there was an object selected, we deselect it
			if (otherState.regionSelection) {
				otherState.regionSelection = null;
				otherState.needRedraw = true; // Need to clear the old selection border
			}

			/* Free Hand Drawing */
			otherState.mouseDownForFreeHand = true;
			otherState.handSelection=new FreeHandTagCanvasElem('#BBAAAA');
			console.log("starting freehand drawing");
			otherState.handSelection.addPoint(mxOther,myOther);
			otherState.addFreeHandTagCanvasElem(otherState.handSelection);
		}
		
	}, true);
	
	//Mouse Move Event--On drag
	canvas.addEventListener('mousemove', function(e) {
		
		if(inZoom && !isZoomCanvas){
			return;
		}
		
		var mouse = myState.getMouse(e);
		var mx = mouse.x;
		var my = mouse.y;
		
		
		/*Free Hand Drawing*/
		if(myState.mouseDownForFreeHand){
			console.log("adding freehand point self: " + mx + ", " + my);
			myState.handSelection.addPoint(mx, my);
			myState.needRedraw=true;
			
			if(isZoomCanvas){ //if this is the zooming canvas, replicate the drawing on the main canvas
				var otherState = subcanvas;
				var mxOther = mx * zoom_to_main_scale_factor_width + zoom_to_main_left_offset;
				var myOther = my * zoom_to_main_scale_factor_height + zoom_to_main_top_offset;
				/*Free Hand Drawing*/
				if(otherState.mouseDownForFreeHand){
					console.log("adding freehand point: " + mxOther + ", " + myOther);
					otherState.handSelection.addPoint(mxOther, myOther);
					otherState.needRedraw=true;
				}
			}
			return;
		}
		
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
		if (myState.regionSelection !== null && !myState.isResizeDrag) {
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
		
		if(inZoom && !isZoomCanvas){
			console.log("Mousedown and in zoom");
			var mouse = myState.getMouse(e);
			zoom_end_x = mouse.x;
			zoom_end_y = mouse.y;
			zoomPanel(zoom_start_x, zoom_start_y, zoom_end_x, zoom_end_y);
			return;
		}
		
		if(myState.mouseDownForFreeHand){
			myState.mouseDownForFreeHand = false;
			myState.needRedraw=true;
			
			if(isZoomCanvas){ //if this is the zoom canvas, turn off mouse listening for the main canvas, too
				var otherState = subcanvas;
				if(otherState.mouseDownForFreeHand){
					console.log("mouseDownForFreehand Main: " + otherState.mouseDownForFreehand);
					otherState.mouseDownForFreeHand = false;
					otherState.needRedraw=true;
				}
			}
			return;
		}
		myState.dragging = false;
		myState.isResizeDrag = false;
		myState.resizeSide = -1;
		
	}, true);
		
	// double click for making new regionTags
	canvas.addEventListener('dblclick', function(e) {
		
		if(inZoom){
			return;
		}
		
		var mouse = myState.getMouse(e);
		myState.regionSelection=new RegionTagCanvasElem(mouse.x - 10, mouse.y - 10, 20, 20,
 'rgba(0,255,0,.6)');
		myState.addRegionTagCanvasElem(myState.regionSelection);
		myState.isResizeDrag=true;
		
		if(isZoomCanvas){
			console.log("mousedown in double click");
			var xTranslate = (mouse.x * zoom_to_main_scale_factor_width + zoom_to_main_left_offset) - (10 * zoom_to_main_scale_factor_width);
			var yTranslate = (mouse.y * zoom_to_main_scale_factor_height + zoom_to_main_top_offset) - (10 * zoom_to_main_scale_factor_width); 
			var otherState = subcanvas;
			otherState.regionSelection=new RegionTagCanvasElem(xTranslate, yTranslate, 20 * zoom_to_main_scale_factor_height, 20 * zoom_to_main_scale_factor_height,'rgba(255,0,0,.6)');
			otherState.addRegionTagCanvasElem(otherState.regionSelection);
			otherState.isResizeDrag=true;
			console.log(otherState);
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

CanvasState.prototype.clear = function(ctx){
	ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
}

CanvasState.prototype.addRegionTagCanvasElem = function(elem){
	this.regionTags.push(elem);
	this.needRedraw=true;
}

CanvasState.prototype.addFreeHandTagCanvasElem = function(elem){
	this.freeHandTags.push(elem);
}

CanvasState.prototype.draw = function() {
	// if our state is invalid, redraw and validate!
	if (this.needRedraw) {
		var ctx = this.ctx;
		var regionTags = this.regionTags;
		var freeHandTags = this.freeHandTags;
		this.clear(ctx);

		// draw all Tags
		var l = regionTags.length;
		for (var i = 0; i < l; i++) {
			var tagElem = regionTags[i];
			// We can skip the drawing of elements that have moved off the screen:
			if (tagElem.x > this.width || tagElem.y > this.height ||
					tagElem.x + tagElem.w < 0 || tagElem.y + tagElem.h < 0) continue;
			regionTags[i].draw(ctx, this.canvas.width, this.canvas.height, (this.regionSelection==regionTags[i]), this.selectionHandles);
		}
		var fl = freeHandTags.length;
		for (var i = 0; i < fl; i++) {
			freeHandTags[i].draw(ctx);
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
