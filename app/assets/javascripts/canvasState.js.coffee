class window.CanvasState

  constructor: (cv, options) ->
    
    @line = d3.svg.line().x((d) ->
      d.x
    ).y((d) ->
      d.y
    ).interpolate("linear")

    
    @allTags = [] #all freehand elems

    #for drawing
    @dragging = false # Keep track of when we are dragging
    @mouseDownForFreeHand = false
    
    # the current selected object.
    @handSelection = null
    @dragOff={"x":0, "y":0}

    #drawing parameters
    @strokeWidth = 3
    
    #recording states
    @tagCloud = -1
    @highlightTagCloud = -1
    @highlightTagSub = -1
    @recording = false
    
    #SETS up using options
    @gender = (if options then options.currentGender else "male")
    @cur_view_side = (if options then options.currentView else 0)
    @mode = (if options.mode then options.mode else "zoom")
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
      .on("mouseup", cv.getEventHandler("mouseup"))
      .on("mousewheel", cv.getEventHandler("mousewheel"))
      .on("mousedown", cv.getEventHandler("mousedown"))
      .on("mousemove", cv.getEventHandler("mousemove"))
   
    # add image
    imgRatio = 3/7
    imgH = options.height - options.margin*2

    @srcImg = @svg.append("image").attr("x", (options.width - imgH*imgRatio) / 2)
      .attr("y", options.margin)
      .attr("width", imgH*imgRatio)
      .attr("height", imgH)
      .attr("xlink:href", @imageLoader.getBodyImageSrc(@gender, @cur_view_side))

  setView: (view) ->
    @cur_view_side = view
    @srcImg.attr "xlink:href", @imageLoader.getBodyImageSrc(@gender, @cur_view_side)
    @svg.selectAll("g").style "opacity", (d) ->
      if @classList.contains("side_" + view) 
        if @classList.contains("tag_"+@tagCloud)
          return 1.0
        else 
          return 0.3
      0
    @deHighlightCloud()

  getView: ->
    @cur_view_side

  addRegionTagCanvasElem: (elem) ->
    @allTags[@tagCloud].allTags.push elem
    @needRedraw = true

  addFreehandElem: (elem, cloud) ->
    list = @allTags[cloud]
    list.push elem
    @allTags[cloud].length - 1

  highlightNextUndo: ->
    if @allTags[@tagCloud]
      curLen = @allTags[@tagCloud].length
      if curLen > 0
        grouper = @svg.select(".tag_" + @tagCloud)
        toRemove = grouper.select(":last-child")
        toRemove.style "stroke", "#FC9272"  unless toRemove.empty()

  deHighlightNextUndo: ->
    curLen = @allTags[@tagCloud].length
    if curLen > 0
      grouper = @svg.select(".tag_" + @tagCloud)
      toRemove = grouper.select(":last-child")
      toRemove.style "stroke", colorSelector(2)  unless toRemove.empty()

  undoLastDrawing: ->
    curLen = @allTags[@tagCloud].length
    if curLen > 0
      @allTags[@tagCloud].pop()
      grouper = @svg.select(".tag_" + @tagCloud)
      grouper.select(":last-child").remove()  unless grouper.empty()

  getMouse: (e) ->
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
    x: mx
    y: my

  submitAll: (gender) ->
    if @allTagData.length is 0
      alert "please express your symptoms!"
      return
    self = this
    $.ajax(
      type: "GET"
      url: "postTag"
      data:
        tagData: JSON.stringify(self.allTagData)
    ).done (tagIdArr) ->
      self.submitGraphicTags JSON.parse(tagIdArr)


  submitGraphicTags: (tagIdArr) ->
    self = this
    l = @allTags.length
    if l is 0
      self.submitComplete()
    else
      j = 0

      while j < l
        tags = @allTags[j]
        len = tags.length
        $.ajax(
          type: "POST"
          url: "postGraphicTag"
          data:
            tagId: tagIdArr[j]
            freeHand: JSON.stringify(tags)
        ).done (msg) ->
          self.submitComplete()  if j is l

        j++

  submitComplete: ->
    alert "complete"
    window.location = "/main/complete?user_id=" + @userID


  stopRecordingNewMsg: ->
    grouper = @svg.select(".side_" + @cur_view_side + ".tag_" + @tagCloud)
    @recording = false

  startRecordingNewMsg: ->
    @tagCloud += 1
    @allTags.push []
    @recording = true

  opaqueCurrent: ()->
    @svg.select(".tag_" + @tagCloud)
      .style("opacity", 0.3)
    $(window).trigger({
      type: "opaqueCurrent",
      message:@tagCloud
      })

  markHistoryDataForCurrent: ()->
    @opaqueCurrent()
    @startRecordingNewMsg()
    data = {}
    data.gender = @gender
    data.cur_view_side = @cur_view_side
    data.index = @tagCloud
    return data

  setStrokeWidth: (width) ->
    @strokeWidth = width

  flush = ->
    @allTags = []

  getTacProperties: () ->
    if @hasHighlightedSelection()
      subIndex = Math.max(@highlightTagSub, 0)
      return @allTags[@highlightTagCloud][subIndex].getProperties()
    return {}
    
  uploadTagProperties: (properties) ->
    if @hasHighlightedSelection()
      cloudElems = @allTags[@highlightTagCloud]
      sIndex = 0
      fIndex = cloudElems.length
      if @highlightTagSub>=0
        sIndex = @highlightTagSub
        fIndex = sIndex + 1
      i = sIndex

      while i < fIndex
        tagElem = cloudElems[i]
        tagElem.saveProperties(properties)
        i++

  #Highlights
  deHighlightCloud: ->
    bbox = @svg.select("#boundingBox")
    bbox.style "opacity", 0  unless bbox.empty()    
    grouper = @svg.select(".side_" + @cur_view_side + ".tag_" + @highlightTagCloud)

    index = @highlightTagCloud
    subIndex = @highlightTagSub
    if index>=0 and subIndex>=0
      $(window).trigger({
        type:'highlighted', 
        message:{highlight:false, data:{tagIdStr:"#{index}_#{subIndex}"}}
      })
    @highlightTagCloud = -1
    @highlightTagSub = -1

  getBoundingBox:(index, subIndex)->
    box =
      x: 1000
      y: 1000
      x2: 0
      y2: 0

    sIndex = 0
    fIndex = @allTags[index]
    if subIndex>=0
      @highlightTagSub = subIndex
      sIndex = subIndex
      fIndex = sIndex + 1
    i = sIndex

    cloudElems = @allTags[index]
    while i < fIndex
      tagElem = cloudElems[i]
      box.x = tagElem.x  if tagElem.x < box.x
      box.y = tagElem.y  if tagElem.y < box.y
      box.x2 = tagElem.x + tagElem.w  if tagElem.x + tagElem.w > box.x2
      box.y2 = tagElem.y + tagElem.h if tagElem.y + tagElem.h > box.y2
      i++
    box

  highlightCloud: (index, subIndex) ->
    index = @allTags.length - 1  if index < 0
    cloudElems = @allTags[index]
    return  if not cloudElems or cloudElems.length < 1
    return  unless cloudElems[0].view is @cur_view_side
    @deHighlightCloud()

    @highlightTagCloud = index
    grouper = @svg.select(".side_" + @cur_view_side + ".tag_" + @highlightTagCloud)
    grouper.style "opacity", 1.0  unless grouper.empty()
    boundingBox = @getBoundingBox(index, subIndex)
    bbox = @svg.select("#boundingBox")
    bbox = @svg.append("rect").attr("id", "boundingBox")  if bbox.empty()
    bbox.attr("x", boundingBox.x).attr("y", boundingBox.y)
      .attr("width", boundingBox.x2- boundingBox.x)
      .attr("height", boundingBox.y2 - boundingBox.y)
      .style("fill", "#7BCCC4").style("stroke", "#43A2CA")
      .style("stroke-width", 3)
      .style("fill-opacity", "0.05").style "opacity", 0.0
    
    
    $(window).trigger({
      type:'highlighted', 
      message:{highlight:true, box:bbox, 
      data:{tagIdStr:"#{index}_#{subIndex}", properties:@getTacProperties()}}
    })

  moveHighlightBox: (mx, my) ->
    bbox = @svg.select("#boundingBox")
    if bbox
      newX = parseInt(bbox.attr("x"))+mx
      newY = parseInt(bbox.attr("y"))+my
      bbox.attr("x", newX).attr("y", newY)
      if @highlightTagCloud>=0 and @highlightTagSub>=0
        $(window).trigger({
          type:'highlightBoxMove', 
          message:{ box:bbox, data:{tagIdStr:"#{@highlightTagCloud}_#{@highlightTagSub}"}}
        })

  setMode: (modeName) ->
    @mode = modeName
    if @mode is "zoom"
      @canvas.style.cursor = "default"
    else if @mode is "draw"
      @canvas.style.cursor = "url('/assets/drawHand.png'), auto"

  updateGraphics: (index, severity, type) ->
    grouper = @svg.select(".side_" + @cur_view_side + ".tag_" + index)
    col = colorSelector(severity)
    grouper.selectAll("path").style "stroke", col  unless grouper.empty()
    col

  hasHighlightedSelection: ->
    @highlightTagCloud >= 0

  setZoomPan: (deltaX, deltaY, deltaZoom) ->
    @tracker.translate deltaX, deltaY
    @lastZoom.x = @canvas.width / 2
    @lastZoom.y = @canvas.height / 2
    zoom deltaZoom, this

  elementUnderneath: (pt) ->
    i = 0
    while i < this.allTags.length
      curTagL = this.allTags[i]
      l = curTagL.length
      j = 0

      while j < l
        if curTagL[j].view is this.cur_view_side and curTagL[j].contains(pt.x, pt.y)
          this.handSelection = curTagL[j]
          grouper = this.svg.select(".tag_" + i)
          this.dragElem = grouper.select(":nth-child(" + (j + 1) + ")")
          return this.dragElem
        j++
      i++
    return null

  getGrouper: (tagCloudGroup)->
    grouper = @svg.select(".side_"+@cur_view_side+".tag_" + tagCloudGroup)
    if grouper.empty()
      # create the group 
      grouper = @svg.append("svg:g")
        .attr("class", "side_" + @cur_view_side + " tag_" + tagCloudGroup)
    grouper

  newTag: (grouper)->
    strokeColor = colorSelector(2)
    unless (path = grouper.select("path")).empty()
      strokeColor = path.style("stroke")

    grouper.append("svg:path")
      .style("stroke-width", @strokeWidth)
      .style("fill", "none").style("stroke", strokeColor)
      .attr("d", @line(@handSelection.points))

  createInSvg: (tagCloudGroup)->
    grouper = @getGrouper(tagCloudGroup)
    @curElem = @newTag(grouper)

  drawInSvg: ()->
    @curElem.attr "d", @line(@handSelection.points)

  getEventHandler: (name) ->
    cv = @
    (e) ->
      if cv.mode is "draw"
        CanvasDrawEventHandler[name] d3.event, cv
      else CanvasZoomEventHandler[name] d3.event, cv if cv.mode is "zoom"


