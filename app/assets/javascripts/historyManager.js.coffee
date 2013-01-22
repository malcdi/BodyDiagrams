class window.HistoryManager
  imgW: 75
  imgH: 175
  width: 125
  height: 182.5
  scale: 4


  constructor:(parent, @bigBro)->
    @container=d3.select(parent)
    @offLeft = (this.width - this.imgW) / 2
    @offTop = (this.height - this.imgH) / 2
    @bigOffLeft = parseInt(@bigBro.cvState.srcImg.attr("x"))
    @bigOffTop = parseInt(@bigBro.cvState.srcImg.attr("y"))
    _ = this
    @line = d3.svg.line().x((d) ->
        (d.x-_.bigOffLeft)/4+_.offLeft
      ).y((d) ->
        (d.y-_.bigOffTop)/4+_.offTop
      ).interpolate("linear")
    @numHistory = 0
    @highlightedIndex = -1


  addNew: (data)->
    svg = @container.append("li").append("svg")
      .attr('width', this.width)
      .attr('height', this.height)
      .attr('class', 'thumbnail')

    svg.append("image")
      .attr("x", @offLeft).attr("y", @offTop)
      .attr("width", this.imgW).attr("height", this.imgH)
      .attr("xlink:href", @bigBro.ImageLoader.getBodyImageSrc(data.gender, data.cur_view_side))

    for freeHandElem in data.handSelections
      svg.append("svg:path")
        .style("stroke-width", 1)
        .style("fill", "none").style("stroke", "#04BE7F")
        .attr("d", @line(freeHandElem.points))
    @numHistory += 1

  highlightWindow: (index)->
    historyW = @container.selectAll("svg")[0][index]
    if @highlightedIndex>=0
      highlighted = @container.selectAll("svg")[0][@highlightedIndex]
      d3.select(highlighted).attr('class', "thumbnail")
    d3.select(historyW).attr('class', "thumbnail highlighted")
    @highlightedIndex = index

  needsRecording: (index)->
    return index>=@numHistory

