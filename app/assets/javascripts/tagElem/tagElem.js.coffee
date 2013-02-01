class window.TagElem
  selBoxPadding = 2

  constructor: (strokeStyle, view) ->
    @strokeStyle = strokeStyle or colorSelector('default')
    @box = {
      x_min:1000
      y_min:1000
      x_max:0
      y_max:0
    }
    @view = view
    @property = {}
    @frame = -1
    @sub = -1
    
  setIndex:(@frame, @sub)->

  setBound: (box)->
    @box.x_min = box.x
    @box.x_max = box.w + box.x
    @box.y_min = box.y
    @box.y_max = box.y + box.h 

  getRectBound:->
    {
      x:@box.x_min
      y:@box.y_min
      w:@box.x_max - @box.x_min
      h:@box.y_max - @box.y_min
    }
    
  getProperties: () ->
    return @property

  saveProperties: (properties) ->
    for k,v of properties
      @property[k] = v

  getView: ->
    @view

  contains: (mx, my) ->
    return false  if mx < @box.x_min - selBoxPadding or mx > @box.x_max + selBoxPadding
    return false  if my < @box.y_min - selBoxPadding or my > @box.y_max + selBoxPadding
    true

  moveAll:(movePixel)->
    @box.x_min += movePixel.mx
    @box.y_min += movePixel.my
    @box.x_max += movePixel.mx
    @box.y_max += movePixel.my