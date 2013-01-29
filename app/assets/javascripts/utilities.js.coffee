window.colorSelector = (severity) ->
  if severity is 0
    "#FFF5F0"
  else if severity is 1
    "#FEE0D2"
  else if severity is 2
    "#FFB6C1"
  else if severity is 3
    "#FFB6C1"
  else if severity is 4
    "#FB6A4A"
  else if severity is 5
    "#EF3B2C"
  else if severity is 6
    "#CB181D"
  else if severity is 7
    "#A50F15"
  else if severity is 8
    "#67000D"
  else if severity is "default"
    "#FFB6C1"

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

  pt = svg.createSVGPoint()
  tracker.transformedPoint = (point) ->
    pt.x = point.x
    pt.y = point.y
    pt.matrixTransform xform.inverse()
