class window.PropertyPopup
  POSTURES: ["stand", "walk", "sit", "lie"]
  FREQS: ["very frequent", "few times a day", "once a day", "sometimes in a day"]

  # initially sets up and controls the tool box
  constructor: (parent)->
    @property = d3.select(parent).append("div")
      .attr("id", "toolbox_property")
      .attr("class", "disabled")
    @property.index = null
    @props = window.bigBro.activatedProp

  # property
    @setupPropertyControls()

  boxMove: (offset)->
    @property.attr("class","")
      .style('left', offset.left+"px")
      .style('top', offset.top+"px")
      .attr('class', '')

  activatePropertyControls: (activate, position, properties, index) ->
    if activate
      @updateProperty properties,index
      @openPopup(position)
    else
      @closePopup()
      @setDefaultPropertyValues()

  isPoppupOpen:()->
    @property.index!=null
    
  openPopupIndex:()->
    @property.index

  closePopup: ()->
    return if @property.attr('class')=="disabled"
    @property.attr('class','disabled')
    window.triggerEvent({
      type:'updateProperty', 
      message:{properties: @getAllValues(), index:@property.index}
    })
    if @props.prop_annotation
      $('#prop_annotation_text').removeClass('open')
    if @props.prop_posture
      $("#prop_posture").multiselect("uncheckAll")
    @property.index = null

  getOffset: (d3Bound)->
    {left:d3Bound.x+d3Bound.w, top:d3Bound.y-20}

  openPopup: (offset)->
    @property.attr("class","")
      .style('left', offset.left+"px")
      .style('top', offset.top+"px")
      .attr('class', '')
    $('#prop_annotation_text').focus()

  #SETTING VALUES INTO THE POPUP
  setPropertyValueInControl: (prop, value)->
    if prop is "prop_annotation"
      $('#prop_annotation_text').val(value).trigger('autosize');
    else if prop is "prop_severity"
      $(@PropControls.severity.node()).slider('value', value)
    else if prop is "prop_posture"
      for v in value
          $("#"+prop).multiselect("widget")
          .find(":checkbox").each(()->
            if this.value is v
              this.click(); 
          )

  setDefaultPropertyValues:()->
    if @props.prop_severity
      @setPropertyValueInControl("prop_severity", 3)
    if @props.prop_posture
      @setPropertyValueInControl("prop_posture", [])
    if @props.prop_annotation
      @setPropertyValueInControl("prop_annotation", "")
    
  updateProperty:(properties, index)->
    @property.index = index
    @setDefaultPropertyValues
    for k,v of properties
      if @props["#{k}"]
        @setPropertyValueInControl(k,v)
  ##############

  # RETRIEVING VALUES FROM the POPUP

  getAllValues: ()->
    allVal = {}
    if @props.prop_severity
      allVal.prop_severity= @getSeverityVal() 
    if @props.prop_posture
      allVal.prop_posture = @getPostureVal()
    if @props.prop_annotation
      allVal.prop_annotation = @getAnnotationVal()
    return allVal

  getSeverityVal:()->
    severity_slider = @PropControls.severity.node()
    $(severity_slider).slider("value")

  severity_val_slided:(e, ui)=>
    window.triggerEvent({
      type:'severity_value_change'
      message:ui.value
    })
    @PropControls.severity.select('.ui-slider-handle')
      .style('background-color',colorSelector(ui.value))

  getPostureVal:()->
    $.map($("#prop_posture").multiselect("getChecked"), (val, i)->
            val.value)

  getAnnotationVal:()->
    $('#prop_annotation_text').val()

  ##############

  setupPropertyControls: ->
    _ = this
    if window.bigBro.activatedProp.prop_annotation
      #annotation box
      annotationBox = @property.append('textarea')
        .attr('id', 'prop_annotation_text')
        .attr('placeholder', 'Describe your symptom here...')
        .attr('rows',3)
      $(annotationBox.node()).autosize()

    @PropControls = {}

    if window.bigBro.activatedProp.prop_severity
      #SEVERITY 
      container = @property.append("div")
        .attr("id", "prop_severity")
      container.append("span")
        .text("Symptom Severity : ")

      @PropControls.severity = container.append('div')
      @PropControls.severity.append('span')
        .style('margin','-5px 0px 0px -5px')
        .html('1')
      @PropControls.severity.append('span')
        .style('margin','-3px -7px 0px 0px')
        .style('float','right')
        .html('10')
      $(@PropControls.severity.node()).slider({
        orientation: "horizontal",
        min:1
        max: 10,
        value:3,
        slide: @severity_val_slided
      })
      @PropControls.severity.select('.ui-slider-handle')
        .style('background-color',colorSelector(3))
    
    if window.bigBro.activatedProp.prop_posture
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

    if window.bigBro.activatedProp.prop_freq
      #freq
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



