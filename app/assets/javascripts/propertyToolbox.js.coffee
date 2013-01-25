class window.PropertyToolbox
  SEVERITY: ["minor", "moderate", "major", "critical"]
  LAYERS: ["Skin", "Muscle", "Internal", "Bone/Joint", "Neural"]
  TYPES: ["sharp", "dull", "hot", "numb", "sensitive", "itchy", "shooting", "cramping", "pounding", "aching"]
  FREQS: ["Stand", "Walk", "Sit", "Lie"]

  # initially sets up and controls the tool box
  constructor: (parent, global)->
    @bigBro = global
    @property = d3.select(parent).append("div")
      .attr("class", "toolbox_container")
      .attr("id", "toolbox_property")

  # property
    @setupPropertyControls()

  activatePropertyControls: (activate, d3Box)->
    if activate
      @updateProperty @bigBro.cvState.downloadTagProperties()
      @openAnnotationBox(d3Box)
    else
      @setDefaultPropertyValues()
      @closeAnnotationBox()

    #annotation popup
    for k,v of @PropControls
      prop = v
      if activate
        prop.control.attr("src", prop.on)
          .attr("class", "opMode")
      else
        prop.control.attr("src", prop.off)
          .attr("class", "opMode disabled")

  closeAnnotationBox: ()->
    @Annotation.attr('class', 'annotation disabled')
    $('#prop_annotation_text').removeClass('open')

  openAnnotationBox: (d3Bound)->
    offsetLeft = parseInt(d3Bound.attr('x'))+parseInt(d3Bound.attr('width'))-90
    offsetTop = parseInt(d3Bound.attr('y'))-10
    @Annotation.attr('class', 'annotation')
      .style('left', offsetLeft+"px")
      .style('top', offsetTop+"px")

  #TODO
  setPropertyValueInControl: (prop, values)->
    if prop is "prop_annotation"
      $('#prop_annotation_text').val(values)
      $('#annotation_summary').text(values)

    else if values.length is 0
      children = d3.select('#'+prop+'_expand').select('div').node().children
      for child in children
        $(child).removeClass("tag-selected")
      if prop is "prop_severity"
        $("#prop_severity_minor").addClass('tag-selected')
        @PropControls.severity.on = $('#prop_severity_minor').attr("src")
    else
      for v in values
        if prop is "prop_severity"
          $('#prop_severity_expand').find(".tag-selected").toggleClass("tag-selected")
          @PropControls.severity.on = $('#'+prop+"_"+v).attr("src")
        $('#'+prop+"_"+v).addClass("tag-selected")

    if prop is "prop_type"
      $("#pain_type_tags").val(values)

  setDefaultPropertyValues:()->
    @setPropertyValueInControl("prop_severity", [])
    @setPropertyValueInControl("prop_type", "")
    @setPropertyValueInControl("prop_layer", [])
    @setPropertyValueInControl("prop_freq", [])
    @setPropertyValueInControl("prop_annotation", "")
    
  updateProperty:(properties)->
    @setDefaultPropertyValues
    for k,v of properties
      @setPropertyValueInControl(k,v)

  updateControl: (elem, id)->
    if not elem.classList.contains "disabled"
      #close
      if @openControl
        oldId = @openControl
        oldElem = d3.select("#prop_"+oldId+"_expand")
        oldElem.style("display", "none")
        d3.select("#prop_"+oldId).style("border", "")
        if oldId is id 
          return

      #open
      d3Elem = d3.select("#prop_"+id+"_expand")
      if d3Elem.style("display") is "none"
        @openControl = id
        d3.select("#prop_"+id+"_expand").style("display", "block")
        d3.select("#prop_"+id).style("border", "solid 2px rgb(108, 204, 128)")
      else
        d3Elem.style("display", "none")
        d3.select("#prop_"+id).style("border", "")

  setupPropertyControls: ->
    _ = this
    #annotation box
    @Annotation = @property.append("div")
      .attr("id", "prop_annotation")
      .attr("class", "annotation disabled")
    
    @Annotation.append('textarea')
      .attr('id', 'prop_annotation_text')
      .attr('placeholder', 'Annotate...')
      .attr('rows',1)
      .on('keyup', ->
        window.trigger({
          type:'updateProperty', 
          message:{"prop_annotation":this.value}})
        )
    @Annotation.append('img')
      .attr("src", "/assets/property/annotation.png")
      .on("click", -> 
        #open up control
        txtA = $('#prop_annotation_text')
        if txtA.hasClass('open')
          txtA.removeClass('open')
          d3.select('#annotation_summary').text(txtA.val())
        else
          txtA.addClass('open')
          $('#annotation_summary').text('')
          #historymanaging
          curCloud = _.bigBro.cvState.getCurrentTagCloudIndex()
          if _.bigBro.historyManager.needsRecording(curCloud)
            data = _.bigBro.cvState.markHistoryDataForCurrent()
            _.bigBro.historyManager.addNew(data)
            _.bigBro.historyManager.highlightWindow(data.index)
      )

    @Annotation.append('span')
      .attr('id', 'annotation_summary')


    @PropControls = {}
    @PropControls.severity = {}
    @PropControls.severity.on = "/assets/property/severity_minor.png"
    @PropControls.severity.off = "/assets/property/severity_minor.png"
    @PropControls.severity.control = @property.append("img")
      .attr("id", "prop_severity")
      .attr("class", "opMode disabled")
      .attr("src", @PropControls.severity.off)
      .on("click", -> 
        #open up control
        _.updateControl(this, "severity")
        )

    @PropControls.type = {}
    @PropControls.type.on = "/assets/property/type_active.png"
    @PropControls.type.off = "/assets/property/type_inactive.png"
    @PropControls.type.control = @property.append("img")
      .attr("id", "prop_type")
      .attr("class", "opMode disabled")
      .attr("src", @PropControls.type.off)
      .on("click", -> 
        #open up control
        _.updateControl(this, "type")
        )

    @PropControls.layer = {}
    @PropControls.layer.on = "/assets/property/layer_active.png"
    @PropControls.layer.off = "/assets/property/layer_inactive.png"
    @PropControls.layer.control = @property.append("img")
      .attr("id", "prop_layer")
      .attr("class", "opMode disabled")
      .attr("src", @PropControls.layer.off)
      .on("click", -> 
        #open up control
        _.updateControl(this, "layer")
        )

    @PropControls.freq = {}
    @PropControls.freq.on = "/assets/property/frequency_active.png"
    @PropControls.freq.off = "/assets/property/frequency_inactive.png"
    @PropControls.freq.control = @property.append("img")
      .attr("id", "prop_freq")
      .attr("class", "opMode disabled")
      .attr("src", @PropControls.freq.off)
      .on("click", -> 
        #open up control
        _.updateControl(this, "freq")
        )

    #drop down setups
    #setup positions
    severity_html = @PropControls.severity.control[0][0]
    d3.select("#prop_severity_expand")
      .style("left", severity_html.offsetLeft+"px")
      .style("top", (severity_html.offsetTop+severity_html.offsetHeight)+"px")
    layer_html = @PropControls.layer.control[0][0]
    d3.select("#prop_layer_expand")
      .style("left", layer_html.offsetLeft+"px")
      .style("top", (layer_html.offsetTop+layer_html.offsetHeight)+"px")
    freq_html = @PropControls.freq.control[0][0]
    d3.select("#prop_freq_expand")
      .style("left", freq_html.offsetLeft+"px")
      .style("top", (freq_html.offsetTop+freq_html.offsetHeight)+"px")
    type_html = @PropControls.type.control[0][0]
    d3.select("#prop_type_expand")
      .style("left", type_html.offsetLeft+"px")
      .style("top", (type_html.offsetTop+type_html.offsetHeight)+"px")

    #SEVERITY slider
    severeElem = d3.select('#prop_severity_expand').append('div')
      .attr('class', 'prop_severity');
    for severity in @SEVERITY
      severeElem.append('img')
        .attr('class', 'opMode')
        .attr('id', 'prop_severity_'+severity)
        .style('display', 'block')
        .attr('src', '/assets/property/severity_'+severity+'.png')
        .on('click', ()-> 
          selected = $(this.parentElement).find(".tag-selected")
          selected.toggleClass("tag-selected")
          $(this).toggleClass("tag-selected")
          severityLevel = this.id.substring(14)
          _.bigBro.cvState.uploadTagProperties({"prop_severity": [severityLevel]})

          #change the menu icon
          menu = d3.select("#prop_severity")
            .attr('src', this.src)

          #close menu
          _.updateControl(menu.node(), "severity")
          )

    #LAYER
    layerElem = d3.select('#prop_layer_expand').append('div')
      .attr('class', 'prop_layer');
    for layer in @LAYERS
      layerElem.append('span')
        .attr('class', 'annotator-tag')
        .attr('id', 'prop_layer_'+layer)
        .html(layer)
        .on('click', ()-> tagClicked(this, _))

    #FREQ
    freqElem = d3.select('#prop_freq_expand').append('div')
      .attr('class', 'prop_freq');
    for freq in @FREQS
      freqElem.append('span')
        .attr('class', 'annotator-tag')
        .attr('id', 'prop_freq_'+freq)
        .html(freq)
        .on('click', ()-> tagClicked(this, _))

    #TYPES
    typeElem = d3.select('#prop_type_expand').append('div')
      .attr('class', 'prop_type');
    for type in @TYPES
      typeElem.append('span')
        .attr('class', 'annotator-type-tag')
        .attr('id', 'prop_type_'+type)
        .html('#'+type)
        .on('click',()->
          pastStr = $("#pain_type_tags").val();
          if pastStr.indexOf($(this).text())<0
            pastStr+=$(this).text()+", "
            $("#pain_type_tags").val(pastStr)

          prop = {}
          prop[this.parentElement.className]=pastStr
          _.bigBro.cvState.uploadTagProperties(prop)
        )

tagClicked = (self, _) ->
  if self.classList!=undefined && self.classList.contains("annotator-tag")
    $(self).toggleClass("tag-selected")

  selectedTags = d3.select(self.parentElement).selectAll(".tag-selected")
  tagProperties = []
  for tag in selectedTags[0]
    tagProperties.push tag.textContent

  prop = {}
  prop[self.parentElement.className]=tagProperties
  _.bigBro.cvState.uploadTagProperties(prop)

