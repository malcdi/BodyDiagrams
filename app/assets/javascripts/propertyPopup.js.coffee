class window.PropertyPopup
  SEVERITY: ["minor", "moderate", "major", "critical"]
  POSTURES: ["stand", "walk", "sit", "lie"]
  FREQS: ["very frequent", "few times a day", "once a day", "sometimes in a day"]

  # initially sets up and controls the tool box
  constructor: (parent)->
    @property = d3.select(parent).append("div")
      .attr("id", "toolbox_property")
      .attr("class", "disabled")
    @property.index = null

  # property
    @setupPropertyControls()

  boxMove: (d3Box, data)->
    offset= @getOffset(d3Box)
    @property.attr("class","")
      .style('left', offset.left+"px")
      .style('top', offset.top+"px")
      .attr('class', '')

  activatePropertyControls: (activate, d3Box, properties, index) ->
    if activate
      @updateProperty properties,index
      @openPopup(d3Box)
    else
      @closePopup()
      @setDefaultPropertyValues()

  isPoppupOpen:()->
    @property.index!=null

  closePopup: ()->
    @property.attr('class', 'disabled')
    window.triggerEvent({
      type:'updateProperty', 
      message:{properties: @getAllValues(), index:@property.index}
    })
    $('#prop_annotation_text').removeClass('open')
    $("#prop_posture").multiselect("uncheckAll")
    @property.index = null

  getOffset: (d3Bound)->
    {left:d3Bound.x+d3Bound.w, top:d3Bound.y-20}

  openPopup: (d3Bound)->
    offset= @getOffset(d3Bound)
    @property.attr("class","")
      .style('left', offset.left+"px")
      .style('top', offset.top+"px")
      .attr('class', '')
    $('#prop_annotation_text').focus()

  #SETTING VALUES INTO THE POPUP
  setPropertyValueInControl: (prop, value)->
    if prop is "prop_annotation"
      $('#prop_annotation_text').val(value)
    else if prop is "prop_severity"
      $('#prop_severity').find(".tag-selected").toggleClass("tag-selected")
      if value
        $('#prop_severity_'+value).toggleClass("tag-selected")
      else
        $('#prop_severity_minor').toggleClass("tag-selected")
    else if prop is "prop_posture"
      for v in value
          $("#"+prop).multiselect("widget")
          .find(":checkbox").each(()->
            if this.value is v
              this.click(); 
          )

  setDefaultPropertyValues:()->
    @setPropertyValueInControl("prop_severity", "")
    @setPropertyValueInControl("prop_posture", [])
    @setPropertyValueInControl("prop_annotation", "")
    
  updateProperty:(properties, index)->
    @property.index = index
    @setDefaultPropertyValues
    for k,v of properties
      @setPropertyValueInControl(k,v)
  ##############

  # RETRIEVING VALUES FROM the POPUP

  getAllValues: ()->
    {prop_severity: @getSeverityVal(), prop_posture:@getPostureVal(), prop_annotation:@getAnnotationVal()}

  getSeverityVal:()->
    selected = @PropControls.severity.select(".tag-selected")
    return "minor" if selected==null or selected.empty()
    selected.attr("id").substring(14)

  getPostureVal:()->
    $.map($("#prop_posture").multiselect("getChecked"), (val, i)->
            val.value)

  getAnnotationVal:()->
    $('#prop_annotation_text').val()

  ##############

  setupPropertyControls: ->
    _ = this
    #annotation box
    @property.append('textarea')
      .attr('id', 'prop_annotation_text tooltip')
      .attr('placeholder', 'Describe your symptom here...')
      .attr('rows',3)

    @PropControls = {}

    #SEVERITY 
    @PropControls.severity = @property.append("div")
      .attr("id", "prop_severity")
    @PropControls.severity.append("span")
      .text("Symptom Severity : ")

    for severity in @SEVERITY
      @PropControls.severity.append('img')
        .attr('class', 'opMode tooltip')
        .attr('id', 'prop_severity_'+severity)
        .attr('src', '/assets/property/severity_'+severity+'.png')
        .attr("title", "#{severity}")
        .call((selection)->
          window.eventManager.setup('severityPropIcon', selection, _)
        )

    $('#prop_severity_minor').attr('class','opMode tag-selected tooltip')

    #Posture
    @PropControls.posture = @property.append("select")
      .attr("id", "prop_posture")
      .attr("name", "posture_selection")
      .attr("title", "Postures that cause the symptom")
      .attr("multiple", "multiple")

    for posture in @POSTURES
      @PropControls.posture.append("option")
        .attr("value", posture) 
        .text(posture)

    $("#prop_posture").multiselect({
        noneSelectedText: 'Select causing postures'
        selectedList: 4
      })
    ###
    #posture
    @PropControls.freq = @property.append("select")
      .attr("id", "prop_freq")
      .attr("name", "freq_selection")
      .attr("multiple", "multiple")

    for freq in @FREQS
      @PropControls.posture.append("option")
        .attr("value", freq)
        .text(freq)

    $("#prop_freq").multiselect({
        noneSelectedText: 'Select how often symptom occurs'
        selectedList: 4
      })
    ###

    @property.append('img')
      .attr('class', 'opMode button tooltip')
      .attr('src', '/assets/done.png')
      .attr('title', 'save')
      .call((selection)->
          window.eventManager.setup('popup_done', selection, _)
        )

    @property.append('img')
      .attr('class', 'opMode button tooltip')
      .attr('src', '/assets/delete.png')
      .attr('title', 'delete this one')
      .call((selection)->
          window.eventManager.setup('popup_delete', selection, _)
        )



