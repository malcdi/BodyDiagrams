class window.HistoryManager

  constructor:(parent)->
    @container=d3.select(parent)
    @width = 125
    @height = window.innerHeight-window.bigBro.height-25
    @imgRatio = 3/7
    @imgH = @height
    @imgW = @imgH*@imgRatio 
    @offLeft = (@width - @imgW) / 2
    @offTop = 0
    @scaleFactor = window.bigBro.cvState.srcImg.attr('height')/@height

    @bigOffLeft = parseInt(window.bigBro.cvState.srcImg.attr("x"))
    @bigOffTop = parseInt(window.bigBro.cvState.srcImg.attr("y"))
    @oldClassVar =""
    _ = this

    @line = d3.svg.line().x((d) ->
        (d.x-_.bigOffLeft)/_.scaleFactor + _.offLeft
      ).y((d) ->
        (d.y-_.bigOffTop)/_.scaleFactor + _.offTop
      ).interpolate("linear")
    @scaledBox = (box)->
      {
        x:(box.x-_.bigOffLeft)/_.scaleFactor + _.offLeft
        y:(box.y-_.bigOffTop)/_.scaleFactor + _.offTop
        w:box.w/_.scaleFactor
        h:box.h/_.scaleFactor
      }

    @curHistory = -1

    #button
    buttonClass = 'thumbnail button'
    buttonSVG = @container.append("li")
      .attr('id', "addNew")
      .append("svg")
        .attr('width', @width+"px")
        .attr('height', @height+"px")
        .attr('class', buttonClass)
        .call (selection)-> 
          eventManager.setup('newFrameButton', selection, _, buttonClass)


    buttonSVG.append('text')
          .attr('x', 25)
          .attr('y', 100)
          .text("click here to start")
    buttonSVG.append('text')
          .attr('x', 25)
          .attr('y', 130)
          .text("with a new frame")
      
    @addNew()

  getAllGraphicSvgElem:(parent)->
    parent.selectAll('path,rect')

  getSVGForFrameId:(frame)->
    @container.select("svg[frame_id='#{frame}']")

  setView: (viewId)->
    svg = @getSVGForFrameId(@curHistory)
    svg.attr("view_side", viewId)
      .select("image").attr("xlink:href", window.bigBro.ImageLoader.getBodyImageSrc(@gender, viewId))
        
    @cur_view_side = viewId

  findThumbnailTag: (frame, sub)->
    svgGroup = @getSVGForFrameId(frame)
    return null if svgGroup.empty()
    d3.select @getAllGraphicSvgElem(svgGroup)[0][sub]

  moveThumbnailTag: (frame, sub, type, data)->
    thumbTag = @findThumbnailTag(frame, sub)
    return if thumbTag==null
    switch type
      when 'hand'
        thumbTag.attr("d", @line(data))
      when 'region'
        scaledBox = @scaledBox(data)
        thumbTag.attr('x', scaledBox.x)
          .attr('y', scaledBox.y)
          .attr('width', scaledBox.w)
          .attr('height', scaledBox.h)


  addNew: ()->
    window.bigBro.cvState.startNewFrame() #notify canvas state
    data = window.bigBro.cvState.getCurrentFrameData() 
    _=@
    svg = @container.insert("li", "#addNew").append("svg")
      .attr('width', this.width)
      .attr('height', this.height)
      .attr('class', 'thumbnail')
      .attr('frame_id', data.index)
      .attr("view_side", data.cur_view_side)
      .call (selection)-> 
        eventManager.setup('frame', selection, _)
        
    @cur_view_side = data.cur_view_side
    @gender = data.gender

    svg = svg.append("g")
      .attr("class", "thumbnail")
      .attr("transform", "translate("+@offLeft+","+@offTop+")")

    svg.append("image")
      .attr("width", this.imgW).attr("height", this.imgH)
      .attr("xlink:href", window.bigBro.ImageLoader.getBodyImageSrc(@gender, @cur_view_side))
    
    @highlightWindow(data.index)
    @curHistory = data.index

  deleteTag:(tag)->
    svg = @getSVGForFrameId(@curHistory)
    thumbTag = @findThumbnailTag(tag.frame, tag.sub)
    return if thumbTag==null
    thumbTag.remove()

  addNewTag: (msg)->
    svg = @getSVGForFrameId(@curHistory)
    if +svg.attr("view_side")!=+@cur_view_side
      @addNew()
      window.triggerEvent({
        type:'moveTagToNewFrame', 
        message:{frame:msg.frame, sub:msg.sub, newFrame:@curHistory}
      })

    svg = @getSVGForFrameId(@curHistory)
    svgElem = null
    switch msg.type
      when 'hand'
        svgElem = svg.append("path")
          .attr("d", @line(msg.data))
      when 'region'
        scaledBox = @scaledBox(msg.data)
        svgElem = svg.append("rect")
          .attr('x', scaledBox.x)
          .attr('y', scaledBox.y)
          .attr('width', scaledBox.w)
          .attr('height', scaledBox.h)

    svgElem.style("stroke-width", 1)
      .style("fill", "none").style("stroke", colorSelector('default'))

  highlightWindow: (index)->
    historyW = @container.selectAll("svg")[0][index]
    if @curHistory>=0
      highlighted = @container.selectAll("svg")[0][@curHistory]
      d3.select(highlighted).attr('class', "thumbnail")
    d3.select(historyW).attr('class', "thumbnail highlighted")
    @curHistory = index

