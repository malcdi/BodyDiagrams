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
      dragOK = @canvasState.imageInBound(dragX, dragY)
      dragX = if dragOK.x then dragX else 0
      dragY = if dragOK.y then dragY else 0

      newMat = @canvasState.tracker.translate(dragX, dragY)
      @canvasState.svg.attr "transform", "matrix(" + newMat.a + "," + newMat.b + "," + newMat.c + "," + newMat.d + "," + newMat.e + "," + newMat.f + ")"
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
        message:{ frameIndex:@dragElem.frameIndex, subIndex:@dragElem.subIndex, dataPoints:@dragElem.tag.points}
      })
    else if @draggedAmt==0
      @canvasState.highlightFrame(@dragElem.frameIndex, @dragElem.subIndex)
    else 
      window.triggerEvent({type:'imageMovingDone'})

    @dragStart = null
    @draggedAmt = -1
    @unsetDraggable()

  mousewheel: (e) ->
    delta = (if e.originalEvent.wheelDelta then e.originalEvent.wheelDelta / 40 else (if e.originalEvent.detail then e.originalEvent.detail else 0))
    zoom delta, @canvasState  if delta
    e.preventDefault() and false
