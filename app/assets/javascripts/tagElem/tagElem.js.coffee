class window.TagElem
  selBoxPadding = 2

  constructor: (strokeStyle, view) ->
    @strokeStyle = strokeStyle or colorSelector('default')
    @box = {
      x:1000
      y:1000
      w:0
      h:0
    }
    @view = view
    @property = {}

  getProperties: () ->
    return @property

  saveProperties: (properties) ->
    for k,v of properties
      @property[k] = v

  getView: ->
    @view
    
  updateBound: (x_t, y_t)->
    if x_t < @box.x
      @box.x = x_t
    else @box.w = x_t - @box.x if x_t > @box.x + @box.w

    if y_t < @box.y
      @box.y = y_t
    else @box.h = y_t - @box.y  if y_t > @box.y + @box.h

  contains: (mx, my) ->
    return false  if mx < @box.x - selBoxPadding or mx > @box.x + @box.w + selBoxPadding
    return false  if my < @box.y - selBoxPadding or my > @box.y + @box.h + selBoxPadding
    true