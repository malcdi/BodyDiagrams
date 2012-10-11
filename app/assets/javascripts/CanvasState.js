function CanvasState(canvas) {

	// fixes mouse co-ordinate problems when there's a border or padding
	// see getMouse for more detail
	if (document.defaultView && document.defaultView.getComputedStyle) {
		stylePaddingLeft = parseInt(document.defaultView.getComputedStyle(canvas, null)['paddingLeft'], 10)      || 0;
		stylePaddingTop  = parseInt(document.defaultView.getComputedStyle(canvas, null)['paddingTop'], 10)       || 0;
		styleBorderLeft  = parseInt(document.defaultView.getComputedStyle(canvas, null)['borderLeftWidth'], 10)  || 0;
		styleBorderTop   = parseInt(document.defaultView.getComputedStyle(canvas, null)['borderTopWidth'], 10)   || 0;
	}

	
	//this.allTags=[];//all the tags on canvas
this.allTags = [];   //graphic tags
this.allTagData =[]; //annotated tags

	//for drawing
	this.dragging = false; // Keep track of when we are dragging
	this.needRedraw = false;
	this.ctx = canvas.getContext('2d');
	this.canvas = canvas;
	this.mouseDownForFreeHand=false;
	
	//for resizing
	// Holds the 8 tiny boxes that will be our selection handles
	// the selection handles will bse in this order:
	// 0  1  2
	// 3     4
	// 5  6  7
	this.selectionHandles = [];
	this.isResizeDrag = false;
	this.resizeSide = -1; 
	
	// the current selected object.
	this.regionSelection = null;
	this.handSelection=null;
	this.dragoffx = 0; 
	this.dragoffy = 0;
	
	
	this.mode = "zoom";//modes: zoom, draw
	this.lastX=canvas.width/2;
	this.lastY=canvas.height/2;
	this.svg= document.createElementNS("http://www.w3.org/2000/svg",'svg');
	
	// Zoom related variables
	this.heightRatio=this.canvas.height/this.canvas.width;
	this.zoomRegionSelection = new RegionTagCanvasElem(5, 5, 320, 320*this.heightRatio, '#CCEEFF', true);//region element within main view.
	this.needRedraw = true;
	this.cur_view_side=0;
	
	/* registering mouse events */
	var myState = this;
	trackTransforms(this.ctx, this.svg);
	
	//fixes a problem where double clicking causes text to get selected on the canvas
	$(myState.canvas).bind('selectstart', getEventHandler('selectstart',myState));
	
	// Up, down, and move are for dragging
	$(myState.canvas).bind('mousedown', getEventHandler('mousedown',myState));
	
	//Mouse Move Event--On drag
	$(myState.canvas).bind('mousemove', getEventHandler('mousemove',myState));
	
	//mouse event done
	$(myState.canvas).bind('mouseup', getEventHandler('mouseup',myState));
	$(myState.canvas).bind('mousewheel', getEventHandler('mousewheel',myState));
	
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
	
	/* Register Rendering */
	this.interval = 30; //every 30 miliseconds
	setInterval(	function() { 
			myState.draw(); 
		}, myState.interval);
		
		
}

//setting variables to keep track of current view's relative xy coordiantes and zoom scale
CanvasState.prototype.setViewState = function(x, y,scale){
	this.viewX=x;
	this.viewY=y;
	this.viewScale=scale;
}

//clearing canvas
CanvasState.prototype.clear = function(ctx){
	ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
}

/*addint & removing tag elements from the allTags*/
CanvasState.prototype.addRegionTagCanvasElem = function(elem){
	this.allTags.push(elem);
	this.needRedraw=true;
}

CanvasState.prototype.addFreeHandTagCanvasElem = function(elem){
	this.allTags.push(elem);
}
CanvasState.prototype.removeInvalidFreeHandTag = function(elem){
	if(!elem.isValidElem()){
		this.allTags.pop();
	}
}
CanvasState.prototype.undoLastDrawing = function(myState){
	myState.allTags.pop();
	myState.needRedraw=true;	
}

