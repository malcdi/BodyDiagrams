class window.FreehandElem extends window.TagElem
  mySelBoxColor = "darkred"
  mySelBoxSize = 6
  selectionColor = "#CC0000"
  selectionWidth = 2

  constructor: (strokeStyle, view) ->
    super(strokeStyle,view)
    @points = []
    @type = 'hand'
  
  drawData: ->
    @points
    
  toJSON: ->
    points: @points.map (d)-> [d.x, d.y]
    view: @view
    type: @type
    property: @property

  updateBound: (x_t, y_t)->
    if x_t < @box.x_min
      @box.x_min = x_t
    else if x_t > @box.x_max
      @box.x_max = x_t

    if y_t < @box.y_min
      @box.y_min = y_t
    else if y_t > @box.y_max
      @box.y_max = y_t
    
  setAllPoints: (@points)->
    x_arr = @points.map (d)->d.x
    y_arr= @points.map (d)->d.y
    @box.x_min = d3.min(x_arr)
    @box.x_max = d3.min(x_arr)
    @box.y_min = d3.min(y_arr)
    @box.y_max = d3.min(y_arr)
    
  addPoint: (x_t, y_t) ->
    @updateBound(x_t, y_t)
    
    @points.push {
      x:x_t,
      y:y_t
    }
    
  isValidElem: ->
    @points.length > 3

  moveAll: (movePixel) ->
    super(movePixel)
    i = 0
    while i < @points.length
      @points[i].x = @points[i].x + movePixel.mx
      @points[i].y = @points[i].y + movePixel.my
      i++