CanvasZoomEventHandler =
  mousedown: (e, cv) ->
    e.preventDefault()
    mouse = cv.getMouse(e)
    globalPoint = cv.tracker.transformedPoint(mouse.x, mouse.y)
    if cv.dragElem
      cv.dragging = true
      cv.dragOff.x = globalPoint.x
      cv.dragOff.y = globalPoint.y
      #highlight the elem
      cv.highlightCloud cv.handSelection.cloudIndex, cv.handSelection.tagIndex

      return
    cv.handSelection = null
    cv.lastZoom.x = e.offsetX or (e.pageX - cv.canvas.offsetLeft)
    cv.lastZoom.y = e.offsetY or (e.pageY - cv.canvas.offsetTop)
    cv.dragStart = cv.tracker.transformedPoint(cv.lastZoom.x, cv.lastZoom.y)

  mousemove: (e, cv) ->
    e.preventDefault()
    cv.lastZoom.x = e.offsetX or (e.pageX - canvas.offsetLeft)
    cv.lastZoom.y = e.offsetY or (e.pageY - canvas.offsetTop)
    mouse = cv.getMouse(e)
    globalPoint = cv.tracker.transformedPoint(mouse.x, mouse.y)
    if cv.dragStart
      #moving around background image
      pt = cv.tracker.transformedPoint(cv.lastZoom.x, cv.lastZoom.y)
      newMat = cv.tracker.translate(pt.x - cv.dragStart.x, pt.y - cv.dragStart.y)
      cv.svg.attr "transform", "matrix(" + newMat.a + "," + newMat.b + "," + newMat.c + "," + newMat.d + "," + newMat.e + "," + newMat.f + ")"
    else if cv.dragging
      #moving around the element
      mx = globalPoint.x - cv.dragOff.x
      my = globalPoint.y - cv.dragOff.y
      cv.handSelection.moveAll mx,my 
      cv.moveHighlightBox mx,my

      cv.dragOff.x = globalPoint.x
      cv.dragOff.y = globalPoint.y
      cv.dragElem.attr "d", cv.line(cv.handSelection.points)
    else
      elemUnder = cv.elementUnderneath(globalPoint)
      if elemUnder is null
        cv.handSelection = null
        if cv.dragElem
          cv.dragElem.style "stroke", colorSelector(2)
          cv.dragElem = null
      else
        cv.dragElem.style "stroke", "#FC9272"

  mouseup: (e, cv) ->
    cv.dragStart = null
    cv.dragging = false
    if cv.dragElem
      cv.dragElem.style "stroke", colorSelector(2)
      cv.dragElem = null

  mousewheel: (e, cv) ->
    delta = (if e.originalEvent.wheelDelta then e.originalEvent.wheelDelta / 40 else (if e.originalEvent.detail then e.originalEvent.detail else 0))
    zoom delta, cv  if delta
    e.preventDefault() and false

