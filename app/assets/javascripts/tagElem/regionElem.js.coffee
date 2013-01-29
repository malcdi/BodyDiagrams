class window.RegionElem extends window.TagElem

  constructor: (x, y, w, h, fill) ->
  
    # This is a very simple and unsafe constructor. 
    # All we're doing is checking if the values exist.
    # "x || 0" just means "if there is a value for x, use that. Otherwise use 0."
    @x = x or 0
    @y = y or 0
    @w = w or 0
    @h = h or 0
    @fill = fill or "#AAAAAA"

  toJSON: ->
    origin_x: @x
    origin_y: @y
    height: @h
    width: @w

  transform: (x, y, scale) ->
    @x = @x / scale + x
    @y = @y / scale + y
    @w = @w / scale
    @h = @h / scale

  draw: (ctx, thisElemOnSelect, selectionHandles) ->
    ctx.fillStyle = "#AAAAAA"
    ctx.globalAlpha = 0.1
    ctx.fillRect @x, @y, @w, @h
    if thisElemOnSelect
      ctx.globalAlpha = 1.0
      ctx.strokeStyle = "#AAAAAA"
      ctx.lineWidth = selectionWidth
      ctx.strokeRect @x, @y, @w, @h
      half = mySelBoxSize / 2

  setCoordinates: (minX, minY, maxX, maxY) ->
    @x = minX
    @y = minY
    @w = maxX - minX
    @h = maxY - minY

  contains: (mx, my) ->
    selBoxPadding = 2
    return false  if mx < @x - selBoxPadding or mx > @x + @w + selBoxPadding
    return false  if my < @y - selBoxPadding or my > @y + @h + selBoxPadding
    true
