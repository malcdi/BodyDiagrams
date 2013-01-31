class window.CanvasRectDrawHandler extends CanvasEventHandler
  constructor:(args)->
    super(args)
  
  mousedown: (e) ->
    e.preventDefault()
    self = @
    $(window).bind('mouseup', (e)->
      return self.mouseup(e)
    )

    @canvasState.deHighlightFrame()
    @mouseDown = true
    
    #creating a new free hand tag
    @regionSelection = new RegionElem("#F89393", @canvasState.cur_view_side)
    tPoint = @canvasState.getPoint(e)
    @regionSelection.setOrigin(tPoint)

    #find out the frame it belongs to
    tagFrameGroup = @canvasState.highlighted.frame
    @regionSelection.setIndex(tagFrameGroup, @canvasState.addTagElem(@regionSelection, tagFrameGroup))

    #create the element in svg
    @curElem = @canvasState.createInSvg(tagFrameGroup, @regionSelection.type)

  mousemove: (e) ->
    e.preventDefault()
    if @mouseDown
      tPoint = @canvasState.getPoint(e)
      @regionSelection.updateRegion tPoint
      @canvasState.drawInSvg(@curElem, @regionSelection)
      return

  mouseup: (e) ->
    $(window).unbind('mouseup')
    if @mouseDown
      @mouseDown = false
      unless @regionSelection.isValidElem()
        @canvasState.deleteTag(@regionSelection.frame, @regionSelection.sub)
      else
        @canvasState.drawInSvg(@curElem, @regionSelection)
        window.triggerEvent({
          type:'newTag', 
          message:{
            frame:@regionSelection.frame
            sub:@regionSelection.sub
            type:@regionSelection.type
            data:@regionSelection.getRectBound()}
        })

        #highlight frame
        @canvasState.highlightFrame @regionSelection.frame, @regionSelection.sub
        
      return