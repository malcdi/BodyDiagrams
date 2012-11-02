function CanvasState(canvas, options) {

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
	
	// the current selected object.
	this.regionSelection = null;
	this.handSelection=null;
	this.dragoffx = 0; 
	this.dragoffy = 0;
	
	
	//SETS up using options
	this.gender = options.gender ? options.gender : "male";
	this.view = options.view ? options.view : 0;
	this.mode = options.mode ? options.mode : "zoom";
	this.imageLoader = options.imageLoader;
	this.saveCallback = options.saveCallback;
	this.selectCallback = options.selectCallback;
	
	this.lastX=canvas.width/2;
	this.lastY=canvas.height/2;
	this.svg= document.createElementNS("http://www.w3.org/2000/svg",'svg');
	
	// Zoom related variables
	this.heightRatio=this.canvas.height/this.canvas.width;
	this.highlightRegion = new RegionTagCanvasElem(5, 5,0, 0, '#CCEEFF');//region element within main view.
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
	this.interval = 10; //every 30 miliseconds
	setInterval(	function() { 
			myState.draw(); 
		}, myState.interval);
	myState.draw(); 
	
}

//setting view side (front? left? etc)
CanvasState.prototype.setView= function(view){
	this.view = view;
	this.needRedraw = true;
	this.draw();
}
CanvasState.prototype.getView= function(){
	return this.view
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
		//ctx.fillStyle='#f00';
		//ctx.fillRect(0,0, this.canvas.width, this.canvas.height);
		
		var bodyImage = this.imageLoader.getBodyImage(this.gender, this.view);
		var imgHeight = 800;
		var imgWidth = bodyImage.width*imgHeight/bodyImage.height; //keeps aspect ratio
		ctx.drawImage(bodyImage, (this.canvas.width-imgWidth)/2, 
										(this.canvas.height-imgHeight)/2, imgWidth, imgHeight);		
		// draw all Tags
		var l = this.allTags.length;
		ctx.lineWidth = 3;
		for (var i = 0; i < l; i++) {
			var tagElem = this.allTags[i];
			//draw called to each element
			/*if(tagElem instanceof RegionTagCanvasElem){
				tagElem.draw(ctx, (this.regionSelection==tagElem), this.selectionHandles);
			}
			else {
				tagElem.draw(ctx);
			}*/
			//only draw if the same side.
			if(tagElem.getView() == this.view)
				tagElem.draw(ctx);
		}
		if(this.regionSelection !=null ){
			var mySel = this.regionSelection;
			this.highlightRegion.setCoordinates(mySel.minX, mySel.minY, mySel.maxX, mySel.maxY);
			this.highlightRegion.draw(ctx,true,this.selectionHandles);
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
		this.canvas.style.cursor="url('/assets/dragHand.png'), auto";
	else if(this.mode=="draw")
		this.canvas.style.cursor="url('/assets/drawHand.png'), auto";
}

CanvasState.prototype.updateGraphics = function(index, severity, type){
	var theTag = this.allTags[index];
	var newPattern = this.ctx.createPattern(this.imageLoader.getPainPatternImage(type, severity), "repeat");
	theTag.setStyle(newPattern);
	this.needRedraw=true;
	this.draw();
}

CanvasState.prototype.saveTagAnnotation = function(index, severity, type, posture, depth, text){
	var theTag = this.allTags[index];
	theTag.saveTagAnnotation(severity, type, posture, depth, text);
}

CanvasState.prototype.setZoomPan = function(deltaX, deltaY, deltaZoom){
	this.ctx.translate(deltaX, deltaY);
	this.lastX = this.canvas.width/2;
	this.lastY = this.canvas.height/2;
	zoom(deltaZoom, this);
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
		e.preventDefault();
		var mouse = myState.getMouse(e);
		var globalPoint = myState.ctx.transformedPoint(mouse.x, mouse.y);
		
		//see if selection occured
		var l = myState.allTags.length;
		for (var i = 0; i < l; i++) {
			if (myState.allTags[i].view ==myState.view && myState.allTags[i].contains(globalPoint.x, globalPoint.y)) 			
			{
				myState.selectCallback(myState.allTags.indexOf(myState.regionSelection),false);
				myState.regionSelection = myState.allTags[i];	
				myState.selectCallback(i,true);
				myState.needRedraw = true;
				myState.dragging = true;
				myState.dragoffx = globalPoint.x;
				myState.dragoffy = globalPoint.y;
				return;
			}
		}
		myState.selectCallback(myState.allTags.indexOf(myState.regionSelection),false);
		myState.regionSelection = null;
		myState.needRedraw = true;
		
		myState.lastX = e.offsetX || (e.pageX - myState.canvas.offsetLeft);
		myState.lastY = e.offsetY || (e.pageY - myState.canvas.offsetTop);
		myState.dragStart = myState.ctx.transformedPoint(myState.lastX,myState.lastY);
	},
	'mousemove': function(e, myState) {
		e.preventDefault();
		myState.lastX = e.offsetX || (e.pageX - canvas.offsetLeft);
		myState.lastY = e.offsetY || (e.pageY - canvas.offsetTop);
		if (myState.dragStart){
			var pt = myState.ctx.transformedPoint(myState.lastX,myState.lastY);
			myState.ctx.translate(pt.x-myState.dragStart.x,pt.y-myState.dragStart.y);
			myState.needRedraw=true;
			myState.draw();
		}
		
		/* Non Free Hand */
		if (myState.dragging){
			var mouse = myState.getMouse(e);
			var globalPoint = myState.ctx.transformedPoint(mouse.x, mouse.y);
			
			myState.regionSelection.moveAll(globalPoint.x - myState.dragoffx, globalPoint.y - myState.dragoffy);
			myState.dragoffx = globalPoint.x;
			myState.dragoffy = globalPoint.y;
			
			myState.needRedraw = true; // Redraw flag 			
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
	},
	'selectstart': function(e,myState) { 
		e.preventDefault(); return false; 
	}
}

var CanvasDrawEventHandler={
	'mousedown': function(e, myState) {
			myState.selectCallback(myState.allTags.indexOf(myState.regionSelection),false);
			myState.regionSelection = null;
			myState.needRedraw = true;
			
			e.preventDefault();
			
			var mouse = myState.getMouse(e);
			
			/* Free Hand Drawing */
			//save old one
			if(myState.handSelection)
				myState.saveCallback(myState.handSelection, myState.allTags.length-1);

			myState.mouseDownForFreeHand = true;
			myState.handSelection=new FreeHandTagCanvasElem('#F89393', myState.view);
			
			var globalPoint = myState.ctx.transformedPoint(mouse.x, mouse.y);
			myState.handSelection.addPoint(globalPoint.x, globalPoint.y);
			myState.addFreeHandTagCanvasElem(myState.handSelection);
		},
		
	'mousemove': function(e, myState) {
			var mouse = myState.getMouse(e);
			e.preventDefault();
			/*Free Hand Drawing*/
			if(myState.mouseDownForFreeHand){
				var globalPoint = myState.ctx.transformedPoint(mouse.x, mouse.y);
				myState.handSelection.addPoint(globalPoint.x, globalPoint.y);
				myState.needRedraw=true;
				return;
			}
		},
	'mouseup': function(e, myState) {
			
			if(myState.mouseDownForFreeHand){
				myState.mouseDownForFreeHand = false;
				
				if(!myState.handSelection.isValidElem()){
					myState.allTags.pop();
				}
				else {
					myState.regionSelection = myState.handSelection;
					myState.selectCallback(myState.allTags.length-1, true);
				}
				myState.needRedraw=true;
				
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


