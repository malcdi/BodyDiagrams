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
    @rotation_view = 0

  # Helper Functions #
  getDirectionVal: (curView, nextView)->
    (nextView-curView+4)%4

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

  # Update Functions #
  updateRotationViews:(view_side)->
    direction = @getDirectionVal(@rotation_view, view_side)
    return if direction==0
    dir = "rotation_left"
    if direction>0
      dir = "rotation_right"
    $("#" + dir)[0].src = window.bigBro.ImageLoader.getBodyImageSrc(window.bigBro.currentGender, @getView(@rotation_view, dir))
    otherDirection = @getOtherView(dir)
    $("#" + otherDirection)[0].src = window.bigBro.ImageLoader.getBodyImageSrc(window.bigBro.currentGender, @getView(@rotation_view, otherDirection))
    @rotation_view = view_side
      
  ##########################

  # Event Handlers #
  updateCurrent: (highlight)->
    if highlight
      @currentMode.control.attr("src", @currentMode.on)
        .attr("class", "opMode tooltip selected")
    else
      @currentMode.control.attr("src", @currentMode.off)
        .attr("class", "opMode tooltip")

  rotate: (id, rotationCheck)->
    # check if rotatable
    if rotationCheck!=undefined or window.bigBro.cvState.rotatable()
      @rotation_view = @getView(@rotation_view, id)
      $("#" + id)[0].src = window.bigBro.ImageLoader.getBodyImageSrc(window.bigBro.currentGender, @getView(@rotation_view, id))
      otherDirection = @getOtherView(id)
      $("#" + otherDirection)[0].src = window.bigBro.ImageLoader.getBodyImageSrc(window.bigBro.currentGender, @getView(@rotation_view, otherDirection))
      window.triggerEvent({type:'rotated', message:@rotation_view})
    else
      alert "Plsease select a new or empty frame to rotate"

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
      .attr("class", "opMode tooltip")
      .attr("src",  @Modes.drag.off) #TODO
      .attr("title", "drag")
      .call (selection)-> 
        window.eventManager.setup('toolbox', selection, _)

    @Modes.rect_draw = {}
    @Modes.rect_draw.on = "/assets/drawRect.png"
    @Modes.rect_draw.off = "/assets/drawRectInactive.png"
    @Modes.rect_draw.control = @control.append("img")
      .attr("id", "rect_draw")
      .attr("class", "opMode tooltip")
      .attr("src", @Modes.rect_draw.off)
      .attr("title", "rectangle")
      .call (selection)-> 
        window.eventManager.setup('toolbox', selection, _)

    @Modes.draw = {}
    @Modes.draw.on = "/assets/drawIcon.png"
    @Modes.draw.off = "/assets/drawIconInactive.png"
    @Modes.draw.control = @control.append("img")
      .attr("id", "draw")
      .attr("class", "opMode tooltip")
      .attr("src", @Modes.draw.off) #TODO
      .attr("title", "pencil")
      .call (selection)-> 
        window.eventManager.setup('toolbox', selection, _)

    #undo
    @control.append("img")
      .attr("id", "undo")
      .attr("class", "opMode tooltip")
      .attr("src", "/assets/undo.png")
      .attr("title", "undo")
      .call (selection)-> 
        window.eventManager.setup('toolbox_undo', selection, _)

    @currentMode = @Modes.drag

  setupRotationControls: (parent)->
    _ = this
    left = d3.select(parent).append("img")
      .attr("id", "rotation_left")
      .attr("class", "tooltip")
      .attr("title", "rotate left")
      .attr("src", window.bigBro.ImageLoader.getBodyImageSrc(window.bigBro.currentGender, 3))
      .style("top", (window.bigBro.height - 150)+"px")
      .call (selection)-> 
        window.eventManager.setup('rotate', selection, _)

    right = d3.select(parent).append("img")
      .attr("id", "rotation_right")
      .attr("class", "tooltip")
      .attr("title", "rotate right")
      .style("top", (window.bigBro.height - 150)+"px")
      .attr("src", window.bigBro.ImageLoader.getBodyImageSrc(window.bigBro.currentGender, 1))
      .call (selection)-> 
        window.eventManager.setup('rotate', selection, _)
      
    padding = left[0][0].offsetLeft + parseInt(left.style("padding"))*4
    leftMargin = window.bigBro.cvState.canvas.clientWidth - padding
    right.style("left", leftMargin+"px")
  # SETUP END #
