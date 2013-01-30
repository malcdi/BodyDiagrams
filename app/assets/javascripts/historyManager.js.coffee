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
        (d.x-_.bigOffLeft)/_.scaleFactor
      ).y((d) ->
        (d.y-_.bigOffTop)/_.scaleFactor
      ).interpolate("linear")
    @scaledBox = (box)->
      {
        x:(box.x-_.bigOffLeft)/_.scaleFactor
        y:(box.y-_.bigOffTop)/_.scaleFactor
        w:box.w/_.scaleFactor
        h:box.h/_.scaleFactor
      }

    @numHistory = 0
    @highlightedIndex = -1

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

  setView: (viewId)->
    if @getAllGraphicSvgElem(@svg).empty()
      @svg.select("image").attr "xlink:href", window.bigBro.ImageLoader.getBodyImageSrc(@gender, viewId)
    @cur_view_side = viewId

  findThumbnailTag: (frameIndex, subIndex)->
    svgGroup = @container.select("svg:nth-child(#{frameIndex+1})")
    return null if svgGroup.empty()
    d3.select @getAllGraphicSvgElem(svgGroup)[0][subIndex]

  moveThumbnailTag: (frameIndex, subIndex, dataPoints)->
    thumbTag = @findThumbnailTag(frameIndex, subIndex)
    return if thumbTag==null
    thumbTag.attr("d", @line(dataPoints))


  addNew: ()->
    window.bigBro.cvState.startNewFrame() #notify canvas state
    data = window.bigBro.cvState.getCurrentFrameData() 
    _=@
    @svg = @container.insert("li", "#addNew").append("svg")
      .attr('width', this.width)
      .attr('height', this.height)
      .attr('class', 'thumbnail')
      .attr('frame_id', data.index)
      .call (selection)-> 
        eventManager.setup('frame', selection, _)
        
    @cur_view_side = data.cur_view_side
    @gender = data.gender

    @svg = @svg.append("g")
      .attr("class", "thumbnail")
      .attr("view_side", @cur_view_side)
      .attr("transform", "translate("+@offLeft+","+@offTop+")")

    @svg.append("image")
      .attr("width", this.imgW).attr("height", this.imgH)
      .attr("xlink:href", window.bigBro.ImageLoader.getBodyImageSrc(@gender, @cur_view_side))
    
    @numHistory += 1
    @highlightWindow(data.index)

  addNewTag: (msg)->
    if +@svg.attr("view_side")!=+@cur_view_side
      @addNew()
    svgElem = null
    switch msg.type
      when 'hand'
        svgElem = @svg.append("path")
          .attr("d", @line(msg.data))
      when 'region'
        scaledBox = @scaledBox(msg.data)
        svgElem = @svg.append("rect")
          .attr('x', scaledBox.x)
          .attr('y', scaledBox.x)
          .attr('width', scaledBox.w)
          .attr('height', scaledBox.h)

    svgElem.style("stroke-width", 1)
      .style("fill", "none").style("stroke", colorSelector('default'))

  highlightWindow: (index)->
    historyW = @container.selectAll("svg")[0][index]
    if @highlightedIndex>=0
      highlighted = @container.selectAll("svg")[0][@highlightedIndex]
      d3.select(highlighted).attr('class', "thumbnail")
    d3.select(historyW).attr('class', "thumbnail highlighted")
    @highlightedIndex = index

  needsRecording: (index)->
    return index>=@numHistory

