class window.CanvasZoomHandler extends CanvasEventHandler

  constructor:(args)->
    super(args)
  mousedown: (e) ->
    e.preventDefault()
    if this.dragElem
      this.draggingElement = true
      this.dragOff = @canvasState.getPoint(e)
      @canvasState.highlightFrame() #highlight the elem
      return
    this.lastZoom = {x:e.offsetX, y:e.offsetY}
    this.dragStart = @canvasState.tracker.transformedPoint(@canvasState.lastZoom)

  mousemove: (e) ->
    e.preventDefault()
    this.lastZoom = {x:e.offsetX, y:e.offsetY}
    tPoint = @canvasState.getPoint(e)

    if this.dragStart
      #moving around background image
      pt = @canvasState.tracker.transformedPoint(this.lastZoom)
      newMat = @canvasState.tracker.translate(pt.x - this.dragStart.x, pt.y - this.dragStart.y)
      #TODO: @canvasState.svg.attr "transform", "matrix(" + newMat.a + "," + newMat.b + "," + newMat.c + "," + newMat.d + "," + newMat.e + "," + newMat.f + ")"
    else if this.draggingElement
      #moving around the element
      mx = tPoint.x - @canvasState.dragOff.x
      my = tPoint.y - @canvasState.dragOff.y
      #TODO
      @canvasState.handSelection.moveAll mx,my 
      @canvasState.moveHighlightBox mx,my
      @canvasState.dragElem.attr "d", @canvasState.line(@canvasState.handSelection.points)

      this.dragOff = tPoint
    else
      elemUnder = @canvasState.elemUnderneath(tPoint)
      if elemUnder is null
        this.unsetDraggable()
      else
        this.setDraggable(elemUnder)

  mouseup: (e) ->
    this.dragStart = null
    this.draggingElement = false
    this.unsetDraggable()

  mousewheel: (e) ->
    delta = (if e.originalEvent.wheelDelta then e.originalEvent.wheelDelta / 40 else (if e.originalEvent.detail then e.originalEvent.detail else 0))
    zoom delta, @canvasState  if delta
    e.preventDefault() and false

