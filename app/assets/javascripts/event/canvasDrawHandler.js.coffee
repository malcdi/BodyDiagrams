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
    @handSelection = new FreehandElem("#F89393", @canvasState.cur_view_side)
    tPoint = @canvasState.getPoint(e)
    @handSelection.addPoint tPoint.x, tPoint.y

    #find out the frame it belongs to
    tagFrameGroup = @canvasState.highlighted.frame
    @handSelection.frameIndex = tagFrameGroup
    @handSelection.tagIndex = @canvasState.addTagElem(@handSelection, tagFrameGroup)

    #create the element in svg
    @curElem = @canvasState.createInSvg(tagFrameGroup, @handSelection.type)

  mousemove: (e) ->
    e.preventDefault()
    if @mouseDownForFreeHand
      tPoint = @canvasState.getPoint(e)
      @handSelection.addPoint tPoint.x, tPoint.y
      @canvasState.drawInSvg(@curElem, @handSelection)
      return

  mouseup: (e) ->
    $(window).unbind('mouseup')
    if @mouseDownForFreeHand
      @mouseDownForFreeHand = false
      unless @handSelection.isValidElem()
        @canvasState.deleteTag(@handSelection.frameIndex, @handSelection.tagIndex)
      else
        @canvasState.drawInSvg(@curElem, @handSelection)
        window.triggerEvent({
          type:'newTag', 
          message:{type:@handSelection.type, data:@handSelection.points}
        })

        #highlight frame
        @canvasState.highlightFrame @handSelection.frameIndex, @handSelection.tagIndex
        
      return