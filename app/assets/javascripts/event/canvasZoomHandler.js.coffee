class window.CanvasZoomHandler extends CanvasEventHandler

  constructor:(args)->
    super(args)

  mousedown: (e) ->
    e.preventDefault()
    self = @
    $(window).bind('mouseup', ()->
      return self.mouseup(e)
    )

    if @dragElem
      @draggedAmt = 0
      @dragOff = @canvasState.getPoint(e)
      @canvasState.highlightFrame() #highlight the elem
      return
    @canvasState.lastZoom = {x:e.offsetX, y:e.offsetY}
    @dragStart = @canvasState.tracker.transformedPoint(@canvasState.lastZoom)

  mousemove: (e) ->
    e.preventDefault()
    @canvasState.lastZoom = {x:e.offsetX, y:e.offsetY}
    tPoint = @canvasState.getPoint(e)
    if @dragStart
      #moving around background image
      pt = @canvasState.tracker.transformedPoint(@canvasState.lastZoom)
      dragX = pt.x - @dragStart.x
      dragY = pt.y - @dragStart.y
      @canvasState.setZoomPan(dragX, dragY,0)
      
    else if @draggedAmt>=0
      #moving around the element
      movePixel = {mx:tPoint.x - @dragOff.x, my:tPoint.y - @dragOff.y}

      @canvasState.moveElement(@dragElem, movePixel)
      @dragOff = tPoint
      @draggedAmt+=1
    else
      elemUnder = @canvasState.elemUnderneath(tPoint)
      if elemUnder is null or undefined
        @unsetDraggable()
      else
        @setDraggable(elemUnder)

  mouseup: (e) ->
    $(window).unbind('mouseup')
    if @draggedAmt>0
      window.triggerEvent({
        type:'tagMovingDone', 
        message:{ frame:@dragElem.frame, sub:@dragElem.sub, type: @dragElem.tag.type, data:@dragElem.tag.drawData()}
      })
    else if @draggedAmt==0
      @canvasState.highlightFrame(@dragElem.frame, @dragElem.sub)
    else 
      window.triggerEvent({type:'imageMovingDone'})

    @dragStart = null
    @draggedAmt = -1
    @unsetDraggable()

