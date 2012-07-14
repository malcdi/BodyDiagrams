/* Constructor for AutoAjax Class 
  input: id of the input tag
  event: the event of input tag that will be listened to
  queryURL: url from which ajax will request information
*/
function AutoAjax (input, event, post_form, queryURL) {
  this.inputBox = document.getElementById(input);
  this.inputBox[event]=this.wrap(this, "requestForEvent");

  //generates AJAX request object.
  if (window.XMLHttpRequest) {
    this.xmlReq = new XMLHttpRequest();	
  } else {
    this.xmlReq = new ActiveXObject("Microsoft.XMLHTTP");
  }
  this.xmlReq.onreadystatechange= this.wrap(this, "onReadyStateChange");
  
  //specifies URL from which AJAX will request information.
  this.queryURL=queryURL;
  
  //specifies element where results will be displayed
  //this.queryDisp=document.getElementById(resultDisp);
  this.form_elem=document.getElementById(post_form);
}

AutoAjax.prototype.wrap = function(obj, method) {
  return function() {
    obj[method]();
  }
}

/* Displays results in the specified resultDisp element */
AutoAjax.prototype.displayResults = function(htmlRender) {
  this.queryDisp.innerHTML=htmlRender;
}

/* Called whenever event listener called. */
AutoAjax.prototype.requestForEvent = function() {  
  if(this.xmlReq){
    //sends request to the server.
    //var queryStr = this.queryURL+"?query="+encodeURIComponent(this.inputBox.value);  
    var queryStr = this.queryURL;
    var fd= new FormData(this.form_elem);
    //TODO: set type variable, display pain type.
    
    this.xmlReq.open("POST",queryStr, true);
    //this.xmlReq.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    this.xmlReq.setRequestHeader("X-Requested-With","XMLHttpRequest");
    this.xmlReq.send(fd);
  }
}

/* Handles incoming data from server */
AutoAjax.prototype.onReadyStateChange = function() {
  if(this.xmlReq.readyState !=4 || this.xmlReq.status!=200)
  {
    return;
  }
  console.log(this.xmlReq.responseText);

  //TODO: redisplay "all the tagged"
  //    allow further tags to be attached.
}


