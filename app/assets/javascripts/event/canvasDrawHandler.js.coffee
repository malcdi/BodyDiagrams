class window.CanvasDrawHandler extends CanvasEventHandler
  constructor:(args)->
    super(args)
  
  mousedown: (e) ->
    e.preventDefault()
    self = @
    $(window).bind('mouseup', (e)->
      return self.mouseup(e)
    )
    @mouseDownForFreeHand = true
    
    @canvasState.deHighlightFrame()

    #creating a new free hand tag
    @canvasState.handSelection = new FreehandElem("#F89393", @canvasState.cur_view_side)
    tPoint = @canvasState.getPoint(e)
    @canvasState.handSelection.addPoint tPoint.x, tPoint.y

    #find out the frame it belongs to
    tagFrameGroup = @canvasState.highlighted.frame
    @canvasState.handSelection.frameIndex = tagFrameGroup
    @canvasState.handSelection.tagIndex = @canvasState.addFreehandElem(@canvasState.handSelection, tagFrameGroup)

    #create the element in svg
    @canvasState.createInSvg(tagFrameGroup)

  mousemove: (e) ->
    e.preventDefault()
    if @mouseDownForFreeHand
      tPoint = @canvasState.getPoint(e)
      @canvasState.handSelection.addPoint tPoint.x, tPoint.y
      @canvasState.drawInSvg()
      return

  mouseup: (e) ->
    $(window).unbind('mouseup')
    if @mouseDownForFreeHand
      @mouseDownForFreeHand = false
      unless @canvasState.handSelection.isValidElem()
        @canvasState.deleteTag(@canvasState.handSelection.frameIndex, @canvasState.handSelection.tagIndex)
      else
        @canvasState.drawInSvg()
        $(window).trigger({
          type:'newTag', 
          message:{"points":@canvasState.handSelection.points}
        })

        #highlight frame
        @canvasState.highlightFrame @canvasState.handSelection.frameIndex, @canvasState.handSelection.tagIndex
        
      return

  mousewheel: (e) ->
    false