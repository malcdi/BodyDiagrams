class window.SummaryManager
  constructor:(@canvasState, @left_border, @right_border)->
    @activated = window.bigBro.activatedProp
    @summary_container = d3.select("#canvasDiv").select("svg")
    
  textBoxHeight = 20
  textBoxWidth = 150
  iconHeight = 25
  smallIconHeight = 20
  boxMargin = 5

  setupSummary: (frame, sub)->
    _ = this
    #summaries
    summaryParent = @summary_container.append('g')
      .attr('class', 'summary disabled')
      .attr('index', "#{frame}_#{sub}")
      .call((selection)->
        window.eventManager.setup('summary', selection, _)
      )
    
    summaryParent.append('line')
      .attr('class', 'summary_link')
      .style('stroke-width', '1px')
      .style('stroke', 'steelblue')

    summaryContent = summaryParent.append('g')
      .attr('class', 'summary_content')

    summaryContent.append('rect')
      .attr('width', textBoxWidth)
      .attr('height', textBoxHeight+iconHeight)
      .attr('fill', 'none')
      .attr('stroke', 'grey')
      .attr('stroke-width', 1)

    summaryContent.append('rect')
      .attr('width', textBoxWidth) #TODO
      .attr('height', 20)
      .attr('fill', 'white')
      .attr('stroke', 'grey')
      .attr('stroke-width', 1)
      .attr('y', iconHeight)
      
    if @activated.prop_severity
      summaryContent.append('image')
        .attr('class', 'prop_severity')
        .attr('height', iconHeight)
        .attr('width', iconHeight+10)
        .attr('x', textBoxWidth-iconHeight)
    if @activated.prop_posture
      summaryContent.append('g')
        .attr('class', 'prop_posture')
        .attr('y', iconHeight-smallIconHeight)
    if @activated.prop_annotation
      summaryContent.append('text')
        .attr('class', 'prop_annotation')
        .attr('y', iconHeight)

  updateSummaryDisplay: (frame)->
    @summary_container.selectAll('g.summary')
      .attr('class', (d)->
        if +this.attributes.getNamedItem("frame").value==frame
          return 'summary'
        else
          return 'summary disabled'
        )
  updateSummary: (frame, sub, updateContent)->
    summaryItem = @getSummary(frame, sub)

    if summaryItem
      box = @canvasState.getBoundingBox(frame, sub)
      center = box.x+box.w/2 
      y = box.y
      linkItem = summaryItem.select('line.summary_link')
      if (@right_border-center)<(center-@left_border)
        x = box.x+box.w
        x_content = @right_border-x
        linkItem.attr('x1', 0) #tag
          .attr('y1', 0)
          .attr('x2', x_content) #summary
          .attr('y2', 0)
      else
        x= 0
        x_content = @left_border-textBoxWidth
        linkItem.attr('x1', box.x) #tag
          .attr('y1', 0)
          .attr('x2', @left_border)
          .attr('y2', 0)

      summaryItem.attr('class', 'summary')
        .attr('transform',"translate(#{x},#{y})")

      summaryItem.select('.summary_content')
        .attr('transform',"translate(#{x_content},0)")
      
    properties = @canvasState.allTags[frame][sub].getProperties()
    if updateContent then @updateSummaryContent(summaryItem, properties)
  
  closeSummary:(frame, sub)->
    summaryItem = @getSummary(frame, sub)
    if summaryItem
      summaryItem.attr('class', 'summary disabled')

  getSummary:(frame, sub) ->
    group = @summary_container.selectAll('g.summary[index="'+frame+'_'+sub+'"]')
    if group is undefined
      return null
    group
    
  appendingTspan:(target, word)->
    target.append("tspan")
      .attr("x", 0)
      .attr("dy", "1.0em")
      .text(word);  

  setTextInSummary:(elem, words)->
    #clear
    for child in elem.node().childNodes
      child.remove()

    #writing
    for word in words
      lastChild = elem.select(':last-child')
      if lastChild.empty() or word=="\n"
        @appendingTspan(elem, word)
      else if lastChild.node().offsetWidth < textBoxWidth-10
        lastChild.text(lastChild.text()+ word)
      else if lastChild.node().offsetTop>textBoxHeight+10
        lastChild.text(lastChild.text()+'...')
        return
      else if word != ''
        @appendingTspan(elem, word)

  updateSummaryContent:(summaryParent, properties)->
    for k,v of properties
      element = summaryParent.select('.'+k)
      switch k
        when "prop_annotation"
          unless v
            v= ""
          @setTextInSummary(element, v)
        when "prop_severity"
          element.attr("xlink:href", "/assets/property/severity_#{v}.png")
        when "prop_posture"
          images = element.selectAll('image').data(v)
          images.enter()
            .append('image')
            .attr('height', smallIconHeight)
            .attr('width', smallIconHeight)
            .attr('x', (d,i)->textBoxWidth-iconHeight-smallIconHeight*(i+1))
            .attr("xlink:href", (d)->"/assets/posture/#{d}.png")
          images.exit().remove()

  #  SUMMARY END #################