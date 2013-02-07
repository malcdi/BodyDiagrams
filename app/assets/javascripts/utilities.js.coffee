window.colorSelector = (option) ->
  switch option
    when 1
      "#FEE0D2"
    when 2
      "#FEE0D2"
    when 3
      "#FCBBA1"
    when 4
      "#FC9272"
    when 5
      "#FB6A4A"
    when 6
      "#EF3B2C"
    when 7
      "#CB181D"
    when 8
      "#A50F15"
    when 9
      "#67000D"
    when 10
      "#67000D"
    when 'default'
      "#FCBBA1"
    when 'highlight'
      "steelblue"
    when 'fill'
      "#FCBBA1"

window.trackSVGTransforms = (tracker, svg) ->
  xform = svg.createSVGMatrix()
  getTransform = tracker.getTransform
  tracker.getTransform = ->
    xform

  scale = 1
  scale = tracker.scale
  tracker.scale = (sx, sy) ->
    xform = xform.scaleNonUniform(sx, sy)
    xform

  rotate = tracker.rotate
  tracker.rotate = (radians) ->
    xform = xform.rotate(radians * 180 / Math.PI)
    xform

  translate = tracker.translate
  tracker.translate = (dx, dy) ->
    xform = xform.translate(dx, dy)
    xform

  transform = tracker.transform
  tracker.transform = (a, b, c, d, e, f) ->
    m2 = svg.createSVGMatrix()
    m2.a = a
    m2.b = b
    m2.c = c
    m2.d = d
    m2.e = e
    m2.f = f
    xform = xform.multiply(m2)
    xform

  setTransform = tracker.setTransform
  tracker.setTransform = (a, b, c, d, e, f) ->
    xform.a = a
    xform.b = b
    xform.c = c
    xform.d = d
    xform.e = e
    xform.f = f
    xform

  setTransform = tracker.setTransform
  tracker.setTransformMat = (newmat) ->
    xform = newmat

  pt = svg.createSVGPoint()
  tracker.transformedPoint = (point) ->
    pt.x = point.x
    pt.y = point.y
    pt.matrixTransform xform.inverse()

  tracker.inverseTransformSize = (a) ->
    a*xform.a

  tracker.inverseTransformPoint = (point) ->
    pt.x = point.x
    pt.y = point.y
    pt.matrixTransform xform
