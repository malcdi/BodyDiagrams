class window.FreehandElem extends window.TagElem
  mySelBoxColor = "darkred"
  mySelBoxSize = 6
  selectionColor = "#CC0000"
  selectionWidth = 2

  constructor: (strokeStyle, view) ->
    
    # This is a very simple and unsafe constructor. 
    # All we're doing is checking if the values exist.
    @strokeStyle = strokeStyle or "#F89393"
    @points = []
    @view = view
    @x = 1000
    @y = 1000
    @w = 0
    @h = 0
    @property = {}

  getProperties: () ->
    return @property

  saveProperties: (properties) ->
    for k,v of properties
      @property[k] = v

  toJSON: ->
    points: @points
    view: @view

  addPoint: (x_t, y_t) ->
    if x_t < @x
      @x = x_t
    else @w = x_t - @x if x_t > @x + @w

    if y_t < @y
      @y = y_t
    else @h = y_t - @y  if y_t > @y + @h

    hash = {}
    hash.x = x_t
    hash.y = y_t
    @points.push hash

  isValidElem: ->
    @points.length > 1

  moveAll: (mx, my) ->
    i = 0

    while i < @points.length
      @points[i].x = @points[i].x + mx
      @points[i].y = @points[i].y + my
      i++
    @x += mx
    @y += my
