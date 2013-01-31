class window.ZoomControl
  constructor:()->
    @moveFactor = 5
    @zoomFactor = 1.2

  setupControls: (left, top)->
    _ = this

    $('#compass').css({"left":left+"px", "top":top+"px"})
    $('#compassHolder').css({"left":left+"px", "top":top+"px"})
    $('#lmczoom').css({"left":(left+28)+"px", "top":(top+73)+"px"})
    $('#lmcslider').css({"left":(left+10)+"px", "top":(top+91)+"px"})
    $('#lmczo').css({"left":(left+10)+"px", "top":(top+237)+"px"})
    $('#lmczb').css({"left":(left+29)+"px", "top":(top+91)+"px"})

    d3.selectAll("#compass div").call (selection)-> 
      window.eventManager.setup('move_compass', selection, _)

    sliderElem = $("#lmczbg")[0]

    #zoom in/out
    d3.selectAll(".zoom_button").call (selection)-> 
      window.eventManager.setup('zoom_button', selection, _, sliderElem)

    #slider zoom
    d3.select("#lmczb").call (selection)-> 
      window.eventManager.setup('zoom_slider', selection, _, sliderElem)

