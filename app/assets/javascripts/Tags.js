/* Constant Value Options*/
var mySelBoxColor = 'darkred'; //  for selection boxes
var mySelBoxSize = 6;
var selectionColor = '#CC0000';
var selectionWidth = 2;  


/* REGION TAGS */
// Constructor for RegionTag objects to hold data relevant to drawing.
function RegionTagCanvasElem(x, y, w, h, fill) {
	// This is a very simple and unsafe constructor. 
	// All we're doing is checking if the values exist.
	// "x || 0" just means "if there is a value for x, use that. Otherwise use 0."
	this.x = x || 0;
	this.y = y || 0;
	this.w = w || 0;
	this.h = h || 0;
	this.fill = fill || '#AAAAAA';
}

RegionTagCanvasElem.prototype.toJSON = function() {
	return {"origin_x":this.x, "origin_y":this.y, "height":this.h, "width":this.w};
}

RegionTagCanvasElem.prototype.transform = function(x, y, scale) {
	this.x = this.x/scale+x;
	this.y = this.y/scale+y;
	this.w = this.w/scale;
	this.h = this.h/scale;
}

// Draws this shape to a given context
RegionTagCanvasElem.prototype.draw = function(ctx, thisElemOnSelect, selectionHandles) {
	ctx.fillStyle = '#AAAAAA';
	ctx.globalAlpha = 0.1;
	// We can skip the drawing of elements that have moved off the screen:
	//if (this.x > WIDTH || this.y > HEIGHT) return; 
	//if (this.x + this.w < 0 || this.y + this.h < 0) return;

	ctx.fillRect(this.x, this.y, this.w, this.h);

	// draw selection
	// this is a stroke along the box and also 8 new selection handles
	if (thisElemOnSelect) {
		ctx.globalAlpha = 1.0;
		ctx.strokeStyle = '#AAAAAA';
		ctx.lineWidth = selectionWidth;
		ctx.strokeRect(this.x,this.y,this.w,this.h);

		// draw the boxes

		var half = mySelBoxSize / 2;
		/*
		// 0  1  2
		// 3     4
		// 5  6  7
		// top left, middle, right
		selectionHandles[0].x = this.x-half;
		selectionHandles[0].y = this.y-half;

		selectionHandles[1].x = this.x+this.w/2-half;
		selectionHandles[1].y = this.y-half;

		selectionHandles[2].x = this.x+this.w-half;
		selectionHandles[2].y = this.y-half;

		//middle left
		selectionHandles[3].x = this.x-half;
		selectionHandles[3].y = this.y+this.h/2-half;

		//middle right
		selectionHandles[4].x = this.x+this.w-half;
		selectionHandles[4].y = this.y+this.h/2-half;

		//bottom left, middle, right
		selectionHandles[6].x = this.x+this.w/2-half;
		selectionHandles[6].y = this.y+this.h-half;

		selectionHandles[5].x = this.x-half;
		selectionHandles[5].y = this.y+this.h-half;

		selectionHandles[7].x = this.x+this.w-half;
		selectionHandles[7].y = this.y+this.h-half;


		ctx.globalAlpha = 1.0;
		ctx.fillStyle = mySelBoxColor;
		for (var i = 0; i < 8; i ++) {
			var cur = selectionHandles[i];
			ctx.fillRect(cur.x, cur.y, mySelBoxSize, mySelBoxSize);
		}*/
	}
}

RegionTagCanvasElem.prototype.setCoordinates = function(minX, minY, maxX, maxY) {
	this.x = minX;
	this.y = minY;
	this.w = maxX - minX;
	this.h = maxY - minY;
}

//DM: I added some margin for error here; it was difficult to select the selResizeBoxes on the drawing canvas after initially creating a region selection
RegionTagCanvasElem.prototype.contains = function(mx, my) {
	selBoxPadding = 2;
	if(mx < this.x - selBoxPadding || mx > this.x+this.w + selBoxPadding) return false;
	if(my < this.y - selBoxPadding || my > this.y+this.h + selBoxPadding) return false;
	return true;
}

/* FREE HAND TAGS */
// Constructor for RegionTag objects to hold data relevant to drawing.
function FreeHandTagCanvasElem(strokeStyle, view) {
	// This is a very simple and unsafe constructor. 
	// All we're doing is checking if the values exist.
	this.strokeStyle = strokeStyle || '#F89393';
	this.points=[];
	this.view = view; 
	this.minX = 10000;
	this.minY = 10000;
	this.maxX = 0;
	this.maxY = 0;
}

FreeHandTagCanvasElem.prototype.getView = function() {
	return this.view;
}
FreeHandTagCanvasElem.prototype.toJSON = function() {
	return {"points":this.points, "view":this.view};
}

FreeHandTagCanvasElem.prototype.contains = function(mx, my) {
	selBoxPadding = 2;
	if(mx < this.minX - selBoxPadding || mx > this.maxX + selBoxPadding) return false;
	if(my < this.minY - selBoxPadding || my > this.maxY + selBoxPadding) return false;
	return true;
}

FreeHandTagCanvasElem.prototype.addPoint = function(x_t, y_t) {
	if(x_t < this.minX)
		this.minX = x_t
	else if(x_t > this.maxX)
		this.maxX = x_t
		
	if(y_t < this.minY)
		this.minY = y_t
	else if(y_t > this.maxY)
		this.maxY = y_t
		
	var hash = {};
	hash.x = x_t;
	hash.y = y_t;
	this.points.push(hash);
}

FreeHandTagCanvasElem.prototype.isValidElem = function() {
	return (this.points.length>1);
}

FreeHandTagCanvasElem.prototype.moveAll = function(mx, my) {
	for (var i=0; i<this.points.length; i++){
		this.points[i].x= this.points[i].x+mx;
		this.points[i].y= this.points[i].y+my;
	}
	this.minX +=mx;
	this.maxX +=mx;
	this.minY +=my;
	this.maxY +=my;
}

// Draws this shape to a given context
FreeHandTagCanvasElem.prototype.draw = function(ctx) {
	ctx.strokeStyle = this.strokeStyle;
	ctx.beginPath();
	for (var i=0; i<this.points.length; i++){
		
		if (i==0) ctx.moveTo(this.points[i].x, this.points[i].y);
		else {
			ctx.lineTo(this.points[i].x, this.points[i].y);
			ctx.stroke();
		}
	}
	ctx.closePath();
}

FreeHandTagCanvasElem.prototype.setStyle = function(strokeStyle) {
	this.strokeStyle = strokeStyle;
}

FreeHandTagCanvasElem.prototype.saveTagAnnotation = function(severity, type, posture, depth, text) {
	this.severity = severity;
	this.type = type;
	this.posture = posture;
	this.depth = depth;
	this.text = text;
}



