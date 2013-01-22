# Constant Value Options
#  for selection boxes

# REGION TAGS 

# Constructor for RegionTag objects to hold data relevant to drawing.


# Draws this shape to a given context

# We can skip the drawing of elements that have moved off the screen:
#if (this.x > WIDTH || this.y > HEIGHT) return; 
#if (this.x + this.w < 0 || this.y + this.h < 0) return;

# draw selection
# this is a stroke along the box and also 8 new selection handles

# draw the boxes

#
#		// 0  1  2
#		// 3     4
#		// 5  6  7
#		// top left, middle, right
#		selectionHandles[0].x = this.x-half;
#		selectionHandles[0].y = this.y-half;
#
#		selectionHandles[1].x = this.x+this.w/2-half;
#		selectionHandles[1].y = this.y-half;
#
#		selectionHandles[2].x = this.x+this.w-half;
#		selectionHandles[2].y = this.y-half;
#
#		//middle left
#		selectionHandles[3].x = this.x-half;
#		selectionHandles[3].y = this.y+this.h/2-half;
#
#		//middle right
#		selectionHandles[4].x = this.x+this.w-half;
#		selectionHandles[4].y = this.y+this.h/2-half;
#
#		//bottom left, middle, right
#		selectionHandles[6].x = this.x+this.w/2-half;
#		selectionHandles[6].y = this.y+this.h-half;
#
#		selectionHandles[5].x = this.x-half;
#		selectionHandles[5].y = this.y+this.h-half;
#
#		selectionHandles[7].x = this.x+this.w-half;
#		selectionHandles[7].y = this.y+this.h-half;
#
#
#		ctx.globalAlpha = 1.0;
#		ctx.fillStyle = mySelBoxColor;
#		for (var i = 0; i < 8; i ++) {
#			var cur = selectionHandles[i];
#			ctx.fillRect(cur.x, cur.y, mySelBoxSize, mySelBoxSize);
#		}

#DM: I added some margin for error here; it was difficult to select the selResizeBoxes on the drawing canvas after initially creating a region selection

# FREE HAND TAGS 

# Constructor for RegionTag objects to hold data relevant to drawing.

