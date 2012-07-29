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
	this.w = w || 1;
	this.h = h || 1;
	this.fill = fill || '#AAAAAA';
}

// Draws this shape to a given context
RegionTagCanvasElem.prototype.draw = function(ctx, WIDTH, HEIGHT, thisElemOnSelect, selectionHandles) {
	ctx.fillStyle = this.fill;
	// We can skip the drawing of elements that have moved off the screen:
	if (this.x > WIDTH || this.y > HEIGHT) return; 
	if (this.x + this.w < 0 || this.y + this.h < 0) return;

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


		ctx.fillStyle = mySelBoxColor;
		for (var i = 0; i < 8; i ++) {
			var cur = selectionHandles[i];
			ctx.fillRect(cur.x, cur.y, mySelBoxSize, mySelBoxSize);
		}
	}
}

RegionTagCanvasElem.prototype.contains = function(mx, my) {
	if(mx < this.x || mx > this.x+this.w) return false;
	if(my < this.y || my > this.y+this.h) return false;
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

FreeHandTagCanvasElem.prototype.addPoint = function(x_t, y_t) {
	this.points.push({x:x_t, y:y_t});
}

// Draws this shape to a given context
FreeHandTagCanvasElem.prototype.draw = function(ctx) {
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




