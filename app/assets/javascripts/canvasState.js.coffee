class window.CanvasState

  constructor: (canvas, options) ->
    
    # fixes mouse co-ordinate problems when theres a border or padding
    # see getMouse for more detail
    if document.defaultView and document.defaultView.getComputedStyle
      stylePaddingLeft = parseInt(document.defaultView.getComputedStyle(canvas, null)["paddingLeft"], 10) or 0
      stylePaddingTop = parseInt(document.defaultView.getComputedStyle(canvas, null)["paddingTop"], 10) or 0
      styleBorderLeft = parseInt(document.defaultView.getComputedStyle(canvas, null)["borderLeftWidth"], 10) or 0
      styleBorderTop = parseInt(document.defaultView.getComputedStyle(canvas, null)["borderTopWidth"], 10) or 0
    @line = d3.svg.line().x((d) ->
      d.x
    ).y((d) ->
      d.y
    ).interpolate("linear")
    
    #this.allTags=[];//all the tags on canvas
    @allTags = [] #graphic tags
    @allTagData = [] #annotated tags
    
    #for drawing
    @dragging = false # Keep track of when we are dragging
    @mouseDownForFreeHand = false
    
    #for resizing
    # Holds the 8 tiny boxes that will be our selection handles
    # the selection handles will bse in this order:
    # 0  1  2
    # 3     4
    # 5  6  7
    @selectionHandles = []
    
    # the current selected object.
    @regionSelection = null
    @handSelection = null
    @dragoffx = 0
    @dragoffy = 0
    @strokeWidth = 3
    
    #recording states
    @tagCloud = -1
    @highlightTagCloud = -1
    @highlightTagSub = -1
    @recording = false
    
    #SETS up using options
    @bigBro = options.bigBro
    @gender = (if options.bigBro then options.bigBro.currentGender else "male")
    @cur_view_side = (if options.bigBro then options.bigBro.currentView else 0)
    @mode = (if options.mode then options.mode else "zoom")
    @imageLoader = options.bigBro.ImageLoader
    @lastX = canvas.width / 2
    @lastY = canvas.height / 2
    
    # Zoom related variables
    @canvas = document.getElementById("canvasDiv")
    @cur_view_side = 0
    
    #d3.select("#canvasDiv")
    #  .attr("onmouseover", "alert('x')");
    
    #DEBUG
    
    # registering mouse events 
    myState = this
    canvasDivW = 500
    canvasDivH = 730
    @svg = d3.select("#canvasDiv").append("svg")
      .attr("width", canvasDivW).attr("height", canvasDivH)
    @startRecordingNewMsg()
  
  #
  #  var markerDef = this.svg.append("defs");
  #  markerDef.append("marker")
  #      .attr("id", "numb_pattern")
  #      .attr("viewBox", "0 0 5 5")
  #      .attr("refX", 1)
  #      .attr("refY", 1)
  #      .attr("markerWidth", 3)
  #      .attr("markerHeight", 3)
  #    .append("image")
  #      .attr("patternUnits", "objectBoundingBox")
  #      .attr("xlink:href", this.imageLoader.getPainPatternImageSrc("Numb", 1))
  #      .attr("x", 0)
  #      .attr("y", 0)
  #      .attr("width", 3)
  #      .attr("height", 3);
  #  markerDef.append("marker")
  #          .attr("id", "dull_pattern")
  #          .attr("viewBox", "0 0 5 5")
  #          .attr("refX", 1)
  #          .attr("refY", 3)
  #          .attr("markerWidth", 3)
  #          .attr("markerHeight", 3)
  #        .append("image")
  #          .attr("patternUnits", "objectBoundingBox")
  #          .attr("xlink:href", this.imageLoader.getPainPatternImageSrc("Dull", 1))
  #          .attr("x", 0)
  #          .attr("y", 0)
  #          .attr("width", 3)
  #          .attr("height", 3);
  #  markerDef.append("marker")
  #          .attr("id", "sharp_pattern")
  #          .attr("viewBox", "0 0 5 5")
  #          .attr("refX", 1)
  #          .attr("refY", 3)
  #          .attr("markerWidth", 3)
  #          .attr("markerHeight", 3)
  #        .append("image")
  #          .attr("patternUnits", "objectBoundingBox")
  #          .attr("xlink:href", this.imageLoader.getPainPatternImageSrc("Sharp", 1))
  #          .attr("x", 0)
  #          .attr("y", 0)
  #          .attr("width", 3)
  #          .attr("height", 3);     
  #  

    #TODO brush stuff
    @strokeWidthGuider = @svg.append("path").attr("id", "strokeWidthGuider").attr("d", "M100,20L110,20L120,20L130,20L140,20").style("stroke-width", @strokeWidth).style("fill", "none").style("stroke", colorSelector(2)).style("opacity", 0)
    @strokeWidthGuider.style("display", 'none')

    @svg = @svg.append("g")
      .on("mouseup", getEventHandler("mouseup", myState))
      .on("mousewheel", getEventHandler("mousewheel", myState))
      .on("mousedown", getEventHandler("mousedown", myState))
      .on("mousemove", getEventHandler("mousemove", myState))
   
    @srcImg = @svg.append("image").attr("x", (canvasDivW - 300) / 2).attr("y", (canvasDivH - 700) / 2).attr("width", 300).attr("height", 700).attr("xlink:href", @imageLoader.getBodyImageSrc(@gender, @cur_view_side))
    @tracker = {}
    trackSVGTransforms @tracker, document.createElementNS("http://www.w3.org/2000/svg", "svg")
    

    #fixes a problem where double clicking causes text to get selected on the canvas
    
    # double click for making new regionTags
    #  canvas.addEventListener('dblclick', function(e) {
    #    var mouse = myState.getMouse(e);
    #    myState.regionSelection=new RegionTagCanvasElem(mouse.x - 10, mouse.y - 10, 20, 20,
    # 'rgba(0,255,0,.6)');
    #    myState.addRegionTagCanvasElem(myState.regionSelection);
    #    myState.isResizeDrag=true;
    #  }, true);
    
    # For Resize 
    
    # set up the selection handle boxes
    ###
    i = 0

    while i < 8
      rect = new RegionTagCanvasElem
      @selectionHandles.push rect
      i++
    ###

  setCallbacks: (cb) ->
    @selectCallback = cb.selectCallback  if cb

  setView: (view) ->
    @cur_view_side = view
    @srcImg.attr "xlink:href", @imageLoader.getBodyImageSrc(@gender, @cur_view_side)
    highlight = "HIGHLIGHTTAG"
    highlight = "tag_" + @highlightTagCloud  if @hasHighlightedSelection()
    @svg.selectAll("g").style "opacity", (d) ->
      if @classList.contains("side_" + view)
        (if @classList.contains(highlight) then 1.0 else 0.3)
      else if @id is "strokeWidthGuider"
        (if @classList.contains(highlight) then 1.0 else 0.3)
      else
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

  startRecordingNewMsg: ->
    @tagCloud += 1
    @allTags.push []
    @recording = true

  stopRecordingNewMsg: ->
    grouper = @svg.select(".side_" + @cur_view_side + ".tag_" + @tagCloud)
    grouper.style "opacity", 0.3  unless grouper.empty()
    @recording = false

  getCurrentTagCloudIndex: ()->
    @tagCloud

  markHistoryDataForCurrent: ()->
    data = {}
    data.gender = @gender
    data.cur_view_side = @cur_view_side
    data.handSelections = @allTags[@tagCloud]
    data.index = @tagCloud
    @startRecordingNewMsg()
    return data

  setStrokeWidth: (width) ->
    @strokeWidth = width
    @strokeWidthGuider.style "stroke-width", @strokeWidth

  flush = ->
    @allTags = []

  downloadTagProperties: () ->
    if @hasHighlightedSelection()
      subIndex = Math.max(@highlightTagSub, 0)
      return @allTags[@highlightTagCloud][subIndex].getProperties()
    return {}
    
  uploadTagProperties: (properties) ->
    if @hasHighlightedSelection()
      cloudElems = @allTags[@highlightTagCloud]
      sIndex = 0
      fIndex = cloudElems.length
      if @highlightTagSub>0
        sIndex = @highlightTagSub
        fIndex = sIndex + 1
      i = sIndex

      while i < fIndex
        tagElem = cloudElems[i]
        tagElem.saveProperties(properties)
        i++

  deHighlightCloud: ->
    bbox = @svg.select("#boundingBox")
    bbox.style "opacity", 0  unless bbox.empty()    
    grouper = @svg.select(".side_" + @cur_view_side + ".tag_" + @highlightTagCloud)
    grouper.style "opacity", 0.3  unless grouper.empty()
    @highlightTagCloud = -1
    @highlightTagSub = -1
    @selectCallback false, null

  highlightCloud: (index, subIndex) ->
    index = @allTags.length - 1  if index < 0
    cloudElems = @allTags[index]
    return  if not cloudElems or cloudElems.length < 1
    return  unless cloudElems[0].view is @cur_view_side
    @deHighlightCloud()

    @highlightTagCloud = index
    grouper = @svg.select(".side_" + @cur_view_side + ".tag_" + @highlightTagCloud)
    grouper.style "opacity", 0.7  unless grouper.empty()
    boundingBox =
      x: 1000
      y: 1000
      x2: 0
      y2: 0

    sIndex = 0
    fIndex = cloudElems.length
    if subIndex>=0
      @highlightTagSub = subIndex
      sIndex = subIndex
      fIndex = sIndex + 1
    i = sIndex

    while i < fIndex
      tagElem = cloudElems[i]
      boundingBox.x = tagElem.x  if tagElem.x < boundingBox.x
      boundingBox.y = tagElem.y  if tagElem.y < boundingBox.y
      boundingBox.x2 = tagElem.x + tagElem.w  if tagElem.x + tagElem.w > boundingBox.x2
      boundingBox.y2 = tagElem.y + tagElem.h if tagElem.y + tagElem.h > boundingBox.y2
      i++
    bbox = @svg.select("#boundingBox")
    bbox = @svg.append("rect").attr("id", "boundingBox")  if bbox.empty()
    bbox.attr("x", boundingBox.x).attr("y", boundingBox.y)
      .attr("width", boundingBox.x2- boundingBox.x)
      .attr("height", boundingBox.y2 - boundingBox.y)
      .style("fill", "#7BCCC4").style("stroke", "#43A2CA").style("stroke-width", 3).style("fill-opacity", "0.05").style "opacity", 1.0
    
    @selectCallback true, bbox

  highlightAllTags: (index) ->
    @regionSelection = null  unless index is -1
    if index is -2
      @highlightTagCloud = @allTags.length - 1
    else
      @highlightTagCloud = index

  moveHighlightBox: (mx, my) ->
    bbox = @svg.select("#boundingBox")
    if bbox
      newX = parseInt(bbox.attr("x"))+mx
      newY = parseInt(bbox.attr("y"))+my
      bbox.attr("x", newX).attr("y", newY)

  setMode: (modeName) ->
    @mode = modeName
    if @mode is "zoom"
      @canvas.style.cursor = "url('/assets/dragHand.png'), auto"
      @strokeWidthGuider.style "opacity", 0
    else if @mode is "draw"
      @canvas.style.cursor = "url('/assets/drawHand.png'), auto"
      @strokeWidthGuider.style "opacity", 1.0

  updateGraphics: (index, severity, type) ->
    grouper = @svg.select(".side_" + @cur_view_side + ".tag_" + index)
    col = colorSelector(severity)
    grouper.selectAll("path").style "stroke", col  unless grouper.empty()
    col

  hasHighlightedSelection: ->
    @highlightTagCloud >= 0

  setZoomPan: (deltaX, deltaY, deltaZoom) ->
    @tracker.translate deltaX, deltaY
    @lastX = @canvas.width / 2
    @lastY = @canvas.height / 2
    zoom deltaZoom, this

  elementUnderneath: (pt) ->
    i = 0
    while i < this.allTags.length
      curTagL = this.allTags[i]
      l = curTagL.length
      j = 0

      while j < l
        if curTagL[j].view is this.cur_view_side and curTagL[j].contains(pt.x, pt.y)
          this.regionSelection = curTagL[j]
          grouper = this.svg.select(".tag_" + i)
          this.dragElem = grouper.select(":nth-child(" + (j + 1) + ")")
          return this.dragElem
        j++
      i++
    return null


