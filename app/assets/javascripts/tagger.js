function Tagger(id, parent, form, x, y, w, h, type, m) {
  this.parent = document.getElementById(parent);
  this.parent.className="parent";

  this.element = document.getElementById(id);
  this.element.className="tagger";
  this.element.style.borderWidth = "2px";
  this.element.style.visibility="hidden";
  this.isMouseDown=false;

  this.parent.onmousedown = this.wrap(this, "mouseDown");

  this.x_form=document.getElementById(x);
  this.y_form=document.getElementById(y);
  this.w_form=document.getElementById(w);
  this.h_form=document.getElementById(h);
  this.type_form=document.getElementById(type);
  this.type_form.value=1;

  
	this.menu=document.getElementById(m);
	this.menu.style.visibility="hidden";
	
	this.ajaxReq=new AutoAjax(m, "onmouseup", form, "/main/post_draw");
}

Tagger.prototype.wrap = function(obj, method) {
	return function(event) {
		obj[method](event);
	}
}

Tagger.prototype.mouseDown = function(event) {
	//TODO: only when on the menu up!
	if((this.menu.style.visibility=="visible")) {
		return;
	}
	
	var obj = this;
	this.oldMoveHandler = document.body.onmousemove;
	document.body.onmousemove = this.wrap(this, "mouseMove");
	this.oldUpHandler = document.body.onmouseup;
	document.body.onmouseup = this.wrap(this, "mouseUp");

	this.startX=event.pageX-(this.parent.offsetLeft+this.parent.offsetParent.offsetLeft);
	this.startY=event.pageY-(this.parent.offsetTop+this.parent.offsetParent.offsetTop);
	this.element.style.left =  this.startX+ "px";
	this.element.style.top =  this.startY+ "px";
	this.element.style.width="0px";
	this.element.style.height="0px";
	this.isMouseDown = true;
	this.element.style.visibility="visible";
	this.menu.style.visibility="hidden";
}

Tagger.prototype.mouseMove = function(event) {
	if (!this.isMouseDown) {
		return;
	}

	//calculate origin point, greater than (0,0)
	var newX= Math.max(0, event.pageX-(this.parent.offsetLeft+this.parent.offsetParent.offsetLeft));
	var newY= Math.max(0, event.pageY-(this.parent.offsetTop+this.parent.offsetParent.offsetTop));

	this.element.style.left=Math.min(this.startX, newX)+ "px";
	this.element.style.top=Math.min(this.startY, newY)+ "px";

	//calculate width and height, cap at right bottom corner.    
	var border_width=2*parseInt(this.element.style.borderWidth);
	var newW=parseInt(this.parent.clientWidth)-Math.min(this.startX, newX)-border_width;
	var newH=parseInt(this.parent.clientHeight)-Math.min(this.startY, newY)-border_width;
	newW=Math.min(Math.abs(newX-this.startX), newW);
	newH=Math.min(Math.abs(newY-this.startY), newH);

	this.element.style.width=newW+"px";
	this.element.style.height=newH+"px";
}

Tagger.prototype.mouseUp = function(event) {
	this.isMouseDown = false;
	document.body.onmousemove = this.oldMoveHandler;
	document.body.onmouseup = this.oldUpHandler;

	//save tag region.
	this.x_form.value=parseInt(this.element.style.left);
	this.y_form.value=parseInt(this.element.style.top);
	this.w_form.value=parseInt(this.element.style.width);
	this.h_form.value=parseInt(this.element.style.height);
											
	//direct to choose a type.
	var l=parseInt(this.element.style.left)+parseInt(this.element.style.width);
	this.menu.style.left=l+"px";
	this.menu.style.top=this.element.style.top;
	this.menu.style.visibility="visible";	
}

