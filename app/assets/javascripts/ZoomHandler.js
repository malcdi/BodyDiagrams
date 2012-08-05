/* Handle zooming events on the main canvas
 * courtesy: http://dev.opera.com/articles/view/html5-canvas-painting/
 */

function ZoomHandler(mainCanvasElement, zoomCanvasStateElement){
	
	var myZH = this;
	
	this.inZoomState=false;
	this.mainCanvasElement=mainCanvasElement;
	this.zoomCanvasStateElement=zoomCanvasStateElement;
	var inZoomState=this.inZoomState;
	
	var startX = null;
	var startY = null;
	var endX = null;
	var endY = null;
	
	//DM: event handling for the zoom functionality
	$(document.body).on('keydown', function(e) {
		if(e.which == 37 && !inZoomState){ // 37 is the key code for left arrow
			inZoomState=true;
	        console.log('in zoom state. zoomState: ' + inZoomState);
	
			var mainCanvas = document.getElementById('canvas');
			var container = mainCanvas.parentNode;

			zoomHandlerCanvas = document.createElement('canvas');
			zoomHandlerCanvas.id='zoomHandlerCanvas';
			zoomHandlerCanvas.width  = mainCanvas.width;
		  	zoomHandlerCanvas.height = mainCanvas.height;
			container.appendChild(zoomHandlerCanvas);

			context = zoomHandlerCanvas.getContext('2d');
			
			zoomHandlerCanvas.addEventListener('mousedown', function(e) {
				var mouse = myZH.getMouse(e);
				startX = mouse.x;
				startY = mouse.y;
			}, true);
			
			zoomHandlerCanvas.addEventListener('mouseup', function(e) {
				var mouse = myZH.getMouse(e);
				endX = mouse.x;
				endY = mouse.y;
			}, true);
		}
	});
	
	$(document.body).on('keyup', function(e) {
	   	if (e.which == 37) { //key code for left arrow; change this to something better like shift...
			inZoomState=false;
            console.log('out of zoom state');
			console.log(startX + ", " + startY + ", " + endX + ", " + endY);
			var zoomHandlerCanvas = document.getElementById('zoomHandlerCanvas');
			var container = zoomHandlerCanvas.parentNode;
			container.removeChild(zoomHandlerCanvas);
			
			//send the call to zoom, and reset all values
			
			zoomCanvasStateElement.setZoomConstants(Math.min(startX, endX), Math.min(startY, endY), 337/Math.abs(startX - endX), 750/(Math.abs(startY - endY)));
			console.log("StartX and StartY: " + startX + "," + startY);
			startX=null;
			startY=null;
			endX=null;
			endY=null;
	    }
	});
}

// Creates an object with x and y defined,
// set to the mouse position relative to the state's canvas
// If you wanna be super-correct this can be tricky,
// we have to worry about padding and borders
ZoomHandler.prototype.getMouse = function(e) {
	var element = this.mainCanvasElement.canvas, offsetX = 0, offsetY = 0, mx, my;
	
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