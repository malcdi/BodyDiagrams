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
    width = options.width - options.scW*2
    height = options.height
    trackSVGTransforms @tracker, document.createElementNS("http://www.w3.org/2000/svg", "svg")

    #summary container

    parent = d3.select(cv)
    summary_container = parent.append('div')
      .attr('id', 'summary_container')
      .style('position','absolute')
      .style('left','0px').style('top','0px')
      .style('width', "#{options.width}px").style('height',"#{height}px")

    @svg = parent.append("svg")
      .style('position','absolute')
      .style('left',"#{options.scW}px").style('top','0px')
      .attr("width", width).attr("height",height)
      .style('background-color','white')
      
    # add image
    imgRatio = 3/7
    @imgY = options.marginTop
    @imgH = height - @imgY*2
    @imgW = @imgH*imgRatio
    @imgMargin = (width - @imgW)/2
    @imgX = @imgMargin

    @svg = @svg.append("g")
      .attr('fill-rule', 'nonzero')
      .call((selection)=>
        window.eventManager.setup('svgCanvas', selection, @)
      )

    @srcImg = @svg.append("image").attr("x", @imgX)
      .attr("y", @imgY)
      .attr("width", @imgW)
      .attr("height", @imgH)
      .attr("xlink:href", @imageLoader.getBodyImageSrc(@gender, @cur_view_side))

    @dragEventHandler = new window.CanvasZoomHandler(this)
    @drawEventHandler = new window.CanvasDrawHandler(this)
    @rectDrawEventHandler = new window.CanvasRectDrawHandler(this)
    @fillEventHandler = new window.CanvasFillHandler(this)

    @summaryManager = new window.SummaryManager(this, summary_container, width, options.width-options.scW, options.scW)

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
        when "fill"
          _.fillEventHandler[name] d3.event

  setStrokeWidth: (width) ->
    @strokeWidth = width

  updateSeverityValue:(severityVal)->
    @updateStrokeColor(@highlighted.frame, @highlighted.sub, colorSelector(severityVal))

  updateStrokeColor:(frame, sub, col)->
    tagGroup = @getTagGroup(frame, sub)
    unless tagGroup==null or tagGroup.empty()
      tag = @allTags[frame][sub]
      svgTagElem = tagGroup.select('.tag')
        .style('stroke', col)
      if tag.type=="region" or tag.filled
        svgTagElem.style('fill',col)

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
        tag = @allTags[@highlighted.frame][curLen-1]
        severe_color = colorSelector(tag.property.prop_severity)
        @updateStrokeColor(@highlighted.frame, curLen-1, severe_color)

  #deletes the tag at frame and sub index from the data and SVG
  # returns deleted
  deleteTag: (frame, sub)->
    if frame is undefined
      frame = @highlighted.frame

    elemDeleted = null
    curLen = @allTags[frame].length
    if curLen > 0
      if sub is undefined then sub = curLen-1
      if sub is @highlighted.sub then @highlighted.sub=-1
      elemDeleted = @allTags[frame].splice(sub, 1)[0]
      tagGroup = @getTagGroup(frame, sub)
      tagGroup.remove()  unless tagGroup.empty()
      @summaryManager.tagDeleted elemDeleted.frame, elemDeleted.sub
    elemDeleted

  # DELETE END ###################

  getPoint: (e) ->
    element = @svg.node()
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
    @summaryManager.updateSummary(index.frame, index.sub, true)
  # END ##########

  #  Highlights #################
  deHighlightFrame: ->   
    grouper = @svg.select("#tag_#{@highlighted.frame}")
    if @isHighlighted()
      window.triggerEvent({
        type:'highlighted', 
        message:{highlight:false}
      })
      tag = @allTags[@highlighted.frame][@highlighted.sub]
      severe_color = colorSelector(tag.property.prop_severity)
      @updateStrokeColor(@highlighted.frame, @highlighted.sub, severe_color)

    @highlighted.sub = -1

  getBoundingBox:(frame, sub)->
    frameElems = @allTags[frame]
    frameElems[sub].getRectBound()

  highlightFrame: (index, sub) ->
    index = @allTags.length - 1  if index is undefined or index<0
    sub = @allTags[index].length - 1  if sub is undefined or sub<0
    frameElems = @allTags[index]
    return  if not frameElems or frameElems.length < 1
    return  unless frameElems[0].view is @cur_view_side
    @deHighlightFrame()

    @highlighted.frame = index
    @highlighted.sub = sub    
    boundingBox = @getBoundingBox(index, sub)
    @updateStrokeColor(index, sub, colorSelector('highlight'))
    #open up summary
    summary_pos = @summaryManager.updateSummary(@highlighted.frame, @highlighted.sub, false)

    window.triggerEvent({
      type:'highlighted', 
      message: {highlight:true, box:summary_pos, 
      properties: @getHighlightedTagProperties(),index: @highlighted}
    })

  isHighlighted: ->
    @highlighted.frame >= 0 and @highlighted.sub>=0

  # HIGHLIGGHTS END ##############

  #### SUMMARY STUFF
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
      when "fill"
        @canvas.style.cursor = "url('/assets/fill_cursor.png'), auto"

  #MOVING AROUND STUFF ###########

  findCenter:(sx, sy, tx, ty)->
    centerX = sx*(tx+(+@srcImg.attr('x'))+(+@srcImg.attr('width')/2))
    centerY = sy*(ty+(+@srcImg.attr('y'))+(+@srcImg.attr('height')/2))
    {x:centerX, y:centerY}

  imgBoundWDrag:(center, dragX, dragY, dragCheck)->
    room = 30
    xOUB = (center.x+room*2<0 and (!dragCheck or dragX<0)) or (center.x-room>@imgW+@imgX*2 and (!dragCheck or dragX>0))
    yOUB = (center.y+room*3.5<@imgY and (!dragCheck or dragY<0)) or (center.y-room>@imgH+@imgY*2 and (!dragCheck or dragY>0))
    {x:!xOUB, y:!yOUB}

  imageInBound: (dragX, dragY)->
    mat = @svg.attr('transform')
    if mat
      matchedStr = mat.match /matrix\((.*),(.*),(.*),(.*),(.*),(.*)\)/
    return {x:true, y:true} if matchedStr is null or matchedStr is undefined
    center = @findCenter(+matchedStr[1], +matchedStr[4], +matchedStr[5], +matchedStr[6])
    return @imgBoundWDrag(center, dragX, dragY, true)
    
  pan: (deltaX, deltaY)->
    boundness = @imageInBound(deltaX, deltaY)
    if boundness.x and boundness.y
      newMat = @tracker.translate deltaX, deltaY
      @svg.attr "transform", "matrix(" + newMat.a + "," + newMat.b + "," + newMat.c + "," + newMat.d + "," + newMat.e + "," + newMat.f + ")"
      
  zoom: (clicks) ->
    oldTransform = @tracker.getTransform()
    pt = @tracker.transformedPoint(@lastZoom.x, @lastZoom.y)
    factor = Math.pow(1.1, clicks)
    @tracker.scale factor, factor
    newMat = @tracker.getTransform()
    if newMat.a<0.7 or newMat.a>1.8 
      #min max zoomlevel
      @tracker.setTransformMat(oldTransform)
      return false
    center = @findCenter(newMat.a, newMat.d, newMat.e, newMat.f)
    boundness = @imgBoundWDrag(center, clicks, clicks, true)
    if boundness.x and boundness.y
      @svg.attr "transform", "matrix(" + newMat.a + "," + newMat.b + "," + newMat.c + "," + newMat.d + "," + newMat.e + "," + newMat.f + ")"
      return true
    else
      @tracker.setTransformMat(oldTransform)
    false

  setZoomPan: (deltaX, deltaY, deltaZoom) ->
    @pan(deltaX, deltaY)
    @lastZoom.x = @canvas.width / 2
    @lastZoom.y = @canvas.height / 2
    @allTags.forEach (frame_arr, frame)=>
      frame_arr.forEach (tag, sub)=>
        pos = @summaryManager.updateSummary(frame,sub,false)
        window.triggerEvent({
          type:'tagMoving', 
          message:{ position:pos}
        })
    return @zoom deltaZoom, deltaX, deltaY

  getGraphicSvgElem:(parent)->
    parent.select('.tag')

  moveElement: (elem, movePixel)->
    elem.tag.moveAll movePixel #update points stored in tag
    pos = @summaryManager.updateSummary(elem.frame, elem.sub,false)
    @drawInSvg(@getGraphicSvgElem(elem.graphicTag), elem.tag)

    window.triggerEvent({
      type:'tagMoving', 
      message:{ position:pos}
    }) #notify moving tag
    
  unsetDraggable: (elem)->
    return if(elem.frame==@highlighted.frame and elem.sub==@highlighted.sub)
    severe_color = colorSelector(elem.tag.property.prop_severity)
    @updateStrokeColor(elem.frame, elem.sub, severe_color)

  setDraggable: (elem)->
    @updateStrokeColor(elem.frame, elem.sub, colorSelector('highlight'))

  setFilled: (elem)->
    pathElem = @getGraphicSvgElem(elem.graphicTag)
    return if pathElem is null or pathElem.empty() 
    #toggle fill
    oldFill = pathElem.style('fill')
    newFill = ''
    if oldFill!="none"
      newFill = "none"
      elem.tag.filled = false
    else
      newFill = colorSelector(elem.tag.property.prop_severity)
      elem.tag.filled = true
    pathElem.style('fill', newFill)

    window.triggerEvent({
      type:'tagFill',
      message:{ frame:elem.frame, sub:elem.sub, filled:elem.tag.filled}
      })

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

    @summaryManager.setupSummary(tagFrameGroup, sub)
    elem = null
    switch type
      when 'hand'
        #path tag
        elem = tagGroup.append("path")
          .attr("fill", 'none')
      when 'region'
        elem = tagGroup.append("rect")
          .attr('fill', strokeColor)

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
  

