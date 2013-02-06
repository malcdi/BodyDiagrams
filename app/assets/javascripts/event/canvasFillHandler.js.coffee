class window.CanvasFillHandler extends CanvasEventHandler

  constructor:(args)->
    super(args)

  click: (e) ->
    e.preventDefault()
    @canvasState.lastZoom = {x:e.offsetX, y:e.offsetY}
    tPoint = @canvasState.getPoint(e)
    return if (@elemUnder is null) or (!@elemUnder) or (@elemUnder.tag.type=="region")
    
    @canvasState.setFilled(@elemUnder)

  mousemove: (e)->
    e.preventDefault()
    @canvasState.lastZoom = {x:e.offsetX, y:e.offsetY}
    tPoint = @canvasState.getPoint(e)
    @elemUnder = @canvasState.elemUnderneath(tPoint)
    if @elemUnder is null or undefined
      @unsetDraggable()
    else
      @setDraggable(@elemUnder)
