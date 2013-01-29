class window.FreehandElem extends window.TagElem
  mySelBoxColor = "darkred"
  mySelBoxSize = 6
  selectionColor = "#CC0000"
  selectionWidth = 2

  constructor: (strokeStyle, view) ->
    super(strokeStyle,view)
    @points = []
    
  toJSON: ->
    points: @points
    view: @view
    property: @property

  addPoint: (x_t, y_t) ->
    @updateBound(x_t, y_t)
    
    @points.push {
      x:x_t,
      y:y_t
    }

  isValidElem: ->
    @points.length > 1

  moveAll: (movePixel) ->
    i = 0

    while i < @points.length
      @points[i].x = @points[i].x + movePixel.mx
      @points[i].y = @points[i].y + movePixel.my
      i++

    @box.x += movePixel.mx
    @box.y += movePixel.my
