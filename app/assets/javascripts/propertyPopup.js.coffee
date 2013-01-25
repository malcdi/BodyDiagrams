class window.PropertyPopup
  SEVERITY: ["minor", "moderate", "major", "critical"]
  FREQS: ["stand", "walk", "sit", "lie"]

  # initially sets up and controls the tool box
  constructor: (parent)->
    @property = d3.select(parent).append("div")
      .attr("id", "toolbox_property")
      .attr("class", "disabled")

    @summaries = {}
    @summaries.parent = d3.select(parent).append("div")
      .attr("id", "summaries")

  # property
    @setupPropertyControls()

  boxMove: (d3Box, data)->
    offset= @getOffset(d3Box)
    @property.attr("class","")
      .style('left', offset.left+"px")
      .style('top', offset.top+"px")
      .attr('class', '')
    d3.select("#summary_#{data.tagIdStr}")
      .style('left', offset.left+"px")
      .style('top', offset.top+"px")

  activatePropertyControls: (activate, d3Box, data) ->
    if activate
      @updateProperty data.properties
      @closeSummary(data.tagIdStr)
      @openPopup(d3Box)
    else
      @openSummary(data.tagIdStr)
      @setDefaultPropertyValues()
      @closePopup()

  closeSummary: (tagIdStr)->
    console.log "close #{tagIdStr}"
    d3.select("#summary_#{tagIdStr}").style("display", "none")

  hideSummaries:(groupId)->
    d3.select(".group_#{groupId}").style("display", "none")

  openSummary: (tagIdStr)->  
    if tagIdStr is undefined then return  

    console.log "open #{tagIdStr}"
    if @summaries[tagIdStr] is undefined
      indexes = /([0-9]*)_([0-9]*)/.exec(tagIdStr)
      #create new
      @summaries[tagIdStr] = @summaries.parent.append("div")
      .attr("class", "summary_container group_#{indexes[1]}")
        .attr("id", "summary_#{tagIdStr}")
        .on('click',()->
          $(window).trigger({
            type:'needHighlight', 
            message:tagIdStr
          })
        )
      @summaries[tagIdStr].append("div")
        .attr("class", "summary_annotation")
      @summaries[tagIdStr].append("div")
        .attr("class", "summary_freq")
      @summaries[tagIdStr].append("div")
        .attr("class", "summary_severity")
      
    offset = {left:@property.style('left'), top:@property.style('top')}
    @summaries[tagIdStr].style("display", "block")
    @summaries[tagIdStr].style('left', offset.left)
      .style('top', offset.top)
    @summaries[tagIdStr].select(".summary_annotation").text("\"#{@getAnnotationVal()}\"")
    @summaries[tagIdStr].select(".summary_freq").text("posture:#{@getFreqVal()}")
    @summaries[tagIdStr].select(".summary_severity").text("severity:#{@getSeverityVal()}")

  closePopup: ()->
    @property.attr('class', 'disabled')
    $('#prop_annotation_text').removeClass('open')
    $("#prop_freq").multiselect("uncheckAll")

  getOffset: (d3Bound)->
    offsetLeft = parseInt(d3Bound.attr('x'))+parseInt(d3Bound.attr('width'))
    offsetTop = parseInt(d3Bound.attr('y'))
    {left:offsetLeft, top:offsetTop}

  openPopup: (d3Bound)->
    offset= @getOffset(d3Bound)
    @property.attr("class","")
      .style('left', offset.left+"px")
      .style('top', offset.top+"px")
      .attr('class', '')
    $('#prop_annotation_text').focus()

  #TODO
  setPropertyValueInControl: (prop, values)->
    if prop is "prop_annotation"
      $('#prop_annotation_text').val(values)
    else if prop is "prop_severity"
      $('#prop_severity').find(".tag-selected").toggleClass("tag-selected")
      if values[0]
        $('#prop_severity_'+values[0]).toggleClass("tag-selected")
      else
        $('#prop_severity_minor').toggleClass("tag-selected")
    else if prop is "prop_freq"
      for v in values
          $("#"+prop).multiselect("widget")
          .find(":checkbox").each(()->
            if this.value is v
              this.click();
          )

  setDefaultPropertyValues:()->
    @setPropertyValueInControl("prop_severity", [])
    @setPropertyValueInControl("prop_freq", [])
    @setPropertyValueInControl("prop_annotation", "")
    
  updateProperty:(properties)->
    @setDefaultPropertyValues
    for k,v of properties
      @setPropertyValueInControl(k,v)

  getSeverityVal:()->
    selected = @PropControls.severity.select(".tag-selected")
    selected.attr("id").substring(14)

  getFreqVal:()->
    $.map($("#prop_freq").multiselect("getChecked"), (val, i)->
            val.value)

  getAnnotationVal:()->
    $('#prop_annotation_text').val()


  setupPropertyControls: ->
    _ = this
    #annotation box
    @property.append('textarea')
      .attr('id', 'prop_annotation_text')
      .attr('placeholder', 'Annotate...')
      .attr('rows',3)
      .on('keyup', ->
        $(window).trigger({
          type:'updateProperty', 
          message:{"prop_annotation":this.value}
        })
      )

    @PropControls = {}

    #SEVERITY 
    @PropControls.severity = @property.append("div")
      .attr("id", "prop_severity")
    @PropControls.severity.append("span")
      .text("Symptom Severity : ")

    for severity in @SEVERITY
      @PropControls.severity.append('img')
        .attr('class', 'opMode')
        .attr('id', 'prop_severity_'+severity)
        .attr('src', '/assets/property/severity_'+severity+'.png')
        .on('click', ()-> 
          selected = $(this.parentElement).find(".tag-selected")
          selected.toggleClass("tag-selected")
          $(this).toggleClass("tag-selected")
          severityLevel = _.getSeverityVal()
          $(window).trigger({
            type:'updateProperty', 
            message:{"prop_severity":[severityLevel]}
          })
        )
    $('#prop_severity_minor').attr('class','opMode tag-selected')

    #FREQ

    @PropControls.freq = @property.append("select")
      .attr("id", "prop_freq")
      .attr("name", "frequency_selection")
      .attr("multiple", "multiple")

    for freq in @FREQS
      @PropControls.freq.append("option")
        .attr("value", freq)
        .text(freq)

    $("#prop_freq").multiselect({
        noneSelectedText: 'Select causing postures'
        selectedList: 4
      })
      .bind("multiselectclick", (event, ui)->
        $(window).trigger({
          type:'updateProperty', 
          message:{"prop_freq":_.getFreqVal()}
        })
      )

