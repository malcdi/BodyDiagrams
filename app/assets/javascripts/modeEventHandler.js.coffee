class window.ModeEventHandler 

  zoomElem = $("#drag")
  drawElem = $("#draw")
  drawSetElem = $("#drawSet")
  newSymptomElem = $("#newDraw")
  doneElem = $("#done_button")

  constructor: (bigBro) ->
    @newSymptom = false #new symptom initialized.
    @zoomMode = true

    @bigBro= bigBro

  #Helper Functions
  getView: (curView, direction) ->
    if direction is "left"
      return (curView + 1) % 4
    else return (curView + 3) % 4  if direction is "right"
    0

  getOtherView: (direction) ->
    if direction is "left"
      return "right"
    else return "left"  if direction is "right"
    ""
  #

  handleEvents: (clickedName, arg) ->
    if clickedName is "drag"
      @zoomMode = true
      @bigBro.cvState.setMode "zoom"
      @zoomElem[0].src = "/assets/dragHand.png"
      @zoomElem[0].style.border = "solid 2px rgb(108, 204, 128)"
      @drawElem[0].src = "/assets/drawIconInactive.png"
      @drawElem[0].style.border = "solid 2px rgb(108, 204, 128)"
      @drawElem[0].style.border = ""
      @drawSetElem.css "opacity", 0.0  unless @newSymptom
    if clickedName is "draw"
      @zoomMode = false
      @bigBro.cvState.setMode "draw"
      @drawElem[0].src = "/assets/drawIcon.png"
      @drawElem[0].style.border = "solid 2px rgb(108, 204, 128)"
      @zoomElem[0].src = "/assets/dragHandInactive.png"
      @zoomElem[0].style.border = ""
      @drawSetElem.css "opacity", 1.0
    else if clickedName is "newDraw"

      #was drawing: done -> new 
      @doneElem.trigger "click"  if @newSymptom
      @zoomMode = false
      @newSymptom = true
      @doneElem.css "display", "block"
      handler = this
      @drawElem.bind "click", ->
        handler.handleEvents "draw", @bigBro.cvState

      @drawElem.trigger "click"
      @bigBro.cvState.startRecordingNewMsg()
      @bigBro.cvState.deHighlightCloud()
      
      #creates new element in the list
      @bigBro.commentController.createNew arg
      @newSymptomElem[0].src = "/assets/plus.png"
    else if clickedName is "done"
      @newSymptom = false
      @drawElem.unbind "click"
      
      #this.commentController.updateAnnotations(this.bigBro.cvState.allTags[arg], arg);
      @bigBro.commentController.editDone arg
      @doneElem.css "display", "none"
      @bigBro.cvState.stopRecordingNewMsg()
      @bigBro.cvState.deHighlightCloud()
      @zoomElem.trigger "click"
    else if clickedName is "undo"
      if arg[0] is "click"
        @bigBro.cvState.undoLastDrawing()
      else if arg[0] is "mouseover"
        @bigBro.cvState.highlightNextUndo()
      else @bigBro.cvState.deHighlightNextUndo() if arg[0] is "mouseleave"

    else if clickedName is "rotate"
      @bigBro.currentView = @getView(@bigBro.currentView, @id)
      @src = @bigBro.ImageLoader.getBodyImageSrc(@bigBro.currentGender, @getView(@bigBro.currentView, @id))
      otherDirection = @getOtherView(@id)
      $("#" + otherDirection)[0].src = @bigBro.ImageLoader.getBodyImageSrc(@bigBro.currentGender, @getView(@bigBro.currentView, otherDirection))
      @bigBro.cvState.setView currentView