CanvasZoomEventHandler =
  mousedown: (e, myState) ->
    e.preventDefault()
    mouse = myState.getMouse(e)
    globalPoint = myState.tracker.transformedPoint(mouse.x, mouse.y)
    if myState.dragElem
      myState.dragging = true
      myState.dragoffx = globalPoint.x
      myState.dragoffy = globalPoint.y
      #highlight the elem
      myState.highlightCloud myState.regionSelection.cloudIndex, myState.regionSelection.tagIndex

      return
    myState.regionSelection = null
    myState.lastX = e.offsetX or (e.pageX - myState.canvas.offsetLeft)
    myState.lastY = e.offsetY or (e.pageY - myState.canvas.offsetTop)
    myState.dragStart = myState.tracker.transformedPoint(myState.lastX, myState.lastY)

  mousemove: (e, myState) ->
    e.preventDefault()
    myState.lastX = e.offsetX or (e.pageX - canvas.offsetLeft)
    myState.lastY = e.offsetY or (e.pageY - canvas.offsetTop)
    mouse = myState.getMouse(e)
    globalPoint = myState.tracker.transformedPoint(mouse.x, mouse.y)
    if myState.dragStart
      #moving around background image
      pt = myState.tracker.transformedPoint(myState.lastX, myState.lastY)
      newMat = myState.tracker.translate(pt.x - myState.dragStart.x, pt.y - myState.dragStart.y)
      myState.svg.attr "transform", "matrix(" + newMat.a + "," + newMat.b + "," + newMat.c + "," + newMat.d + "," + newMat.e + "," + newMat.f + ")"
    else if myState.dragging
      #moving around the element
      mx = globalPoint.x - myState.dragoffx
      my = globalPoint.y - myState.dragoffy
      myState.regionSelection.moveAll mx,my 
      myState.moveHighlightBox mx,my

      myState.dragoffx = globalPoint.x
      myState.dragoffy = globalPoint.y
      myState.dragElem.attr "d", myState.line(myState.regionSelection.points)
    else
      elemUnder = myState.elementUnderneath(globalPoint)
      if elemUnder is null
        myState.regionSelection = null
        if myState.dragElem
          myState.dragElem.style "stroke", colorSelector(2)
          myState.dragElem = null
      else
        myState.dragElem.style "stroke", "#FC9272"

  mouseup: (e, myState) ->
    myState.dragStart = null
    myState.dragging = false
    if myState.dragElem
      myState.dragElem.style "stroke", colorSelector(2)
      myState.dragElem = null

  mousewheel: (e, myState) ->
    delta = (if e.originalEvent.wheelDelta then e.originalEvent.wheelDelta / 40 else (if e.originalEvent.detail then e.originalEvent.detail else 0))
    zoom delta, myState  if delta
    e.preventDefault() and false

