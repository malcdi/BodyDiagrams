class window.RegionElem extends window.TagElem

  constructor: (strokeStyle, view) ->
    super(strokeStyle, view)
    @type = 'region'
    @origin_x =0
    @origin_y =0

  toJSON: ->
    rect:@getRectBound()

  setOrigin: (pt) ->
    @origin_x = pt.x
    @origin_y = pt.y
    @box.x_min =  @origin_x
    @box.y_min =  @origin_y

  isValidElem: ->
    true

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
