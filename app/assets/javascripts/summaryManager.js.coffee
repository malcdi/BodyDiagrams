class window.SummaryManager
  constructor:(@canvasState)->


  textBoxHeight = 20
  textBoxWidth = 150
  iconHeight = 25
  smallIconHeight = 20

  setupSummary: (tagGroup, frame, sub)->
    #summaries
    summaryParent = tagGroup.append('g')
      .attr('class', 'summary disabled')
      .attr('frame', frame)
      .attr('sub', sub)
      .on('click', ()->
        frameGroup = d3.select(this).attr('frame')
        subIndex = d3.select(this).attr('sub')
        self.highlightFrame(+frameGroup, subIndex)
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
      .attr('width', iconHeight)
      .attr('x', textBoxWidth-iconHeight)
    summaryParent.append('g')
      .attr('class', 'prop_freq')
      .attr('y', iconHeight-smallIconHeight)
    summaryParent.append('text')
      .attr('class', 'prop_annotation')
      .attr('y', iconHeight)

  hideOrShow: (frameIndex, hide)->
    newClass = (if hide then 'summary disabled' else 'summary')
    @getSummary(frameIndex).attr('class', newClass)

  closeSummary:(frameIndex, subIndex)->
    summaryItem = @getSummary(frameIndex, subIndex)
    if summaryItem
      summaryItem.attr('class', 'summary disabled')

  getSummary:(frameIndex, subIndex) ->
    group = @canvasState.svg.select("#tag_#{frameIndex}")
    if subIndex is undefined
      return group.selectAll('g.summary')
    d3.select(group.selectAll('g.summary')[0][subIndex])

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
          @setTextInSummary(element, v)
        when "prop_severity"
          element.attr("xlink:href", "/assets/property/severity_#{v}.png")
        when "prop_freq"
          images = element.selectAll('image').data(v)
          images.enter()
            .append('image')
            .attr('height', smallIconHeight)
            .attr('width', smallIconHeight)
            .attr('x', (d,i)->textBoxWidth-iconHeight-smallIconHeight*(i+1))
            .attr("xlink:href", (d)->"/assets/posture/#{d}.png")
          images.exit()

  #  SUMMARY END #################