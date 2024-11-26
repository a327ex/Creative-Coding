--[[
  Returns the angle of the vector.
  Examples:
    math.angle()      -> error, expects 2 numbers
    math.angle(1, 0)  -> 0
    math.angle(-1, 0) -> math.pi
    math.angle(0, 1)  -> math.pi/2
    math.angle(0, -1) -> -math.pi/2
]]--
function math.angle(x, y)
  return math.atan2(y, x)
end

--[[
  Returns the smallest difference between two angles.
  The direction of the difference tells which way you'd need to move from the first to the second angle.
  If you don't care about the direction then just math.abs it.
  Examples:
    math.angle_delta()                      -> error, expects 2 numbers
    math.angle_delta(0, 0)                  -> 0
    math.angle_delta(math.pi, math.pi/4)    -> -3*math.pi/4
    math.angle_delta(-math.pi/2, math.pi/4) -> 3*math.pi/4
    math.angle_delta(-math.pi, math.pi)     -> 0
    math.angle_delta(-math.pi, -math.pi/2)  -> math.pi/2
--]]
function math.angle_delta(a, b)
  local d = math.loop(a-b, 2*math.pi)
  if d > math.pi then d = d - 2*math.pi end
  return -d
end

--[[
  Returns -1 if the angle is on either left quadrants or 1 if its on either right quadrants.
  Examples:
  math.angle_to_horizontal(math.pi/4)    -> 1
  math.angle_to_horizontal(-math.pi/4)   -> 1
  math.angle_to_horizontal(-3*math.pi/4) -> -1
  math.angle_to_horizontal(3*math.pi/4)  -> -1
--]]
function math.angle_to_horizontal(r)
  r = math.loop(r, 2*math.pi)
  if r > math.pi/2 and r < 3*math.pi/2 then return -1
  elseif r >= 3*math.pi/2 or r <= math.pi/2 then return 1 end
end


--[[
  Returns the angle from point x1, y1 to point x2, y2
  Examples:
    math.angle_to_point()           -> error, expects 4 numbers
    math.angle_to_point(0, 0, 0, 0) -> 0
    math.angle_to_point(0, 0, 1, 1) -> math.pi/4
    math.angle_to_point(0, 0, 1, 0) -> 0
    math.angle_to_point(0, 0, 0, 1) -> math.pi/2
]]--
function math.angle_to_point(x1, y1, x2, y2)
  return math.atan2(y2 - y1, x2 - x1)
end

--[[
  Returns -1 if the angle is on either bottom quadrants and 1 if its on either top quadrants.
  Examples:
    math.angle_to_horizontal(math.pi/4)    -> -1
    math.angle_to_horizontal(-math.pi/4)   -> 1
    math.angle_to_horizontal(-3*math.pi/4) -> 1
    math.angle_to_horizontal(3*math.pi/4)  -> -1
--]]
function math.angle_to_vertical(r)
  r = math.loop(r, 2*math.pi)
  if r > 0 and r < math.pi then return -1
  elseif r >= math.pi and r <= 2*math.pi then return 1 end
end

--[[
  Given angle r and normal values nx, ny, returns the bounce angle.
  TODO: examples
--]]
function math.bounce(vx, vy, nx, ny)
  local dot = math.dot(vx, vy, nx, ny)
  return vx - 2*dot*nx, vy - 2*dot*ny
end

--[[
  Clamps value n between min and max.
  Examples:
    math.clamp()           -> error, expects a number
    math.clamp(2)          -> 1 -- default range is [0, 1]
    math.clamp(-4, 0, 10)  -> 0
    math.clamp(83, 0, 10)  -> 10
    math.clamp(0, -10, -4) -> -4
    math.clamp(5, 10, -10) -> 5
]]--
function math.clamp(n, min, max)
  local min, max = min or 0, max or 1
  if min > max then min, max = max, min end
  return math.min(math.max(n, min), max)
end