CanvasDrawEventHandler =
  mousedown: (e, myState) ->
    return  unless myState.recording
    myState.regionSelection = null
    e.preventDefault()
    mouse = myState.getMouse(e)
    myState.mouseDownForFreeHand = true
    myState.deHighlightCloud()

    #creating a new free hand tag
    myState.handSelection = new FreehandElem("#F89393", myState.cur_view_side)
    globalPoint = myState.tracker.transformedPoint(mouse.x, mouse.y)
    myState.handSelection.addPoint globalPoint.x, globalPoint.y

    #find out the cloud it belongs to
    tagCloudGroup = myState.tagCloud
    tagCloudGroup = myState.highlightTagCloud  if myState.hasHighlightedSelection()
    myState.handSelection.cloudIndex = tagCloudGroup
    myState.handSelection.tagIndex = myState.addFreehandElem(myState.handSelection, tagCloudGroup)
    grouper = myState.svg.select(".tag_" + tagCloudGroup)

    strokeColor = colorSelector(2)
    if grouper.empty()
      # create the group 
      grouper = myState.svg.append("svg:g")
        .attr("class", "side_" + myState.cur_view_side + " tag_" + tagCloudGroup)
        .attr("opacity", 0.7)
    else
      # append to existing group
      path = grouper.select("path")
      strokeColor = path.style("stroke")  unless path.empty()
    
    myState.curElemG = grouper.append("svg:path")
      .style("stroke-width", myState.strokeWidth)
      .style("fill", "none").style("stroke", strokeColor)
      .attr("d", myState.line(myState.handSelection.points))

  mousemove: (e, myState) ->
    mouse = myState.getMouse(e)
    e.preventDefault()
    if myState.mouseDownForFreeHand
      globalPoint = myState.tracker.transformedPoint(mouse.x, mouse.y)
      myState.handSelection.addPoint globalPoint.x, globalPoint.y
      myState.curElemG.attr "d", myState.line(myState.handSelection.points)
      return

  mouseup: (e, myState) ->
    if myState.mouseDownForFreeHand
      myState.mouseDownForFreeHand = false
      unless myState.handSelection.isValidElem()
        myState.undoLastDrawing()
      else
        # valid tagging done!
        myState.regionSelection = myState.handSelection
        myState.curElemG.attr "d", myState.line(myState.handSelection.points)
        #highlight cloud
        myState.highlightCloud myState.handSelection.cloudIndex, myState.handSelection.tagIndex
        
      return
    myState.dragging = false

  mousewheel: (e, myState) ->
    false

