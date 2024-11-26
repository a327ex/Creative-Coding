collision = {}

function collision.point_circle(px, py, cx, cy, cr)
  return math.distance(px, py, cx, cy) <= cr
end

function collision.point_line(px, py, x1, y1, x2, y2)
  return mlib.segment.checkPoint(px, py, x1, y1, x2, y2)
end

function collision.point_polygon(px, py, vertices)
  return mlib.polygon.checkPoint(px, py, vertices)
end

function collision.point_rectangle(px, py, x, y, w, h)
  return px >= x - w/2 and px <= x + w/2 and py >= y - h/2 and py <= y + h/2
end

function collision.line_circle(x1, y1, x2, y2, cx, cy, cr)
  return mlib.circle.getSegmentIntersections(cx, cy, cr, x1, y1, x2, y2)
end

function collision.line_line(x1, y1, x2, y2, x3, y3, x4, y4)
  return mlib.segment.getIntersection(x1, y1, x2, y2, x3, y3, x4, y4)
end

function collision.line_polygon(x1, y1, x2, y2, vertices)
  return mlib.segment.getSegmentIntersection(x1, y1, x2, y2, vertices)
end

function collision.line_rectangle(x1, y1, x2, y2, rx, ry, rw, rh)
  return mlib.segment.getSegmentIntersection(x1, y1, x2, y2, math.to_rectangle_vertices(rx-rw/2, ry-rh/2, rx+rw/2, ry+rh/2))
end

function collision.circle_circle(c1x, c1y, c1r, c2x, c2y, c2r)
  return math.distance(c1x, c1y, c2x, c2y) <= c1r+c2r
end

function collision.circle_polygon(cx, cy, cr, vertices)
  local intersections = mlib.polygon.getCircleIntersection(cx, cy, cr, vertices)
  if not intersections then
    return mlib.polygon.isCircleCompletelyInside(cx, cy, cr, vertices) or mlib.circle.isPolygonCompletelyInside(cx, cy, cr, vertices)
  else
    return true
  end
end

function collision.circle_rectangle(cx, cy, cr, rx, ry, rw, rh)
  local px, py = collision.nearest_point_on_rectangle(cx, cy, rx, ry, rw, rh)
  return math.distance(cx, cy, px, py) <= cr
end

function collision.polygon_polygon(vertices_1, vertices_2)
  local intersections = mlib.polygon.getPolygonIntersection(vertices_1, vertices_2)
  if not intersections then
    return mlib.polygon.isPolygonCompletelyInside(vertices_1, vertices_2) or mlib.polygon.isPolygonCompletelyInside(vertices_2, vertices_1)
  else
    return true
  end
end

function collision.polygon_rectangle(vertices, rx, ry, rw, rh)
  return collision.polygon_polygon(vertices, math.to_rectangle_vertices(rx-rw/2, ry-rh/2, rx+rw/2, ry+rh/2))
end

function collision.rectangle_rectangle(x1, y1, w1, h1, x2, y2, w2, h2)
  local dx, dy = math.abs(x1 - x2), math.abs(y1 - y2)
  if dx > w1/2 + w2/2 then return false end
  if dy > h1/2 + h2/2 then return false end
  return true
end

function collision.nearest_point_on_rectangle(px, py, rx, ry, rw, rh)
  return math.clamp(px, rx - rw/2, rx + rw/2), math.clamp(py, ry - rh/2, ry + rh/2)
end
