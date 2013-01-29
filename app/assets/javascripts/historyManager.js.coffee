class window.HistoryManager

  constructor:(parent, @bigBro)->
    @container=d3.select(parent)
    @width = 125
    @height = window.innerHeight-@bigBro.height-25
    @imgRatio = 3/7
    @imgH = @height
    @imgW = @imgH*@imgRatio 
    @offLeft = (@width - @imgW) / 2
    @offTop = 0
    @scaleFactor = @bigBro.cvState.srcImg.attr('height')/@height

    @bigOffLeft = parseInt(@bigBro.cvState.srcImg.attr("x"))
    @bigOffTop = parseInt(@bigBro.cvState.srcImg.attr("y"))
    @oldClassVar =""
    _ = this

    @line = d3.svg.line().x((d) ->
        (d.x-_.bigOffLeft)/_.scaleFactor
      ).y((d) ->
        (d.y-_.bigOffTop)/_.scaleFactor
      ).interpolate("linear")

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
        .on('click', ()->
          _.addNew()
        )
        .on('mouseover',()->
          d3.select(this).attr('class', "#{buttonClass} mouseover")
        )
        .on('mouseout',()->
          d3.select(this).attr('class', buttonClass)
        )
    buttonSVG.append('text')
          .attr('x', 25)
          .attr('y', 100)
          .text("click here to start")
    buttonSVG.append('text')
          .attr('x', 25)
          .attr('y', 130)
          .text("with a new frame")
      
    @addNew()

  setView: (viewId)->
    if @svg.select('path').empty()
      @svg.select("image").attr "xlink:href", @bigBro.ImageLoader.getBodyImageSrc(@gender, viewId)
    @cur_view_side = viewId
    console.log @cur_view_side

  findThumbnailTag: (frameIndex, subIndex)->
    svgGroup = @container.select("svg:nth-child(#{frameIndex+1})")
    return null if svgGroup.empty()
    svgGroup.select("path:nth-child(#{subIndex+2})")

  moveThumbnailTag: (frameIndex, subIndex, dataPoints)->
    thumbTag = @findThumbnailTag(frameIndex, subIndex)
    return if thumbTag==null
    thumbTag.attr("d", @line(dataPoints))


  addNew: ()->
    data = @bigBro.cvState.startNewFrame() #notify canvas state
    _=@
    @svg = @container.insert("li", "#addNew").append("svg")
      .attr('width', this.width)
      .attr('height', this.height)
      .attr('class', 'thumbnail')
      .attr('frame_id', data.index)
      .on('mouseover',()->
        this.oldClass = d3.select(this).attr("class")
        d3.select(this).attr('class', "#{this.oldClass} mouseover")
      )
      .on('mouseout',()->
        d3.select(this).attr('class', this.oldClass)
      )
      .on('click',()->
        d3Elem = d3.select(this)
        _.container.select("svg.highlighted").attr('class', "thumbnail")
        this.oldClass = "highlighted thumbnail"
        d3Elem.attr('class', this.oldClass)
        $(window).trigger(
          {type:'frameChanged', message: d3Elem.attr('frame_id')}
        )
      )

    @cur_view_side = data.cur_view_side
    @gender = data.gender

    @svg = @svg.append("g")
      .attr("class", "thumbnail")
      .attr("view_side", @cur_view_side)
      .attr("transform", "translate("+@offLeft+","+@offTop+")")

    @svg.append("image")
      .attr("width", this.imgW).attr("height", this.imgH)
      .attr("xlink:href", @bigBro.ImageLoader.getBodyImageSrc(@gender, @cur_view_side))
    
    @numHistory += 1
    @highlightWindow(data.index)

  addNewTag: (dataPoints)->
    if +@svg.attr("view_side")!=+@cur_view_side
      @addNew()

    @svg.append("svg:path")
      .style("stroke-width", 1)
      .style("fill", "none").style("stroke", colorSelector(2))
      .attr("d", @line(dataPoints))

  highlightWindow: (index)->
    historyW = @container.selectAll("svg")[0][index]
    if @highlightedIndex>=0
      highlighted = @container.selectAll("svg")[0][@highlightedIndex]
      d3.select(highlighted).attr('class', "thumbnail")
    d3.select(historyW).attr('class', "thumbnail highlighted")
    @highlightedIndex = index

  needsRecording: (index)->
    return index>=@numHistory