--[[
  Calculates a new velocity based on the previous velocity, acceleration, drag (damping), max_v and dt.
  This is taken directly from HaxeFlixel: https://github.com/HaxeFlixel/flixel/blob/dev/flixel/math/FlxVelocity.hx#L223.
]]--
function math.compute_velocity(v, a, drag, max_v, dt)
  if a ~= 0 then
    v = v + a*dt
  elseif drag ~= 0 then
    drag = drag*dt
    if v - drag > 0 then v = v - drag
    elseif v + drag < 0 then v = v + drag
    else v = 0 end
  end
  if v ~= 0 and max_v ~= 0 then
    if v > max_v then v = max_v
    elseif v < -max_v then v = -max_v end
  end
  return v
end

--[[
  Returns the 1D index of the given 2D coordinate with a grid of a given width.
  Examples:
    math.coordinate_to_index(1, 2, 10) -> 11
    math.coordinate_to_index(2, 1, 4) -> 2
    math.coordinate_to_index(3, 3, 7) -> 17
    math.coordinate_to_index(1, 5, 4) -> 17
    math.coordinate_to_index(4, 1, 4) -> 4
--]]
function math.coordinate_to_index(i, j, w)
  return i + (j-1)*w
end

--[[
  Framerate-independent damping of value v.
  p is the percentage distance covered to the target. A value of 0.9 means 90% will be covered, for instance.
  t is how much it will take until the distance covered is the one specified by p.
  Examples:
    math.damping()                    -> error, expects 4 numbers
    x = math.damping(0.9, 1, dt, x)   -> after 1 second, x's value will be its initial value times 0.9
    x = math.damping(0.5, 0.5, dt, x) -> after 0.5 seconds, x's value will be its initial value times 0.5
]]--
function math.damping(p, t, dt, v)
  return (v or 0)*((1-p)^(dt/t))
end

--[[
  Framerate-independent damping of values v and u.
  Uses math.damping internally, so everything there applies here.
  Examples:
    math.damping_2d()                              -> error, expects 5 numbers
    vx, vy = math.damping_2d(0.9, 1, dt, vx, vy)   -> after 1 second, vx and vy's values will be their initial values times 0.9
    vx, vy = math.damping_2d(0.5, 0.5, dt, vx, vy) -> after 0.5 seconds, vx and vy's values will be their initial values times 0.5
--]]
function math.damping_2d(p, t, dt, v, u)
  return math.damping(p, t, dt, v), math.damping(p, t, dt, u)
end

--[[
  Returns the squared distance between two points.
  TODO: examples
]]--
function math.distance(x1, y1, x2, y2)
  return math.sqrt((x2-x1)*(x2-x1) + (y2-y1)*(y2-y1))
end

--[[
  Returns the dot product between two points.
  TODO: examples
--]]
function math.dot(x1, y1, x2, y2)
  return x1*x2 + y1*y2
end

