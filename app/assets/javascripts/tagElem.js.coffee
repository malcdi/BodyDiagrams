class window.TagElem
  selBoxPadding = 2

  setStyle: (strokeStyle) ->
    @strokeStyle = strokeStyle

  getView: ->
    @view

  contains: (mx, my) ->
    return false  if mx < @x - selBoxPadding or mx > @x + @w + selBoxPadding
    return false  if my < @y - selBoxPadding or my > @y + @h + selBoxPadding
    true