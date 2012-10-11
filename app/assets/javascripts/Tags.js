/* Constant Value Options*/
var mySelBoxColor = 'darkred'; //  for selection boxes
var mySelBoxSize = 6;
var selectionColor = '#CC0000';
var selectionWidth = 2;  


/* REGION TAGS */
// Constructor for RegionTag objects to hold data relevant to drawing.
function RegionTagCanvasElem(x, y, w, h, fill, zoomBox) {
	// This is a very simple and unsafe constructor. 
	// All we're doing is checking if the values exist.
	// "x || 0" just means "if there is a value for x, use that. Otherwise use 0."
	this.x = x || 0;
	this.y = y || 0;
	this.w = w || 1;
	this.h = h || 1;
	this.fill = fill || '#AAAAAA';
	if(zoomBox!=undefined && zoomBox!=null){
		this.zoomBox=true;
	}
	else {
		this.zoomBox=false;
	}
}
RegionTagCanvasElem.prototype.toJSON = function() {
	return {"origin_x":this.x, "origin_y":this.y, "height":this.h, "width":this.w};
}

RegionTagCanvasElem.prototype.onZoomButton = function(mx, my) {
	var zbs = this.zoomBoxSize();
	if(mx < zbs.x || mx > zbs.x+zbs.w) return false;
	if(my < zbs.y || my > zbs.y+zbs.h) return false;
	return true;
}

RegionTagCanvasElem.prototype.transform = function(x, y, scale) {
	this.x = this.x/scale+x;
	this.y = this.y/scale+y;
	this.w = this.w/scale;
	this.h = this.h/scale;
}

// Draws this shape to a given context
RegionTagCanvasElem.prototype.draw = function(ctx, thisElemOnSelect, selectionHandles, fillColor) {
	ctx.fillStyle = fillColor;
	ctx.globalAlpha = 0.4;
	// We can skip the drawing of elements that have moved off the screen:
	//if (this.x > WIDTH || this.y > HEIGHT) return; 
	//if (this.x + this.w < 0 || this.y + this.h < 0) return;

	ctx.fillRect(this.x, this.y, this.w, this.h);

	// draw selection
	// this is a stroke along the box and also 8 new selection handles
	if (thisElemOnSelect) {
		ctx.strokeStyle = mySelBoxColor;
		ctx.lineWidth = selectionWidth;
		ctx.strokeRect(this.x,this.y,this.w,this.h);

		// draw the boxes

		var half = mySelBoxSize / 2;

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
		}
		if(this.zoomBox){
			ctx.fillStyle = "#33FF33";
			var zbs=this.zoomBoxSize();
			ctx.fillRect(zbs.x, zbs.y, zbs.w, zbs.h);
			ctx.fillStyle = "#000000";
			ctx.fillText("zoom", zbs.x+2, zbs.y+10);
		}
	}
}

RegionTagCanvasElem.prototype.zoomBoxSize = function() {
	return {"x": this.x + this.w/2-12, "y": this.y+this.h/2-10, "w":28, "h":15}
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
function FreeHandTagCanvasElem(fill) {
	// This is a very simple and unsafe constructor. 
	// All we're doing is checking if the values exist.
	this.fill = fill || '#AAAAAA';
	this.points=[];
}

FreeHandTagCanvasElem.prototype.toJSON = function() {
	return this.points;
}

FreeHandTagCanvasElem.prototype.addPoint = function(x_t, y_t, svg, transformMat) {
	var pt = svg.createSVGPoint();
	pt.x = x_t;
	pt.y = y_t;
	var globalPoint = pt.matrixTransform(transformMat);
	
	this.points.push([globalPoint.x, globalPoint.y]);
}

FreeHandTagCanvasElem.prototype.isValidElem = function() {
	return (this.points.length>1);
}

FreeHandTagCanvasElem.prototype.transform = function(x, y, scale) {
	for (var i=0; i<this.points.length; i++){
		this.points[i][0]= this.points[i][0]/scale+x;
		this.points[i][1]= this.points[i][1]/scale+y;
	}
}
// Draws this shape to a given context
FreeHandTagCanvasElem.prototype.draw = function(ctx, fillColor) {
	ctx.strokeStyle = fillColor;
	ctx.beginPath();
	for (var i=0; i<this.points.length; i++){
		if (i==0) ctx.moveTo(this.points[i][0], this.points[i][1]);
		else {
			ctx.lineTo(this.points[i][0], this.points[i][1]);
			ctx.stroke();
		}
	}
	ctx.closePath();
}