CanvasDrawEventHandler =
  mousedown: (e, cv) ->
    return  unless cv.recording
    cv.handSelection = null
    e.preventDefault()
    mouse = cv.getMouse(e)
    cv.mouseDownForFreeHand = true
    cv.deHighlightCloud()

    #creating a new free hand tag
    cv.handSelection = new FreehandElem("#F89393", cv.cur_view_side)
    globalPoint = cv.tracker.transformedPoint(mouse.x, mouse.y)
    cv.handSelection.addPoint globalPoint.x, globalPoint.y

    #find out the cloud it belongs to
    tagCloudGroup = cv.tagCloud
    tagCloudGroup = cv.highlightTagCloud  if cv.hasHighlightedSelection()
    cv.handSelection.cloudIndex = tagCloudGroup
    cv.handSelection.tagIndex = cv.addFreehandElem(cv.handSelection, tagCloudGroup)

    #create the element in svg
    cv.createInSvg(tagCloudGroup)


  mousemove: (e, cv) ->
    mouse = cv.getMouse(e)
    e.preventDefault()
    if cv.mouseDownForFreeHand
      globalPoint = cv.tracker.transformedPoint(mouse.x, mouse.y)
      cv.handSelection.addPoint globalPoint.x, globalPoint.y
      cv.drawInSvg()
      return

  mouseup: (e, cv) ->
    if cv.mouseDownForFreeHand
      cv.mouseDownForFreeHand = false
      unless cv.handSelection.isValidElem()
        cv.undoLastDrawing()
      else
        cv.drawInSvg()
        $(window).trigger({
          type:'newTag', 
          message:{"points":cv.handSelection.points}
        })

        #highlight cloud
        cv.highlightCloud cv.handSelection.cloudIndex, cv.handSelection.tagIndex
        
      return
    cv.dragging = false

  mousewheel: (e, cv) ->
    false

    



