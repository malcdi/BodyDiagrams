class window.ZoomControl
  constructor:(bigBro)->
    @bigBro = bigBro

  setupControls: ()->
    _cvState = @bigBro.cvState
    $("#compass div").click ->
      switch @title
        when "Pan left"
          _cvState.setZoomPan -2, 0, 0
        when "Pan right"
          _cvState.setZoomPan 2, 0, 0
        when "Pan up"
          _cvState.setZoomPan 0, -2, 0
        when "Pan down"
          _cvState.setZoomPan 0, 2, 0

    sliderElem = $("#lmczbg")[0]

    #zoom in/out
    $("div[title=\"Zoom In\"]").click ->
      if parseInt(sliderElem.style.top) > 0
        newY = parseInt(sliderElem.style.top) - 10
        newY = Math.max(Math.min(137, newY), 0)
        sliderElem.style.top = newY + "px"
        _cvState.setZoomPan 0, 0, 0.75

    $("div[title=\"Zoom Out\"]").click ->
      if parseInt(sliderElem.style.top) < 137
        newY = parseInt(sliderElem.style.top) + 10
        newY = Math.max(Math.min(137, newY), 0)
        sliderElem.style.top = newY + "px"
        _cvState.setZoomPan 0, 0, -0.75


    #slider zoom
    $("#lmczb").mousedown (e) ->
      e.preventDefault()
      oldY = parseInt(sliderElem.style.top)
      newY = (e.pageY - @offsetTop) - 60
      sliderElem.style.top = Math.max(Math.min(137, newY), 0) + "px"
      _cvState.setZoomPan 0, 0, (oldY - newY) * 10 / 137
      @dragStart = true

    $("#lmczb").mousemove (e) ->
      e.preventDefault()
      if @dragStart
        newY = (e.pageY - @offsetTop) - 60
        newY = Math.max(Math.min(137, newY), 0)
        lastY = parseInt(sliderElem.style.top)
        sliderElem.style.top = newY + "px"
        _cvState.setZoomPan 0, 0, (lastY - newY) * 10 / 137

    $("#lmczb").mouseup (e) ->
      @dragStart = false

