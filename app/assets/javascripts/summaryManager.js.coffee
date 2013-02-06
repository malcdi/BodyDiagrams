class window.SummaryManager
  constructor:(@canvasState, @summary_contents, @right_border, @left_border)->
    @activated = window.bigBro.activatedProp
    @summary_line_container = d3.select("#canvasDiv").select("svg").append('g')
    @canvas_width = +@canvasState.srcImg.attr('width')
    
  textBoxHeight = 20
  textBoxWidth = 150
  iconHeight = 25
  smallIconHeight = 20
  boxMargin = 5

  setupSummary: (frame, sub)->
    _ = this
    #line
    @summary_line_container.append('line')
      .attr('class', 'summary_link disabled')
      .attr('frame', frame)
      .attr('sub', sub)
      .style('stroke-width', '1px')
      .style('stroke', 'steelblue')

    summaryContent = @summary_contents.append('div')
      .attr('class', 'summary_content disabled')
      .attr('frame', frame)
      .attr('sub', sub)
      .call((selection)->
        window.eventManager.setup('summary', selection, _)
      )
      
    if @activated.prop_severity
      summaryContent.append('img')
        .attr('class', 'prop_severity')
        .style('height', iconHeight+"px")
        .style('width', (iconHeight)+"px")
        .style('left', (textBoxWidth-iconHeight)+"px")
    if @activated.prop_posture
      summaryContent.append('div')
        .attr('class', 'prop_posture')
        .attr('top', (iconHeight-smallIconHeight)+"px")
    if @activated.prop_annotation
      summaryContent.append('textarea')
        .attr('class', 'prop_annotation')
        .attr('top', (iconHeight+'px'))

  updateSummaryDisplay: (frame)->
    summaryItems = @getSummary()
    console.log 'update'
    linkItems = @getLink()

    summaryItems.attr('class', (d)->
      if d3.select(this).attr("frame")==frame
        return 'summary_content'
      else
        return 'summary_content disabled'
      )

    linkItems.attr('class', (d)->
      if d3.select(this).attr("frame")==frame
        return 'summary_link'
      else
        return 'summary_link disabled'
      )

  updateSummary: (frame, sub, updateContent)->
    summaryItem = @getSummary(frame, sub)
    box = @canvasState.getBoundingBox(frame, sub)
    newPos = {left: box.x+box.w, top:box.y}
    
    if summaryItem
      center = box.x+box.w/2 
      y = box.y
      linkItem = @getLink(frame, sub)
      if (@canvas_width-center)<center
        x = box.x+box.w
        x_content = @right_border
        linkItem.attr('x1', x) #tag
          .attr('y1', y)
          .attr('x2', x_content) #summary
          .attr('y2', y)
      else
        x= 0
        x_content = @left_border-textBoxWidth-iconHeight
        linkItem.attr('x1', box.x) #tag
          .attr('y1', y)
          .attr('x2', 0) #summary
          .attr('y2', y)

      linkItem.attr('class', 'summary_link')

      summaryItem.attr('class', 'summary_content')
        .style('left',"#{x_content}px")
        .style('top', "#{y}px")
      console.log x_content
      newPos = {left: x_content, top:y-iconHeight}
      
    properties = @canvasState.allTags[frame][sub].getProperties()
    if updateContent then @updateSummaryContent(summaryItem, properties)
    return newPos
  
  closeSummary:(frame, sub)->
    summaryItem = @getSummary(frame, sub)
    if summaryItem
      summaryItem.attr('class', 'summary_content disabled')

    linkItem = @getLink(frame, sub)
    if linkItem
      linkItem.attr('class', 'summary_link disabled')

  getLink:(frame, sub)->
    if frame is undefined
      return @summary_line_container.selectAll('line')

    unless sub is undefined
      return @summary_line_container.selectAll('line[frame="'+frame+'"][sub="'+sub+'"]')
    @summary_line_container.selectAll('line[frame="'+frame+'"]')

  getSummary:(frame, sub) ->
    if frame is undefined
      return @summary_contents.selectAll('.summary_content')
    unless sub is undefined
      return @summary_contents.selectAll('.summary_content[frame="'+frame+'"][sub="'+sub+'"]')
    @summary_contents.selectAll('.summary_content[frame="'+frame+'"]')

  updateSummaryContent:(summaryParent, properties)->
    for k,v of properties
      element = summaryParent.select('.'+k)
      switch k
        when "prop_annotation"
          unless v
            v= ""
          element.node().value= v
        when "prop_severity"
          element.attr("src", "/assets/property/severity_#{v}.png")
        when "prop_posture"
          images = element.selectAll('img').data(v)
          images.enter()
            .append('img')
            .style('height', smallIconHeight)
            .style('width', smallIconHeight)
            .style('left', (d,i)->(textBoxWidth-iconHeight-smallIconHeight*(i+1))+'px')
            .style("src", (d)->"/assets/posture/#{d}.png")
          images.exit().remove()

  #  SUMMARY END #################