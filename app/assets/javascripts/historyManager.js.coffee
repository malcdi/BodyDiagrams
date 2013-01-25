class window.HistoryManager
  imgW: 75
  imgH: 175
  width: 125
  height: 182.5
  scale: 4

  constructor:(parent, @bigBro)->
    @container=d3.select(parent)
    @width = 125
    @height = window.innerHeight-@bigBro.height
    @imgRatio = 3/7
    @imgH = @height
    @imgW = @imgH*@imgRatio 
    @offLeft = (@width - @imgW) / 2
    @offTop = 0

    @bigOffLeft = parseInt(@bigBro.cvState.srcImg.attr("x"))
    @bigOffTop = parseInt(@bigBro.cvState.srcImg.attr("y"))
    _ = this

    @line = d3.svg.line().x((d) ->
        (d.x-_.bigOffLeft)/4
      ).y((d) ->
        (d.y-_.bigOffTop)/4
      ).interpolate("linear")

    @container.append('button')
      .attr('id', "addNew")
      .text("addNew")
      .on('click', ()->
        data = _.bigBro.cvState.markHistoryDataForCurrent()
        _.addNew(data)
        _.highlightWindow(data.index)
      )

    @numHistory = 0
    @highlightedIndex = -1
    $('#addNew').click()

  updateImgSize: ()->
    @offLeft = (@width - @height*@imgRatio) / 4
    @offTop = 0
    for i of @svgGroup
      offset = @getOffsetForIndex(i)
      @svgGroup[i]
        .attr("transform", "scale(0.5) translate("+offset.left+","+offset.top+")")

  getOffsetForIndex: (index)->
    offset = {}
    offset.left = @offLeft
    offset.top = @offTop
    switch index
      when 1
        offset.left = @offLeft*3 + @imgW
      when 2
        offset.top = @offTop*3 + @imgH
      when 3
        offset.left = @offLeft*3 + @imgW
        offset.top = @offTop*3 + @imgH
    return offset

  setView: (viewId)->
    if @svg.select('path').empty()
      @svgGroup[viewId] = @svgGroup[@cur_view_side]
      @svgGroup[@cur_view_side] = undefined
      @svgGroup[viewId].select("image").attr "xlink:href", @bigBro.ImageLoader.getBodyImageSrc(@gender, viewId)
    @cur_view_side = viewId

  addNew: (data)->
    @svg = @container.append("li").append("svg")
      .attr('width', this.width)
      .attr('height', this.height)
      .attr('class', 'thumbnail')

    @cur_view_side = data.cur_view_side
    @gender = data.gender

    @svgGroup = []
    @svgGroup[@cur_view_side] = @svg.append("g")
      .attr("class", "thumbnail")
      .attr("transform", "translate("+@offLeft+","+@offTop+")")

    @svgGroup[@cur_view_side].append("image")
      .attr("width", this.imgW).attr("height", this.imgH)
      .attr("xlink:href", @bigBro.ImageLoader.getBodyImageSrc(@gender, @cur_view_side))
    @numHistory += 1

  addNewTag: (dataPoints)->
    if @svgGroup[@cur_view_side] is undefined
      if @svgGroup.length is 1
        @updateImgSize()

      #compute offsets
      offset = @getOffsetForIndex(@cur_view_side)
      # append new
      @svgGroup[@cur_view_side] = @svg.append("g")
      .attr("class", "thumbnail")
      .attr("transform", "scale(0.5) translate("+offset.left+","+offset.top+")")
      @svgGroup[@cur_view_side].append("image")
        .attr("width", @imgW).attr("height", @imgH)
        .attr("xlink:href", @bigBro.ImageLoader.getBodyImageSrc(@gender, @cur_view_side))
    
    @svgGroup[@cur_view_side].append("svg:path")
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

