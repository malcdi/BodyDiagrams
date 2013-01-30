class window.Toolbox   

  # initially sets up and controls the tool box
  constructor: (parent, rotationParent)->
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
    window.bigBro.currentView = @getView(window.bigBro.currentView, id)
    $("#" + id)[0].src = window.bigBro.ImageLoader.getBodyImageSrc(window.bigBro.currentGender, @getView(window.bigBro.currentView, id))
    otherDirection = @getOtherView(id)
    $("#" + otherDirection)[0].src = window.bigBro.ImageLoader.getBodyImageSrc(window.bigBro.currentGender, @getView(window.bigBro.currentView, otherDirection))
    window.triggerEvent({type:'rotated', message:window.bigBro.currentView})


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
      .call (selection)-> 
        window.eventManager.setup('toolbox', selection, _)

    @Modes.rect_draw = {}
    @Modes.rect_draw.on = "/assets/drawRect.png"
    @Modes.rect_draw.off = "/assets/drawRect.png"
    @Modes.rect_draw.control = @control.append("img")
      .attr("id", "rect_draw")
      .attr("class", "opMode")
      .attr("src", @Modes.rect_draw.off)
      .call (selection)-> 
        window.eventManager.setup('toolbox', selection, _)

    @Modes.draw = {}
    @Modes.draw.on = "/assets/drawIcon.png"
    @Modes.draw.off = "/assets/drawIconInactive.png"
    @Modes.draw.control = @control.append("img")
      .attr("id", "draw")
      .attr("class", "opMode")
      .attr("src", @Modes.draw.off) #TODO
      .call (selection)-> 
        window.eventManager.setup('toolbox', selection, _)

    #undo
    @control.append("img")
      .attr("id", "undo")
      .attr("class", "opMode")
      .attr("src", "/assets/undo.png")
      .call (selection)-> 
        window.eventManager.setup('toolbox_undo', selection, _)

    @currentMode = @Modes.drag

  setupRotationControls: (parent)->
    _ = this
    left = d3.select(parent).append("img")
      .attr("id", "rotation_left")
      .attr("src", window.bigBro.ImageLoader.getBodyImageSrc(window.bigBro.currentGender, 3))
      .style("top", (window.bigBro.height - 150)+"px")
      .call (selection)-> 
        window.eventManager.setup('rotate', selection, _)

    right = d3.select(parent).append("img")
      .attr("id", "rotation_right")
      .style("top", (window.bigBro.height - 150)+"px")
      .attr("src", window.bigBro.ImageLoader.getBodyImageSrc(window.bigBro.currentGender, 1))
      .call (selection)-> 
        window.eventManager.setup('rotate', selection, _)
      
    padding = left[0][0].offsetLeft + parseInt(left.style("padding"))*4
    leftMargin = window.bigBro.cvState.canvas.clientWidth - padding
    right.style("left", leftMargin+"px")
  # SETUP END #
