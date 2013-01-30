window.colorSelector = (option) ->
  switch option
    when 'default'
      "#FFB6C1"
    when 'highlight'
      "#996d73"

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