getEventHandler =  (name, myState) ->
  (e) ->
    if myState.mode is "draw"
      CanvasDrawEventHandler[name] d3.event, myState
    else CanvasZoomEventHandler[name] d3.event, myState  if myState.mode is "zoom"
    
trackSVGTransforms = (tracker, svg) ->
  xform = svg.createSVGMatrix()
  getTransform = tracker.getTransform
  tracker.getTransform = ->
    xform

  scale = 1
  scale = tracker.scale
  tracker.scale = (sx, sy) ->
    xform = xform.scaleNonUniform(sx, sy)
    xform

  rotate = tracker.rotate
  tracker.rotate = (radians) ->
    xform = xform.rotate(radians * 180 / Math.PI)
    xform

  translate = tracker.translate
  tracker.translate = (dx, dy) ->
    xform = xform.translate(dx, dy)
    xform

  transform = tracker.transform
  tracker.transform = (a, b, c, d, e, f) ->
    m2 = svg.createSVGMatrix()
    m2.a = a
    m2.b = b
    m2.c = c
    m2.d = d
    m2.e = e
    m2.f = f
    xform = xform.multiply(m2)
    xform

  setTransform = tracker.setTransform
  tracker.setTransform = (a, b, c, d, e, f) ->
    xform.a = a
    xform.b = b
    xform.c = c
    xform.d = d
    xform.e = e
    xform.f = f
    xform

  pt = svg.createSVGPoint()
  tracker.transformedPoint = (x, y) ->
    pt.x = x
    pt.y = y
    pt.matrixTransform xform.inverse()


colorSelector = (severity) ->
  if severity is 0
    "#FFF5F0"
  else if severity is 1
    "#FEE0D2"
  else if severity is 2
    "#04BE7F"
  else if severity is 3
    "#FC9272"
  else if severity is 4
    "#FB6A4A"
  else if severity is 5
    "#EF3B2C"
  else if severity is 6
    "#CB181D"
  else if severity is 7
    "#A50F15"
  else if severity is 8
    "#67000D"
  else "#67000D"  if severity is 9

zoom = (clicks, myState) ->
  pt = myState.tracker.transformedPoint(myState.lastX, myState.lastY)
  factor = Math.pow(1.1, clicks)
  myState.tracker.scale factor, factor
  newMat = myState.tracker.getTransform()
  myState.svg.attr "transform", "matrix(" + newMat.a + "," + newMat.b + "," + newMat.c + "," + newMat.d + "," + newMat.e + "," + newMat.f + ")"