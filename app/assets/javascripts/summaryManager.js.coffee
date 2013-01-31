class window.SummaryManager
  constructor:(@canvasState)->
    
  textBoxHeight = 20
  textBoxWidth = 150
  iconHeight = 25
  smallIconHeight = 20

  setupSummary: (tagGroup, frame, sub)->
    _ = this
    #summaries
    summaryParent = tagGroup.append('g')
      .attr('class', 'summary disabled')
      .attr('frame', frame)
      .attr('sub', sub)
      .call((selection)->
        window.eventManager.setup('summary', selection, _)
      )

    summaryParent.append('rect')
      .attr('width', textBoxWidth) #TODO
      .attr('height', 20)
      .attr('fill', 'white')
      .attr('stroke', 'grey')
      .attr('stroke-width', 1)
      .attr('y', iconHeight)
    summaryParent.append('image')
      .attr('class', 'prop_severity')
      .attr('height', iconHeight)
      .attr('width', iconHeight+10)
      .attr('x', textBoxWidth-iconHeight)
    summaryParent.append('g')
      .attr('class', 'prop_posture')
      .attr('y', iconHeight-smallIconHeight)
    summaryParent.append('text')
      .attr('class', 'prop_annotation')
      .attr('y', iconHeight)

  updateSummaryDisplay: (frame)->
    @canvasState.svg.selectAll('g.summary')
      .attr('class', (d)->
        if +this.attributes.getNamedItem("frame").value==frame
          return 'summary'
        else
          return 'summary disabled'
        )

  closeSummary:(frame, sub)->
    summaryItem = @getSummary(frame, sub)
    if summaryItem
      summaryItem.attr('class', 'summary disabled')

  getSummary:(frame, sub) ->
    group = @canvasState.svg.select("#tag_#{frame}")
    if sub is undefined
      return group.selectAll('g.summary')
    d3.select(group.selectAll('g.summary')[0][sub])

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