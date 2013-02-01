class window.RegionElem extends window.TagElem

  constructor: (strokeStyle, view) ->
    super(strokeStyle, view)
    @type = 'region'
    @origin_x =0
    @origin_y =0

  toJSON: ->
    rect: @getRectBound()
    view: @view
    type: @type
    property: @property

  isValidElem: ->
    (@box.x_max-@box.x_min)>2 and (@box.y_max-@box.y_min)>2

  drawData: ->
    @getRectBound()
    
  updateRegion:(pt)->
    if pt.x < @origin_x
      @box.x_max = @origin_x
      @box.x_min = pt.x
    else
      @box.x_max = pt.x

    if pt.y < @origin_y
      @box.y_max = @origin_y
      @box.y_min = pt.y
    else
      @box.y_max = pt.y