/*main draw function*/
CanvasState.prototype.draw = function() {
	// if our state is invalid, redraw and validate!
	if (this.needRedraw) {
		var ctx = this.ctx;
		this.clear(ctx);
		
		ctx.drawImage(document.getElementById("imgsrc"), 370,20, 260, 800);		
		// draw all Tags
		var l = this.allTags.length;
		var fillColor="#F89393";
		for (var i = 0; i < l; i++) {
			var tagElem = this.allTags[i];
			//draw called to each element
			if(tagElem instanceof RegionTagCanvasElem){
				tagElem.draw(ctx, (this.regionSelection==tagElem), this.selectionHandles, fillColor);
			}
			else {
				tagElem.draw(ctx, fillColor);
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
	mx = e.pageX - offsetX;
	my = e.pageY - offsetY;

	// We return a simple javascript object (a hash) with x and y defined
	return {x: mx, y: my};
}

CanvasState.prototype.packGraphicTagInfo = function(){
	var l = this.allTags.length;
	var freeHandTags=[];
	var regionTags=[];
	for (var i = 0; i < l; i++) {
		this.allTags[i].transform(this.viewX, this.viewY, this.viewScale);
	}
	return this.allTags;
}

//flush data of current canvas state.
//called when submit button clicked, or view rotated
CanvasState.prototype.flush = function(){
	this.allTags=[];
	this.needRedraw=true;
	this.draw();
}

CanvasState.prototype.setMode = function(modeName){
	this.mode=modeName;
	if(this.mode=="zoom")
		this.canvas.style.cursor="move";
	else if(this.mode=="draw")
		this.canvas.style.cursor="crosshair";
}

function getEventHandler(name, myState){
 	return function(e){
		if(myState.mode=="draw")	
			CanvasDrawEventHandler[name](e, myState);
		else if(myState.mode=="zoom")	
			CanvasZoomEventHandler[name](e, myState);
	};
}

var CanvasZoomEventHandler={
	'mousedown': function(e, myState) {
		myState.lastX = e.offsetX || (e.pageX - myState.canvas.offsetLeft);
		myState.lastY = e.offsetY || (e.pageY - myState.canvas.offsetTop);
		myState.dragStart = myState.ctx.transformedPoint(myState.lastX,myState.lastY);
	},
	'mousemove': function(e, myState) {
		myState.lastX = e.offsetX || (e.pageX - canvas.offsetLeft);
		myState.lastY = e.offsetY || (e.pageY - canvas.offsetTop);
		if (myState.dragStart){
			var pt = myState.ctx.transformedPoint(myState.lastX,myState.lastY);
			myState.ctx.translate(pt.x-myState.dragStart.x,pt.y-myState.dragStart.y);
			myState.needRedraw=true;
			myState.draw();
		}
	},
	'mouseup': function(e, myState) {
		myState.dragStart = null;
	},
	'mousewheel':function(e,myState) { 
		var delta = e.originalEvent.wheelDelta ? e.originalEvent.wheelDelta/40 : e.originalEvent.detail ? e.originalEvent.detail : 0;
		if (delta) zoom(delta,myState);
		return e.preventDefault() && false;
	},
	'selectstart': function(e,myState) { 
		e.preventDefault(); return false; 
	}
}

var CanvasDrawEventHandler={
	'mousedown': function(e, myState) {
			if(myState.resizeSide != -1){
				myState.isResizeDrag = true;
				return;
			}
			
			var mouse = myState.getMouse(e);
			var mx = mouse.x;
			var my = mouse.y;
		
			//can only edit ones not submitted yet
			var l = myState.allTags.length;
			for (var i = 0; i < l; i++) {
				if ((myState.allTags[i] instanceof RegionTagCanvasElem) && myState.allTags[i].contains(mx, my)) {
					var mySel = myState.allTags[i];	
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

			myState.handSelection.addPoint(mx, my,myState.svg, myState.ctx.getTransform().inverse());
			myState.addFreeHandTagCanvasElem(myState.handSelection);
		},
	'mousemove': function(e, myState) {
			var mouse = myState.getMouse(e);
			var mx = mouse.x;
			var my = mouse.y;
			/*Free Hand Drawing*/
			if(myState.mouseDownForFreeHand){
				myState.handSelection.addPoint(mx, my,myState.svg, myState.ctx.getTransform().inverse());
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
			
		},
	'mouseup': function(e, myState) {
			if(myState.mouseDownForFreeHand){
				myState.mouseDownForFreeHand = false;
				myState.needRedraw=true;
				myState.removeInvalidFreeHandTag(myState.handSelection);
				
				var mouse = myState.getMouse(e);
				//open up annotation button
				var annotateBox=$("#annotate-box");
				annotateBox.css({
					left:mouse.x,
					top:mouse.y,
					visibility:"visible"
					});
				
				return;
			}
			myState.dragging = false;
			myState.isResizeDrag = false;
			myState.resizeSide = -1;
		},
		'mousewheel':function(e,myState) {
			return false;
		},
	'selectstart': function(e,myState) { 
			e.preventDefault(); return false; }
};


var zoom = function(clicks, myState){
	var ctx=myState.ctx;
	
	var pt = ctx.transformedPoint(myState.lastX,myState.lastY);
	ctx.translate(pt.x,pt.y);
	var factor = Math.pow(1.1,clicks);
	ctx.scale(factor,factor);
	ctx.translate(-pt.x,-pt.y);
	myState.needRedraw=true;
	myState.draw();
}

function trackTransforms(ctx,svg){
	var xform = svg.createSVGMatrix();
	ctx.getTransform = function(){ return xform; };

	var savedTransforms = [];
	var save = ctx.save;
	ctx.save = function(){
		savedTransforms.push(xform.translate(0,0));
		return save.call(ctx);
	};
	var restore = ctx.restore;
	ctx.restore = function(){
		xform = savedTransforms.pop();
		return restore.call(ctx);
	};

	var scale = ctx.scale;
	ctx.scale = function(sx,sy){
		xform = xform.scaleNonUniform(sx,sy);
		return scale.call(ctx,sx,sy);
	};
	var rotate = ctx.rotate;
	ctx.rotate = function(radians){
		xform = xform.rotate(radians*180/Math.PI);
		return rotate.call(ctx,radians);
	};
	var translate = ctx.translate;
	ctx.translate = function(dx,dy){
		xform = xform.translate(dx,dy);
		return translate.call(ctx,dx,dy);
	};
	var transform = ctx.transform;
	ctx.transform = function(a,b,c,d,e,f){
		var m2 = svg.createSVGMatrix();
		m2.a=a; m2.b=b; m2.c=c; m2.d=d; m2.e=e; m2.f=f;
		xform = xform.multiply(m2);
		return transform.call(ctx,a,b,c,d,e,f);
	};
	var setTransform = ctx.setTransform;
	ctx.setTransform = function(a,b,c,d,e,f){
		xform.a = a;
		xform.b = b;
		xform.c = c;
		xform.d = d;
		xform.e = e;
		xform.f = f;
		return setTransform.call(ctx,a,b,c,d,e,f);
	};
	var pt  = svg.createSVGPoint();
	ctx.transformedPoint = function(x,y){
		pt.x=x; pt.y=y;
		return pt.matrixTransform(xform.inverse());
	}
}


