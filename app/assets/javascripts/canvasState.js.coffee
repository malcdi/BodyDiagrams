class window.CanvasState

  constructor: (cv, options) ->
    
    @line = d3.svg.line().x((d) ->
      d.x
    ).y((d) ->
      d.y
    ).interpolate("linear")

    
    @allTags = [] #all freehand elems

    #drawing parameters
    @strokeWidth = 3
    
    #recording states
    @tagFrame = -1
    @highlighted = {frame:-1, sub:-1}
    
    #SETS up using options
    @gender = (if options then options.currentGender else "male")
    @cur_view_side = 0
    @mode = (if options.mode then options.mode else "drag")
    @imageLoader = options.imageLoader
    
    # Zoom related variables
    @canvas = d3.select(cv).node()
    @cur_view_side = 0
    @lastZoom ={"x": options.width / 2, "y":options.height / 2}
    @tracker = {}
    trackSVGTransforms @tracker, document.createElementNS("http://www.w3.org/2000/svg", "svg")

    # registering mouse events 
    cv = this
    @svg = d3.select("#canvasDiv").append("svg")
      .attr("width", options.width).attr("height", options.height)

    @svg = @svg.append("g")
      .call((selection)->
        window.eventManager.setup('svgCanvas', selection, cv)
      )
   
    # add image
    imgRatio = 3/7
    imgH = options.height - options.margin*2

    @srcImg = @svg.append("image").attr("x", (options.width - imgH*imgRatio) / 2)
      .attr("y", options.margin)
      .attr("width", imgH*imgRatio)
      .attr("height", imgH)
      .attr("xlink:href", @imageLoader.getBodyImageSrc(@gender, @cur_view_side))

    @dragEventHandler = new window.CanvasZoomHandler(this)
    @drawEventHandler = new window.CanvasDrawHandler(this)
    @rectDrawEventHandler = new window.CanvasRectDrawHandler(this)

    @summaryManager = new window.SummaryManager(this)

  # View Side related #

  changeFrame: (newFrameIndex)->
    view_side = @getGrouper(newFrameIndex).attr('view_side')
    @highlighted.frame = newFrameIndex
    @setView(+view_side)

  setView: (view) ->
    _=@
    @cur_view_side = view
    @srcImg.attr "xlink:href", @imageLoader.getBodyImageSrc(@gender, @cur_view_side)
    @deHighlightFrame()
    @updateOpacityLevels()

  updateViewStatus: (view)->
    @getGrouper(@highlighted.frame).attr('view_side', view)

  getView: ->
    @cur_view_side

  rotatable:->
    @allTags[@highlighted.frame].length==0

  ####################

  getEventHandler:(name)->
    _ = @
    ()->
      switch _.mode
        when "drag"
          _.dragEventHandler[name] d3.event
        when "draw"
          _.drawEventHandler[name] d3.event
        when "rect_draw"
          _.rectDrawEventHandler[name] d3.event

  setStrokeWidth: (width) ->
    @strokeWidth = width

  updateStrokeColor:(frame, sub, col)->
    tagGroup = @getTagGroup(frame, sub)
    unless tagGroup.empty()
      svgTagElem = tagGroup.select('.tag')
        .style('stroke', col)

  addTagElem: (elem, frame) ->
    list = @allTags[frame]
    list.push elem
    @allTags[frame].length - 1

  # DELETES ###################a
  showNextUndo: ->
    if @allTags[@highlighted.frame]
      curLen = @allTags[@highlighted.frame].length
      if curLen > 0
        @updateStrokeColor(@highlighted.frame, curLen-1, colorSelector('highlight'))

  hideNextUndo: ->
    if @allTags[@highlighted.frame]
      curLen = @allTags[@highlighted.frame].length
      if curLen > 0
        @updateStrokeColor(@highlighted.frame, curLen-1, colorSelector('default'))

  #deletes the tag at frame and sub index from the data and SVG
  # returns deleted
  deleteTag: (frame, sub)->
    if frame is undefined
      frame = @highlighted.frame

    elemDeleted = null
    curLen = @allTags[frame].length
    if curLen > 0
      if sub is undefined
        sub = curLen-1
      elemDeleted = @allTags[frame].splice(sub, 1)
      tagGroup = @getTagGroup(frame, sub)
      tagGroup.remove()  unless tagGroup.empty()
    elemDeleted[0]

  # DELETE END ###################

  getPoint: (e) ->
    element = @canvas
    offsetX = 0
    offsetY = 0
    mx = undefined
    my = undefined
    if element.offsetParent isnt `undefined`
      loop
        offsetX += element.offsetLeft
        offsetY += element.offsetTop
        break unless (element = element.offsetParent)
    mx = e.pageX - offsetX
    my = e.pageY - offsetY
    @tracker.transformedPoint({x:mx, y:my})

  submitAll: (gender) ->
    if @allTags.length is 0
      alert "please express your symptoms!"
      return
    self = this

    $.ajax(
      type: "POST"
      url: "postTag"
      data:
        tagData: JSON.stringify(self.allTags)
    ).done (msg) ->
      self.submitComplete()

  submitComplete: ->
    alert "complete"
    window.location = "/main/complete?user_id=" + @userID

  updateOpacityLevels: ()->
    _= @
    @svg.selectAll("g.frameGroup").style "opacity", (d) ->
      unless +this.attributes.getNamedItem("view_side").value is _.cur_view_side
        return 0
      else if this.id is "tag_#{_.highlighted.frame}"
        return 1.0
      else 
        return 0.3
    @summaryManager.updateSummaryDisplay @highlighted.frame

  startNewFrame: ()->
    @deHighlightFrame()
    #create new
    @tagFrame += 1
    @highlighted.frame = @tagFrame
    @allTags.push []
    @getGrouper(@tagFrame)
    @updateOpacityLevels()

  getCurrentFrameData:->
    data = {}
    data.gender = @gender
    data.cur_view_side = @cur_view_side
    data.index = @tagFrame
    return data

  # HIGHLIGHTED TAG PROPERTY MANAGEMENT ##########
  getHighlightedTagProperties: () ->
    if @isHighlighted()
      return @allTags[@highlighted.frame][@highlighted.sub].getProperties()
    return {}
    
  uploadTagProperties: (properties, index) ->
    frameElems = @allTags[index.frame]
    frameElems[index.sub].saveProperties(properties)
  # END ##########

  #  Highlights #################
  deHighlightFrame: ->   
    grouper = @svg.select("#tag_#{@highlighted.frame}")
    if @isHighlighted()
      window.triggerEvent({
        type:'highlighted', 
        message:{highlight:false}
      })
      @updateStrokeColor(@highlighted.frame, @highlighted.sub, colorSelector('default'))
      #open up summary
      @updateSummary(@highlighted.frame, @highlighted.sub, true)

    @highlighted.sub = -1

  getBoundingBox:(frame, sub)->
    frameElems = @allTags[frame]
    frameElems[sub].getRectBound()

  highlightFrame: (index, sub) ->
    @summaryManager.closeSummary(index, sub)
    index = @allTags.length - 1  if index < 0
    frameElems = @allTags[index]
    return  if not frameElems or frameElems.length < 1
    return  unless frameElems[0].view is @cur_view_side
    @deHighlightFrame()

    @highlighted.frame = index
    @highlighted.sub = sub    
    boundingBox = @getBoundingBox(index, sub)
    @updateStrokeColor(index, sub, colorSelector('highlight'))
    
    window.triggerEvent({
      type:'highlighted', 
      message: {highlight:true, box:boundingBox, 
      properties: @getHighlightedTagProperties(),index: @highlighted}
    })

  isHighlighted: ->
    @highlighted.frame >= 0 and @highlighted.sub>=0

  # HIGHLIGGHTS END ##############

  #### SUMMARY STUFF
  updateSummary: (frame, sub, updateContent)->
    properties = @allTags[frame][sub].getProperties()
    summaryItem = @summaryManager.getSummary(frame, sub)

    if summaryItem
      box = @getBoundingBox(frame, sub)
      summaryItem.attr('class', 'summary')
        .attr('transform',"translate(#{box.x+box.w+5},#{box.y-25})")
      if updateContent then @summaryManager.updateSummaryContent(summaryItem, properties)
  ########

  setMode: (modeName) ->
    @mode = modeName
    switch @mode
      when "drag"
        @canvas.style.cursor = "default"
      when "draw"
        @canvas.style.cursor = "url('/assets/drawHand.png'), auto"
      when "rect_draw"
        @canvas.style.cursor = "crosshair"

  #MOVING AROUND STUFF ###########

  findCenter:(sx, sy, tx, ty)->
    centerX = (tx+(+@srcImg.attr('x'))+(+@srcImg.attr('width')/2))
    centerY = (ty+(+@srcImg.attr('y'))+(+@srcImg.attr('height')/2))
    {x:centerX, y:centerY}

  imgBoundWDrag:(center, dragX, dragY, dragCheck)->
    xOUB = (center.x-60<0 and (!dragCheck or dragX<0)) or (center.x+60>+$('svg').attr('width') and (!dragCheck or dragX>0))
    yOUB = (center.y<0 and (!dragCheck or dragY<0)) or (center.y>+$('svg').attr('height') and (!dragCheck or dragY>0))
    {x:!xOUB, y:!yOUB}

  imageInBound: (dragX, dragY)->
    mat = @svg.attr('transform')
    if mat
      matchedStr = mat.match /matrix\((.*),(.*),(.*),(.*),(.*),(.*)\)/
    return true if matchedStr is null or matchedStr is undefined
    center = @findCenter(+matchedStr[1], +matchedStr[4], +matchedStr[5], +matchedStr[6])
    return @imgBoundWDrag(center, dragX, dragY, true)
    

  zoom: (clicks) ->
    pt = @tracker.transformedPoint(@lastZoom.x, @lastZoom.y)
    factor = Math.pow(1.1, clicks)
    @tracker.scale factor, factor
    newMat = @tracker.getTransform()
    center = @findCenter(newMat.a, newMat.d, newMat.e, newMat.f)
    boundness = @imgBoundWDrag(center, 0, 0, false)
    if boundness.x and boundness.y
      @svg.attr "transform", "matrix(" + newMat.a + "," + newMat.b + "," + newMat.c + "," + newMat.d + "," + newMat.e + "," + newMat.f + ")"
      return true
    false

  setZoomPan: (deltaX, deltaY, deltaZoom) ->
    @tracker.translate deltaX, deltaY
    @lastZoom.x = @canvas.width / 2
    @lastZoom.y = @canvas.height / 2
    return @zoom deltaZoom

  getGraphicSvgElem:(parent)->
    parent.select('.tag')

  moveElement: (elem, movePixel)->
    elem.tag.moveAll movePixel #update points stored in tag
    @updateSummary(elem.frame, elem.sub,false)
    @drawInSvg(@getGraphicSvgElem(elem.graphicTag), elem.tag)

    window.triggerEvent({
      type:'tagMoving', 
      message:{ box:elem.tag.getRectBound()}
    }) #notify moving tag
    
  unsetDraggable: (elem)->
    return if(elem.frame==@highlighted.frame and elem.sub==@highlighted.sub)
    @updateStrokeColor(elem.frame, elem.sub, colorSelector('default'))

  setDraggable: (elem)->
    @updateStrokeColor(elem.frame, elem.sub, colorSelector('highlight'))

  #MOVING AROUND STUFF DONE ###########

  elemUnderneath: (pt) -> 
    curTagL = @allTags[@highlighted.frame]
    l = curTagL.length
    j = 0

    while j < l
      if curTagL[j].view is @cur_view_side and curTagL[j].contains(pt.x, pt.y)
        grouper = @svg.select("#tag_#{@highlighted.frame}")
        return {frame:@highlighted.frame, sub:j, tag:curTagL[j], graphicTag:grouper.select("g:nth-child(#{j+1})")}
      j++
    return null

  getGrouper: (tagFrameGroup)->
    grouper = @svg.select("#tag_#{tagFrameGroup}")
    if grouper.empty()
      # create the group 
      grouper = @svg.append("svg:g")
        .attr("id", "tag_#{tagFrameGroup}")
        .attr("view_side", @cur_view_side)
        .attr('class','frameGroup')
    grouper

  getTagGroup:(frame, sub)->
    grouper = @svg.select("#tag_#{frame}")
    if grouper.empty() then return null
    childNodes = grouper.node().childNodes
    if childNodes.length<=sub then return null
    d3.select(childNodes[sub])
    
  newTag: (tagFrameGroup, grouper, type)->
    strokeColor = colorSelector('default')

    sub = grouper.node().childNodes.length
    tagGroup = grouper.append("g")
      .attr('tag_type', type)
    self = @

    @summaryManager.setupSummary(tagGroup, tagFrameGroup, sub)
    elem = null
    switch type
      when 'hand'
        #path tag
        elem = tagGroup.append("path")
          .attr("fill", "none")
      when 'region'
        elem = tagGroup.append("rect")
          .attr('fill', strokeColor)
          .attr('fill-opacity', 0.2)

    elem.attr("stroke-width", @strokeWidth)
      .attr("stroke", strokeColor)
      .attr('class', 'tag')

  # creates and retuns created drawn element
  createInSvg: (tagFrameGroup, type)->
    grouper = @getGrouper(tagFrameGroup)
    @newTag(tagFrameGroup, grouper, type)

  drawInSvg: (elem, dataElem)->
    switch dataElem.type
      when 'hand'
        elem.attr "d", @line(dataElem.drawData())
      when 'region'
        box = dataElem.drawData()
        elem.attr('x', box.x)
          .attr('y', box.y)
          .attr('width', box.w)
          .attr('height', box.h)
  

