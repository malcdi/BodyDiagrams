class window.CanvasEventHandler

  constructor:(@canvasState)->
    @dragElem=null
    @dragStart=null
    @draggingElement=false
    @dragOff={"x":0, "y":0}
    @mouseDownForFreeHand=false

  unsetDraggable: ()->
    if @dragElem then @canvasState.unsetDraggable(@dragElem)
    @dragElem = null

  isSameElem:(a, b)->
    return a.frame is b.frame and 
        a.sub is b.sub
      
  setDraggable: (elemUnder)->
    if @dragElem is not null
      return if @isSameElem(@dragElem, elemUnder)
      @canvasState.unsetDraggable(@dragElem)
    @dragElem = elemUnder
    @canvasState.setDraggable(elemUnder)