--[[
  Generates points in the area centered around x, y with size w, h, while ensuring each point has a minimum distance of rs from each other.
  Based on https://www.youtube.com/watch?v=7WcmyxyFO7o.
  TODO: examples
--]]
function math.generate_poisson_disc_sampled_points_2d(x, y, w, h, rs)
  local cell_size = rs/math.sqrt(2)
  local grid = object():grid(math.floor(w/cell_size), math.floor(h/cell_size), 0)
  local points = {}
  local spawn_points = {}

  local is_valid_point = function(x, y)
    if x >= 0 and x <= w and y >= 0 and y <= h then
      local cx, cy = math.floor(x/cell_size), math.floor(y/cell_size)
      local sx1, sx2 = math.max(1, cx - 2), math.min(cx + 2, grid.grid_w)
      local sy1, sy2 = math.max(1, cy - 2), math.min(cy + 2, grid.grid_h)
      for i = sx1, sx2 do
        for j = sy1, sy2 do
          local point_index = grid:grid_get(i, j)
          if point_index ~= 0 then
            local d = math.distance(x, y, points[point_index].x, points[point_index].y)
            if d < rs then
              return false
            end
          end
        end
      end
      return true
    end
  end

  table.insert(spawn_points, {an:random_float(0, w), an:random_float(0, h)})
  while #spawn_points > 0 do
    local spawn_index = an:random_int(1, #spawn_points)
    local spawn_center = spawn_points[spawn_index]
    local accepted = false
    for i = 1, 30 do
      local r = an:random_angle()
      local d = an:random_float(rs, 2*rs)
      local cx, cy = spawn_center[1] + d*math.cos(r), spawn_center[2] + d*math.sin(r)
      if is_valid_point(cx, cy) and grid:grid_get(math.floor(cx/cell_size), math.floor(cy/cell_size)) == 0 then
        table.insert(points, {x = cx, y = cy})
        table.insert(spawn_points, {cx, cy})
        grid:grid_set(math.floor(cx/cell_size), math.floor(cy/cell_size), #points)
        accepted = true
        break
      end
    end
    if not accepted then
      table.remove(spawn_points, spawn_index)
    end
  end

  for _, point in ipairs(points) do
    point.x = point.x + (x - w/2) - rs/3
    point.y = point.y + (y - h/2) - rs/3
  end
  return points
end

--[[
  Returns the polygon's center.
  TODO: examples
--]]
function math.get_polygon_center(vertices)
  local xs, ys = 0, 0
  for i = 1, #vertices, 2 do
    local x, y = vertices[i], vertices[i+1]
    xs = xs + x
    ys = ys + y
  end
  xs = xs/(#vertices/2)
  ys = ys/(#vertices/2)
  return xs, ys
end

--[[
  Returns the polygon's visual center.
  The visual center is the center of the polygon that correctly draws its bounding box around it using that value as the rectangle's center.
  The rectangle's proper center, which is the average of all its points, will often differ from the visual center if the polygon isn't very symmetrical.
  TODO: examples
--]]
function math.get_polygon_visual_center(vertices)
  local min_x, min_y, max_x, max_y = 1e10, 1e10, -1e10, -1e10
  for i = 1, #vertices, 2 do
    if vertices[i] < min_x then min_x = vertices[i] end
    if vertices[i] > max_x then max_x = vertices[i] end
    if vertices[i+1] < min_y then min_y = vertices[i+1] end
    if vertices[i+1] > max_y then max_y = vertices[i+1] end
  end
  return (min_x + max_x)/2, (min_y + max_y)/2
end

--[[
  Returns the polygon's width and height (its bounding box).
  TODO: examples
]]--
function math.get_polygon_size(vertices)
  local min_x, min_y, max_x, max_y = 1e10, 1e10, -1e10, -1e10
  for i = 1, #vertices, 2 do
    if vertices[i] < min_x then min_x = vertices[i] end
    if vertices[i] > max_x then max_x = vertices[i] end
    if vertices[i+1] < min_y then min_y = vertices[i+1] end
    if vertices[i+1] > max_y then max_y = vertices[i+1] end
  end
  return max_x - min_x, max_y - min_y
end

--[[
  Returns the 2D coordinate of a given index with a grid of a given width.
  Examples:
    math.index_to_coordinate(11, 10) -> 1, 2
    math.index_to_coordinate(2, 4) -> 2, 1
    math.index_to_coordinate(17, 7) -> 3, 3
    math.index_to_coordinate(17, 4) -> 1, 5
    math.index_to_coordinate(4, 4) -> 4, 1
--]]
function math.index_to_coordinate(n, w)
  local i, j = n % w, math.ceil(n/w)
  if i == 0 then i = w end
  return i, j
end

--[[
  Returns the length of x, y.
  Examples:
    math.length()     -> error, expects 2 numbers
    math.length(0, 0) -> 0
    math.length(1, 0) -> 1
    math.length(1, 1) -> math.sqrt(2)
    math.length(2, 2) -> math.sqrt(8)
]]--
function math.length(x, y)
  return math.sqrt(x*x + y*y)
end

--[[
  Returns the squared length of x, y.
  Examples:
    math.squared_length()     -> error, expects 2 numbers
    math.squared_length(0, 0) -> 0
    math.squared_length(1, 0) -> 1
    math.squared_length(1, 1) -> 2
    math.squared_length(2, 2) -> 8
]]--
function math.length_squared(x, y)
  return x*x + y*y
end

--[[
  Linearly interpolates between src and dst with lerp value of t.
  t is clamped to the range of [0, 1].
  You can match this function with any of the easing functions at the end of this file for a non-linear curve.
  Examples:
    math.lerp()                        -> error, expects 3 numbers
    math.lerp(0, 0, 5)                 -> 0
    math.lerp(1, 0, 5)                 -> 5
    math.lerp(0.5, 0, 5)               -> 2.5
    math.lerp(math.expo_in(0.5), 0, 5) -> 0.15625, t here is using an exponential curve instead of a linear one
]]--
function math.lerp(t, src, dst)
  return src*(1-t) + dst*t
end

--[[
  Same as lerp except it can be used with angles while wrapping correctly and keeping values in the [0, 2*math.pi] range.
]]--
function math.lerp_angle(t, src, dst)
  local dt = math.loop(dst - src, 2*math.pi)
  if dt > math.pi then dt = dt - 2*math.pi end
  return src + dt*math.clamp(t, 0, 1)
end

--[[
  Framerate-independent linear interporation between src and dst.
  p is the percentage distance covered to the target. A value of 0.9 means 90% will be covered, for instance.
  t is how much it will take until the distance covered is the one specified by p.
  Examples:
    math.lerp_dt()                         -> error, expects 5 numbers
    x = math.lerp_dt(0.9, 1, dt, x, 100)   -> covers 90% of the distance between @x and 100 per second
    x = math.lerp_dt(0.5, 0.5, dt, x, 100) -> covers 50% of the distance between @x and 100 per 0.5 seconds
]]--
function math.lerp_dt(p, t, dt, src, dst)
  return math.lerp(1 - (1-p)^(dt/t), src, dst)
end

--[[
  Same as lerp_dt except it can be used with angles while wrapping correctly and keeping values in the [0, 2*math.pi] range.
]]--
function math.lerp_angle_dt(p, t, dt, src, dst)
  return math.lerp_angle(1 - (1-p)^(dt/t), src, dst)
end

--[[
  Returns the given x, y values truncated by max.
  max is the maximum length of the vector represented by x, y, not the max length of each individual component.
  Examples:
    math.limit() -> error, expects 3 numbers
    math.limit(0, 0, 1)     -> 0, 0
    math.limit(1, 0, 1)     -> 1, 0
    math.limit(1, 1, 1)     -> 1/math.sqrt(2), 1/math.sqrt(2)
    math.limit(2, 2, 1)     -> 1/math.sqrt(2), 1/math.sqrt(2)
    math.limit(50, 35, 100) -> 50, 35
    math.limit(50, 35, 50)  -> 40.961596025952, 28.673117218166
]]--
function math.limit(x, y, max)
  local s = max*(max/math.length_squared(x, y))
  s = (s > 1 and 1) or math.sqrt(s)
  return x*s, y*s
end

--[[
  Loops value t such that it is never higher than length and never lower than 0.
  This is especially useful for keeping angles, for instance, confined to the [0, 2*math.pi] range.
  Examples:
    math.loop()                     -> error, expects 2 numbers
    math.loop(1, 0)                 -> 0
    math.loop(1, 0.5)               -> 0
    math.loop(2, 1.5)              -> 0.5
    math.loop(3*math.pi, 2*math.pi) -> math.pi
]]--
function math.loop(t, length)
  return math.clamp(t - math.floor(t/length)*length, 0, length)
end

--[[
  Generates a perlin noise value in 1-4 dimensions.
  See a thorough explanation of it here https://natureofcode.com/random/#a-smoother-approach-with-perlin-noise.
  The returned value will always be the same, given the same arguments, and it's always in the [0, 1] range.
  Smaller offset differences (i.e. 0.01) between calls will result in a smoother curve, larger ones will make it more jagged.
  Examples:
    math.perlin_noise()     -> error, expects at least 1 number
    math.perlin_noise(1)    -> 0.5
    math.perlin_noise(1.01) -> 0.50094182413411
    math.perlin_noise(1.02) -> 0.50189415463731
    math.perlin_noise(5.64) -> 0.27784960404685
]]--
function math.perlin_noise(x, y, z, w)
  return love.math.perlinNoise(x, y, z, w)
end

--[[
  Generates a simplex noise value in 1-4 dimensions.
  See a thorough explanation of it here https://natureofcode.com/random/#a-smoother-approach-with-perlin-noise.
  The returned value will always be the same, given the same arguments, and it's always in the [0, 1] range.
  Smaller offset differences (i.e. 0.01) between calls will result in a smoother curve, larger ones will make it more jagged.
  Examples:
    math.simplex_noise()     -> error, expects at least 1 number
    math.simplex_noise(1)    -> 0.5
    math.simplex_noise(1.01) -> 0.50197427144449
    math.simplex_noise(1.02) -> 0.50394463571858
    math.simplex_noise(5.64) -> 0.21390468850046
]]--
function math.simplex_noise(x, y, z, w)
  return love.math.simplexNoise(x, y, z, w)
end


--[[
  Returns the normalized values of x, y.
  Examples:
    math.normalize() -> error, expects 2 numbers
    math.normalize(0, 0)   -> 0, 0
    math.normalize(1, 0)   -> 1, 0
    math.normalize(0, 100) -> 0, 1
    math.normalize(1, 1)   -> 1/math.sqrt(2), 1/math.sqrt(2)
]]--
function math.normalize(x, y)
  if math.abs(x) < 0.0001 and math.abs(y) < 0.0001 then return x, y end
  local l = math.length(x, y)
  return x/l, y/l
end

--[[
  Remaps value n using its previous range of old_min, old_max into the new range new_min, new_max.
  Examples:
    math.remap() -> error, expects 5 numbers
    math.remap(10, 0, 20, 0, 1)       -> 0.5 because 10 is 50% of [0, 20] and thus 0.5 is 50% of [0, 1]
    math.remap(3, 0, 3, 0, 100)       -> 100
    math.remap(2.5, -5, 5, -100, 100) -> 50
    math.remap(-10, 0, 10, 0, 1000)   -> -1000
]]--
function math.remap(n, old_min, old_max, new_min, new_max)
  return ((n - old_min)/(old_max - old_min))*(new_max - new_min) + new_min
end

--[[
  Rotates the point by r angle with ox, oy as the pivot.
  TODO: examples
]]--
function math.rotate_point(x, y, r, ox, oy)
  return x*math.cos(r) - y*math.sin(r) + ox - ox*math.cos(r) + oy*math.sin(r), x*math.sin(r) + y*math.cos(r) + oy - oy*math.cos(r) - ox*math.sin(r)
end

--[[
  Rounds value n to p digits of precision.
  Examples:
    math.round() -> error, expects 1 number
    math.round(45.321)            -> 45
    math.round(10.94, 1)          -> 10.9
    math.round(101.9157289403, 5) -> 101.91572
]]--
function math.round(n, p)
  local p = p or 0
  local m = 10^p
  return math.floor(n*m+0.5)/m
end

--[[
  Returns the sign of value n.
  Examples:
    math.sign()    -> 0
    math.sign(10)  -> 1
    math.sign(-10) -> -1
    math.sign(0)   -> 0
]]--
function math.sign(n)
  if n > 0 then return 1
  elseif n < 0 then return -1
  else return 0 end
end

--[[
  Floors value v to the closest number divisible by n.
  Examples:
    math.snap()       -> error, expects 2 numbers
    math.snap(15, 16) -> 0
    math.snap(17, 16) -> 16
    math.snap(13, 4)  -> 12
--]]
function math.snap(v, n)
  return math.round(v/n, 0)*n
end

--[[
  Snaps value v to the closest number divisible by n and then centers it.
  This is useful when doing calculations for grids where each cell would be of size n, for instance.
  Examples:
    math.snap_center()       -> error, expects 2 numbers
    math.snap_center(12, 16) -> 8
    math.snap_center(17, 16) -> 24
    math.snap_center(12, 12) -> 6
    math.snap_center(13, 12) -> 18
--]]
function math.snap_center(v, n)
  return math.ceil(v/n)*n - n/2
end

--[[
  Decomposes a simple convex or concave polygon into triangles.
  TODO: example
--]]
function math.triangulate_polygon(vertices)
  return love.math.triangulate(vertices)
end

--[[
  Returns rectangle vertices based on top-left and bottom-right coordinates in clockwise order.
  Example:
    math.to_rectangle_vertices(0, 0, 40, 40) -> returns vertices for a rectangle centered on 20, 20
                                                or more explicitly: {0, 0, 40, 0, 40, 40, 0, 40}
--]]
function math.to_rectangle_vertices(x1, y1, x2, y2)
  return {x1, y1, x2, y1, x2, y2, x1, y2}
end

--[[
  Tweening functions are defined below, they are meant to be used primarily with timer_tween.
  Although they can be used with anything that needs to transform a [0, 1] number into another [0, 1] number curved differently.
]]--
PI = math.pi
PI2 = math.pi/2
LN2 = math.log(2)
LN210 = 10*math.log(2)

function math.linear(t)
  return t
end

function math.sine_in(t)
  if t == 0 then return 0
  elseif t == 1 then return 1
  else return 1 - math.cos(t*PI2) end
end

function math.sine_out(t)
  if t == 0 then return 0
  elseif t == 1 then return 1
  else return math.sin(t*PI2) end
end

function math.sine_in_out(t)
  if t == 0 then return 0
  elseif t == 1 then return 1
  else return -0.5*(math.cos(t*PI) - 1) end
end

function math.sine_out_in(t)
  if t == 0 then return 0
  elseif t == 1 then return 1
  elseif t < 0.5 then return 0.5*math.sin((t*2)*PI2)
  else return -0.5*math.cos((t*2-1)*PI2) + 1 end
end

function math.quad_in(t)
  return t*t
end

function math.quad_out(t)
  return -t*(t-2)
end

function math.quad_in_out(t)
  if t < 0.5 then
    return 2*t*t
  else
    t = t - 1
    return -2*t*t + 1
  end
end

function math.quad_out_in(t)
  if t < 0.5 then
    t = t*2
    return -0.5*t*(t-2)
  else
    t = t*2 - 1
    return 0.5*t*t + 0.5
  end
end

function math.cubic_in(t)
  return t*t*t
end

function math.cubic_out(t)
  t = t - 1
  return t*t*t + 1
end

function math.cubic_in_out(t)
  t = t*2
  if t < 1 then
    return 0.5*t*t*t
  else
    t = t - 2
    return 0.5*(t*t*t + 2)
  end
end

function math.cubic_out_in(t)
  t = t*2 - 1
  return 0.5*(t*t*t + 1)
end

function math.quart_in(t)
  return t*t*t*t
end

function math.quart_out(t)
  t = t - 1
  t = t*t
  return 1 - t*t
end

function math.quart_in_out(t)
  t = t*2
  if t < 1 then
    return 0.5*t*t*t*t
  else
    t = t - 2
    t = t*t
    return -0.5*(t*t - 2)
  end
end

function math.quart_out_in(t)
  if t < 0.5 then
    t = t*2 - 1
    t = t*t
    return -0.5*t*t + 0.5
  else
    t = t*2 - 1
    t = t*t
    return 0.5*t*t + 0.5
  end
end

function math.quint_in(t)
  return t*t*t*t*t
end

function math.quint_out(t)
  t = t - 1
  return t*t*t*t*t + 1
end

function math.quint_in_out(t)
  t = t*2
  if t < 1 then
    return 0.5*t*t*t*t*t
  else
    t = t - 2
    return 0.5*t*t*t*t*t + 1
  end
end

function math.quint_out_in(t)
  t = t*2 - 1
  return 0.5*(t*t*t*t*t + 1)
end

function math.expo_in(t)
  if t == 0 then return 0
  else return math.exp(LN210*(t - 1)) end
end

function math.expo_out(t)
  if t == 1 then return 1
  else return 1 - math.exp(-LN210*t) end
end

function math.expo_in_out(t)
  if t == 0 then return 0
  elseif t == 1 then return 1 end
  t = t*2
  if t < 1 then return 0.5*math.exp(LN210*(t - 1))
  else return 0.5*(2 - math.exp(-LN210*(t - 1))) end
end

function math.expo_out_in(t)
  if t < 0.5 then return 0.5*(1 - math.exp(-20*LN2*t))
  elseif t == 0.5 then return 0.5
  else return 0.5*(math.exp(20*LN2*(t - 1)) + 1) end
end

function math.circ_in(t)
  if t < -1 or t > 1 then return 0
  else return 1 - math.sqrt(1 - t*t) end
end

function math.circ_out(t)
  if t < 0 or t > 2 then return 0
  else return math.sqrt(t*(2 - t)) end
end

function math.circ_in_out(t)
  if t < -0.5 or t > 1.5 then return 0.5
  else
    t = t*2
    if t < 1 then return -0.5*(math.sqrt(1 - t*t) - 1)
    else
      t = t - 2
      return 0.5*(math.sqrt(1 - t*t) + 1)
    end
  end
end

function math.circ_out_in(t)
  if t < 0 then return 0
  elseif t > 1 then return 1
  elseif t < 0.5 then
    t = t*2 - 1
    return 0.5*math.sqrt(1 - t*t)
  else
    t = t*2 - 1
    return -0.5*((math.sqrt(1 - t*t) - 1) - 1)
  end
end

function math.bounce_in(t)
  t = 1 - t
  if t < 1/2.75 then return 1 - (7.5625*t*t)
  elseif t < 2/2.75 then
    t = t - 1.5/2.75
    return 1 - (7.5625*t*t + 0.75)
  elseif t < 2.5/2.75 then
    t = t - 2.25/2.75
    return 1 - (7.5625*t*t + 0.9375)
  else
    t = t - 2.625/2.75
    return 1 - (7.5625*t*t + 0.984375)
  end
end

function math.bounce_out(t)
  if t < 1/2.75 then return 7.5625*t*t
  elseif t < 2/2.75 then
    t = t - 1.5/2.75
    return 7.5625*t*t + 0.75
  elseif t < 2.5/2.75 then
    t = t - 2.25/2.75
    return 7.5625*t*t + 0.9375
  else
    t = t - 2.625/2.75
    return 7.5625*t*t + 0.984375
  end
end

function math.bounce_in_out(t)
  if t < 0.5 then
    t = 1 - t*2
    if t < 1/2.75 then return (1 - (7.5625*t*t))*0.5
    elseif t < 2/2.75 then
      t = t - 1.5/2.75
      return (1 - (7.5625*t*t + 0.75))*0.5
    elseif t < 2.5/2.75 then
      t = t - 2.25/2.75
      return (1 - (7.5625*t*t + 0.9375))*0.5
    else
      t = t - 2.625/2.75
      return (1 - (7.5625*t*t + 0.984375))*0.5
    end
  else
    t = t*2 - 1
    if t < 1/2.75 then return (7.5625*t*t)*0.5 + 0.5
    elseif t < 2/2.75 then
      t = t - 1.5/2.75
      return (7.5625*t*t + 0.75)*0.5 + 0.5
    elseif t < 2.5/2.75 then
      t = t - 2.25/2.75
      return (7.5625*t*t + 0.9375)*0.5 + 0.5
    else
      t = t - 2.625/2.75
      return (7.5625*t*t + 0.984375)*0.5 + 0.5
    end
  end
end

function math.bounce_out_in(t)
  if t < 0.5 then
    t = t*2
    if t < 1/2.75 then return (7.5625*t*t)*0.5
    elseif t < 2/2.75 then
      t = t - 1.5/2.75
      return (7.5625*t*t + 0.75)*0.5
    elseif t < 2.5/2.75 then
      t = t - 2.25/2.75
      return (7.5625*t*t + 0.9375)*0.5
    else
      t = t - 2.625/2.75
      return (7.5625*t*t + 0.984375)*0.5
    end
  else
    t = 1 - (t*2 - 1)
    if t < 1/2.75 then return 0.5 - (7.5625*t*t)*0.5 + 0.5
    elseif t < 2/2.75 then
      t = t - 1.5/2.75
      return 0.5 - (7.5625*t*t + 0.75)*0.5 + 0.5
    elseif t < 2.5/2.75 then
      t = t - 2.25/2.75
      return 0.5 - (7.5625*t*t + 0.9375)*0.5 + 0.5
    else
      t = t - 2.625/2.75
      return 0.5 - (7.5625*t*t + 0.984375)*0.5 + 0.5
    end
  end
end

local overshoot = 1.70158
function math.back_in(t)
  if t == 0 then return 0
  elseif t == 1 then return 1
  else return t*t*((overshoot + 1)*t - overshoot) end
end

function math.back_out(t)
  if t == 0 then return 0
  elseif t == 1 then return 1
  else
    t = t - 1
    return t*t*((overshoot + 1)*t + overshoot) + 1
  end
end

function math.back_in_out(t)
  if t == 0 then return 0
  elseif t == 1 then return 1
  else
    t = t*2
    if t < 1 then return 0.5*(t*t*(((overshoot*1.525) + 1)*t - overshoot*1.525))
    else
      t = t - 2
      return 0.5*(t*t*(((overshoot*1.525) + 1)*t + overshoot*1.525) + 2)
    end
  end
end

function math.back_out_in(t)
  if t == 0 then return 0
  elseif t == 1 then return 1
  elseif t < 0.5 then
    t = t*2 - 1
    return 0.5*(t*t*((overshoot + 1)*t + overshoot) + 1)
  else
    t = t*2 - 1
    return 0.5*t*t*((overshoot + 1)*t - overshoot) + 0.5
  end
end

local amplitude = 1
local period = 0.0003
function math.elastic_in(t)
  if t == 0 then return 0
  elseif t == 1 then return 1
  else
    t = t - 1
    return -(amplitude*math.exp(LN210*t)*math.sin((t*0.001 - period/4)*(2*PI)/period))
  end
end

function math.elastic_out(t)
  if t == 0 then return 0
  elseif t == 1 then return 1
  else return math.exp(-LN210*t)*math.sin((t*0.001 - period/4)*(2*PI)/period) + 1 end
end

function math.elastic_in_out(t)
  if t == 0 then return 0
  elseif t == 1 then return 1
  else
    t = t*2
    if t < 1 then
      t = t - 1
      return -0.5*(amplitude*math.exp(LN210*t)*math.sin((t*0.001 - period/4)*(2*PI)/period))
    else
      t = t - 1
      return amplitude*math.exp(-LN210*t)*math.sin((t*0.001 - period/4)*(2*PI)/period)*0.5 + 1
    end
  end
end

function math.elastic_out_in(t)
  if t < 0.5 then
    t = t*2
    if t == 0 then return 0
    else return (amplitude/2)*math.exp(-LN210*t)*math.sin((t*0.001 - period/4)*(2*PI)/period) + 0.5 end
  else
    if t == 0.5 then return 0.5
    elseif t == 1 then return 1
    else
      t = t*2 - 1
      t = t - 1
      return -((amplitude/2)*math.exp(LN210*t)*math.sin((t*0.001 - period/4)*(2*PI)/period)) + 0.5
    end
  end
end
