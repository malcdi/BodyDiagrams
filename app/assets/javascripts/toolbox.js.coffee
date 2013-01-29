class window.Toolbox   

  # initially sets up and controls the tool box
  constructor: (parent, rotationParent, @bigBro)->
    @control = d3.select(parent).append("div")
      .attr("id", "toolbox_control")
      .attr("class","toolbox_container")

    @currentMode

    @Modes = {}

    # manipulation controls
    @setupControls()

    # rotation
    @setupRotationControls(rotationParent)
    $('#drag').trigger('click')


  # Helper Functions #
  getView: (curView, direction) ->
    if direction is "rotation_left"
      return (curView + 3) % 4
    else return (curView + 1) % 4  if direction is "rotation_right"
    0

  getOtherView: (direction) ->
    if direction is "rotation_left"
      return "rotation_right"
    else return "rotation_left"
    ""
  # Helper Functions END #

  # Event Handlers #
  updateCurrent: (highlight)->
    if highlight
      @currentMode.control.attr("src", @currentMode.on)
        .attr("class", "opMode selected")
    else
      @currentMode.control.attr("src", @currentMode.off)
        .attr("class", "opMode")

  rotate: (id)->
    @bigBro.currentView = @getView(@bigBro.currentView, id)
    $("#" + id)[0].src = @bigBro.ImageLoader.getBodyImageSrc(@bigBro.currentGender, @getView(@bigBro.currentView, id))
    otherDirection = @getOtherView(id)
    $("#" + otherDirection)[0].src = @bigBro.ImageLoader.getBodyImageSrc(@bigBro.currentGender, @getView(@bigBro.currentView, otherDirection))
    $(window).trigger({type:'rotated', message:@bigBro.currentView})


  # Event Handlers End #

  # SETUP #
  setupControls: ->
    _ = this

    #drag
    @Modes.drag = {}
    @Modes.drag.on = "/assets/dragHand.png"
    @Modes.drag.off = "/assets/dragHandInactive.png"
    @Modes.drag.control = @control.append("img")
      .attr("id", "drag")
      .attr("class", "opMode")
      .attr("src",  @Modes.drag.off) #TODO
      .on("click", -> 
        _.updateCurrent(false)
        _.currentMode = _.Modes.drag
        _.bigBro.cvState.setMode "zoom"
        _.updateCurrent(true))

    @Modes.rect_draw = {}
    @Modes.rect_draw.on = "/assets/drawIcon.png"
    @Modes.rect_draw.off = "/assets/drawIconInactive.png"
    @Modes.rect_draw.control = @control.append("img")
      .attr("id", "rect_draw")
      .attr("class", "opMode")
      .attr("src", @Modes.rect_draw.off) #TODO
      .on("click", -> 
        _.updateCurrent(false)
        _.currentMode = _.Modes.rect_draw
        _.bigBro.cvState.setMode "draw"
        _.updateCurrent(true))

    @Modes.draw = {}
    @Modes.draw.on = "/assets/drawIcon.png"
    @Modes.draw.off = "/assets/drawIconInactive.png"
    @Modes.draw.control = @control.append("img")
      .attr("id", "draw")
      .attr("class", "opMode")
      .attr("src", @Modes.draw.off) #TODO
      .on("click", -> 
        _.updateCurrent(false)
        _.currentMode = _.Modes.draw
        _.bigBro.cvState.setMode "draw"
        _.updateCurrent(true))

    #undo
    @control.append("img")
      .attr("id", "undo")
      .attr("class", "opMode")
      .attr("src", "/assets/undo.png")
      .on("click", ->  
        $(window).trigger({type:'last_undo_click'})
      )
      .on("mouseover", ->  
        $(window).trigger({type:'last_undo_mouseover'})
      )
      .on("mouseleave", -> 
        $(window).trigger({type:'last_undo_mouseout'})
      )

    @currentMode = @Modes.drag

  setupRotationControls: (parent)->
    _ = this
    left = d3.select(parent).append("img")
      .attr("id", "rotation_left")
      .attr("src", @bigBro.ImageLoader.getBodyImageSrc(@bigBro.currentGender, 3))
      .style("top", (_.bigBro.height - 150)+"px")
      .on("click", -> _.rotate(@id))

    right = d3.select(parent).append("img")
      .attr("id", "rotation_right")
      .style("top", (_.bigBro.height - 150)+"px")
      .attr("src", @bigBro.ImageLoader.getBodyImageSrc(@bigBro.currentGender, 1))
      .on("click", -> _.rotate(@id))
      
    padding = left[0][0].offsetLeft + parseInt(left.style("padding"))*4
    leftMargin = @bigBro.cvState.canvas.clientWidth - padding
    right.style("left", leftMargin+"px")
  # SETUP END #
