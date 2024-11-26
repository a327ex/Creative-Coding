--[[
  The collider module is a mix of a box2d body + fixture + shape. It works in conjunction with the physics_world module.
  This should be used whenever there's a need for collision detection _and_ resolution.
  A collider receives several arguments:
    physics_tag - can be any of the tags set with "physics_world_set_physics_tags".
    body_type   - can be either 'static', 'dynamic' or 'kinematic', see https://love2d.org/wiki/BodyType.
    shape_type and its attributes can be:
      'rectangle', width, height
      'circle', radius
      'polygon', vertices
      'chain', vertices, loop
]]--
collider = class:class_new()
function collider:collider(physics_tag, body_type, shape_type, a, b, c, d)
  self.tags.collider = true
  self.physics_tag = physics_tag
  self.body_type = body_type or 'dynamic'
  self.shape_type = shape_type

  if self.shape_type == 'rectangle' then
    self.w, self.h = a, b
    self.body = love.physics.newBody(an.world, self.x, self.y, self.body_type)
    self.shape = love.physics.newRectangleShape(self.body, self.w, self.h)
    self.sensor = love.physics.newRectangleShape(self.body, self.w, self.h)
  elseif self.shape_type == 'circle' then
    self.rs = a
    self.w, self.h = 2*self.rs, 2*self.rs
    self.body = love.physics.newBody(an.world, self.x, self.y, self.body_type)
    self.shape = love.physics.newCircleShape(self.body, self.rs)
    self.sensor = love.physics.newCircleShape(self.body, self.rs)
  elseif self.shape_type == 'polygon' then
    self.vertices = a
    self.w, self.h = math.get_polygon_size(self.vertices)
    self.body = love.physics.newBody(an.world, 0, 0, self.body_type)
    if #self.vertices > 16 then
      self.shapes = {}
      self.sensors = {}
      for _, triangle in ipairs(love.math.triangulate(self.vertices)) do
        table.insert(self.shapes, love.physics.newPolygonShape(self.body, triangle))
        table.insert(self.sensors, love.physics.newPolygonShape(self.body, triangle))
      end
    else
      self.shape = love.physics.newPolygonShape(self.body, self.vertices)
      self.sensor = love.physics.newPolygonShape(self.body, self.vertices)
    end
    self.body:setPosition(self.x or 0, self.y or 0)
  elseif self.shape_type == 'chain' then
    self.vertices, self.loop = a, b
    self.w, self.h = math.get_polygon_size(self.vertices)
    self.body = love.physics.newBody(an.world, 0, 0, self.body_type)
    self.shape = love.physics.newChainShape(self.body, self.loop, self.vertices)
    self.sensor = love.physics.newChainShape(self.body, self.loop, self.vertices)
    self.body:setPosition(self.x or 0, self.y or 0)
  end
  if self.shapes and self.sensors then
    for _, shape in ipairs(self.shapes) do
      shape:setUserData(self)
      shape:setCategory(an.collision_tags[self.physics_tag].category)
      shape:setMask(unpack(an.collision_tags[self.physics_tag].masks))
    end
    for _, sensor in ipairs(self.sensors) do
      sensor:setUserData(self)
      sensor:setSensor(true)
    end
  else
    self.shape:setUserData(self)
    self.shape:setCategory(an.collision_tags[self.physics_tag].category)
    self.shape:setMask(unpack(an.collision_tags[self.physics_tag].masks))
    self.sensor:setUserData(self)
    self.sensor:setSensor(true)
  end
  return self
end

--[[
  Draws the collider.
  This should be used for debug purposes primarily, however you can also copy the code here and change it to fit your game.
  Example:
    game = object():layer()
    self:collider_draw(game, an.colors.white[0])    -> draws the collider as a white filled shape
    self:collider_draw(game, an.colors.white[0], 2) -> draws the collider as a white unfilled shape with line width of 2
]]--
function collider:collider_draw(layer, color, line_width)
  local color = color or an.colors.white[0]
  if self.shape_type == 'rectangle' or self.shape_type == 'polygon' then
    if self.shapes then
      for _, shape in ipairs(self.shapes) do
        layer:polygon({self.body:getWorldPoints(shape:getPoints())}, color, line_width)
      end
    else
      layer:polygon({self.body:getWorldPoints(self.shape:getPoints())}, color, line_width)
    end
  elseif self.shape_type == 'circle' then
    x, y = self.body:getWorldCenter()
    rs = self.shape:getRadius()
    layer:circle(x, y, rs, color, line_width)
  elseif self.shape_type == 'chain' then
    local points = {self.body:getWorldPoints(self.shape:getPoints())}
    for i = 1, #points-2, 2 do
      layer:line(points[i], points[i+1], points[i+2], points[i+3], color, line_width)
      if self.loop and i == #points-2 then
        layer:line(points[i], points[i+1], points[1], points[2], color, line_width)
      end
    end
  end
end

--[[
  Destroys the collider. This destroys all fixtures, shapes and bodies that represent it.
  This is automatically called at the end of the frame for group objects that have their self.dead attribute set to true.
  If you're not using groups then you must call this manually whenever the object is killed, otherwise you'll leak memory.
]]--
function collider:collider_destroy()
  if self.body then
    if self.sensors then
      for _, sensor in ipairs(self.sensors) do
        sensor:setUserData(nil)
        sensor:destroy()
        sensor:release()
      end
      self.sensors = nil
    else
      if self.sensor then self.sensor:setUserData(nil) end
      if self.sensor then
        self.sensor:destroy()
        self.sensor:release()
      end
      self.sensor = nil
    end
    if self.shapes then
      for _, shape in ipairs(self.shapes) do
        shape:setUserData(nil)
        shape:destroy()
        shape:release()
      end
      self.shapes = nil
    else
      self.shape:setUserData(nil)
      self.shape:destroy()
      self.shape:release()
      self.shape = nil
    end
    self.body:destroy()
    self.body:release()
    self.body = nil
  end
end

--[[
  Updates the self.x, self.y and self.r attributes of this collider to match the physics body's.
  This should generally be called at the start of an object's update function to update the object's position and rotation
  based on the results from the physics engine's update, since that happens right before groups are updated.
  However, another common way to use colliders is to "lead" the physics engine body with your own object's variables for
  certain tasks, in which case some judgement will be necessary on whether to call this function or not.
  Example:
    self:collider_update_transform()
]]--
function collider:collider_update_transform()
  self.x, self.y = self.body:getPosition()
  self.r = self.body:getAngle()
end

--[[
  Same as "collider_update_position_and_angle" but only updates this object's self.x, self.y attributes.
  Example:
    self:collider_update_position()
]]--
function collider:collider_update_position()
  self.x, self.y = self.body:getPosition()
end

--[[
  Sets the collider's position. In general you should use self.:collider_set_velocity for movement instead of teleporting the object around.
  However this is here because in some cases it just works better to teleport the object.
  This call doesn't update the object's self.x and self.y variable, call self.:collider_update_position for that.
  Example:
    self:collider_set_position(0, 0)
]]--
function collider:collider_set_position(x, y)
  self.body:setPosition(x, y)
end

--[[
  Applies a continuous amount of force to the collider.
  This should generally be called over multiple frames.
  Example:
    self:collider_apply_force(100*math.cos(angle), 100*math.sin(angle))
]]--
function collider:collider_apply_force(fx, fy, x, y)
  local x, y = x or self.x, y or self.y
  self.body:applyForce(fx, fy, x, y)
end

--[[
  APplies an instantaneous amount of angular force to the collider.
  This should generally be called once on some event, and not every frame.
  Example:
    self:collider_apply_angular_impulse(8*math.pi)
--]]
function collider:collider_apply_angular_impulse(f)
  self.body:applyAngularImpulse(f)
end

--[[
  Applies an instantaneous amount of force to the collider.
  This should generally be called once on some event, and not every frame.
  Example:
    self:collider_apply_impulse(100*math.cos(angle), 100*math.sin(angle))
]]--
function collider:collider_apply_impulse(fx, fy, x, y)
  local x, y = x or self.x, y or self.y
  self.body:applyLinearImpulse(fx, fy, x, y)
end

--[[
  Set the collider's angle.
  If "collider_set_fixed_rotation" is set to true then this will do nothing.
  Example:
    self:collider_set_angle(math.pi/4)
]]--
function collider:collider_set_angle(v)
  self.body:setAngle(v)
end

--[[
  Sets the collider's angular damping.
  The higher this value, the more the collider will resist rotation and the faster it will stop rotating after angular forces are applied to it.
  Example:
    self:collider_set_angular_damping(10)
--]]
function collider:collider_set_angular_damping(v)
  self.body:setAngularDamping(v)
end

--[[
  Sets the collider as a bullet.
  Bullets will collide and generate collision responses regardless of their velocity, despite being more expensive to compute.
  Example:
    self:collider_set_bullet(true)
]]--
function collider:collider_set_bullet(v)
  self.body:setBullet(v)
end

--[[
  Sets the collider's damping. This is a value from 0 to infinity.
  The higher this value, the more the collider resists movement and the faster it stops moving after forces are applied to it.
  Example:
    self:collider_set_damping(10)
]]--
function collider:collider_set_damping(v)
  self.body:setLinearDamping(v)
end

--[[
  Sets the collider to have fixed rotation.
  When box2d objects don't have fixed rotation, whenever they collide with other objects they will rotate around depending on
  where the collision happened. Setting this to true prevents that from happening, which is useful for every type of game
  where you don't need accurate physics responses in terms of the collider's rotation.
  Example:
    self:collider_set_fixed_rotation(true)
]]--
function collider:collider_set_fixed_rotation(v)
  self.body:setFixedRotation(v)
end

--[[
  Sets the collider's friction.
  This is a value from 0 to infinity, but generally between 0 to 1.
  The higher it is, the more friction there will be when this collider slides with another.
  At value 0, friction is turned off and the object will slide with no resistance.
  The friction calculation takes into account the friction of both colliders, so if one object has friction set to 0 then the
  interaction will be treated as if there were no friction between both objects.
  Example:
    self:collider_set_friction(1)
]]--
function collider:collider_set_friction(v)
  if self.shapes then
    for _, shape in ipairs(self.shapes) do
      shape:setFriction(v)
    end
  else
    self.shape:setFriction(v)
  end
end

--[[
  Sets the colider's gravity scale.
  This is a multiplier on the world's gravity, but applied to this collider alone.
  Example:
    self:collider_set_gravity_scale(0)
]]--
function collider:collider_set_gravity_scale(v)
  self.body:setGravityScale(v)
end

--[[
  Sets if the collider is allowed to sleep or not. This is true by default.
  This is particularly useful when you're using colliders for UI or other elements that are static but still need to be interacted with collision-wise.
  Example:
    self:collider_set_sleeping_allowed(false)
--]]
function collider:collider_set_sleeping_allowed(v)
  self.body:setSleepingAllowed(v)
end

--[[
  Sets the collier's restitution.
  This is a value from 0 to 1 and the higher it is the more energy is conserved when the collider bounces off other objects.
  At value 1, it will bounce perfectly and not lose any velocity.
  At value 0, it will not bounce at all.
  Example:
    self:collider_set_restitution(0.75)
]]--
function collider:collider_set_restitution(v)
  if self.shapes then
    for _, shape in ipairs(self.shapes) do
      shape:setRestitution(v)
    end
  else
    self.shape:setRestitution(v)
  end
end

--[[
  Sets the collider's velocity.
  Example:
    self:collider_set_velocity(100, 100)
]]--
function collider:collider_set_velocity(vx, vy)
  self.body:setLinearVelocity(vx, vy)
end

--[[
  Returns the collider's velocity.
  Example:
    vx, vy = self:collider_get_velocity()
]]--
function collider:collider_get_velocity()
  return self.body:getLinearVelocity()
end

--[[
  Moves the object towards a point.
  You can either do this by using the speed argument directly, or by using the max_time argument.
  max_time will override speed since it will make the object reach the target in a set given time.
  Examples:
    self:collider_move_towards_point(player.x, player.y, 40)     -> move towards the player with 40 speed
    self:collider_move_towards_point(player.x, player.y, nil, 2) -> move towards the player with speed such that it'd reach him in 2 seconds if he never moved
--]]
function collider:collider_move_towards_point(x, y, speed, max_time)
  if max_time then speed = math.distance(self.x, self.y, x, y)/max_time end
  local r = math.angle_to_point(self.x, self.y, x, y)
  self:collider_set_velocity(speed*math.cos(r), speed*math.sin(r))
end

--[[
  Moves the object along an angle. Most useful for simple projectiles that have predictable movement.
  Example:
    self:collider_move_towards_angle(math.pi/4, 100)
]]--
function collider:collider_move_towards_angle(r, speed)
  self:collider_set_velocity(speed*math.cos(r), speed*math.sin(r))
end

--[[
  Same as collider_move_towards_point but towards the mouse.
  Example:
    self:collider_move_towards_mouse(nil, 1)
--]]
function collider:collider_move_towards_mouse(speed, max_time)
  if max_time then speed = math.distance(self.x, self.y, an.mouse.x, an.mouse.y)/max_time end
  local r = math.angle_to_point(self.x, self.y, an.mouse.x, an.mouse.y)
  self:collider_set_velocity(speed*math.cos(r), speed*math.sin(r))
end

--[[
  Same as collider_move_towards_mouse but does so only the x axis.
  Example:
    self:collider_move_towards_mouse_horizontally(nil, 1)
--]]
function collider:collider_move_towards_mouse_horizontally(speed, max_time)
  if max_time then speed = math.distance(self.x, self.y, an.mouse.x, an.mouse.y)/max_time end
  local r = math.angle_to_point(self.x, self.y, an.mouse.x, an.mouse.y)
  local vx, vy = self:collider_get_velocity()
  self:collider_set_velocity(speed*math.cos(r), vy)
end

--[[
  Same as collider_move_towards_mouse but does so only the x axis.
  Example:
    self:collider_move_towards_mouse_vertically(nil, 1)
--]]
function collider:collider_move_towards_mouse_vertically(speed, max_time)
  if max_time then speed = math.distance(self.x, self.y, an.mouse.x, an.mouse.y)/max_time end
  local r = math.angle_to_point(self.x, self.y, an.mouse.x, an.mouse.y)
  local vx, vy = self:collider_get_velocity()
  self:collider_set_velocity(vx, speed*math.sin(r))
end

--[[
  Rotates the object towards a point using rotational lerp.
  p is the percentage distance covered to the target. A value of 0.9 means 90% will be covered, for instance.
  t is how much time it will take until the distance covered is the one specified by p.
  Examples:
    x, y = an.mouse.x, an.mouse.y
    self:collider_rotate_towards_point(0.9, 1, dt, x, y)   -> covers 90% of the rotation between current angle and angle to mouse per second
    self:collider_rotate_towards_point(0.5, 0.5, dt, x, y) -> covers 50% of the rotation between current angle and angle to mouse per 0.5 seconds
]]--
function collider:collider_rotate_towards_point(p, t, dt, x, y)
  self:collider_set_angle(math.lerp_angle_dt(p, t, dt, self.r, math.angle_to_point(self.x, self.y, x, y)))
end

--[[
  Rotates the object towards the mouse using rotational lerp.
  p is the percentage distance covered to the target. A value of 0.9 means 90% will be covered, for instance.
  t is how much time it will take until the distance covered is the one specified by p.
  Examples:
    self:collider_rotate_towards_mouse(0.9, 1, dt)    -> covers 90% of the rotation between current angle and angle to mouse per second
    self:collider_rotate_towards_mouse(0.5, 0.5, dt)  -> covers 50% of the rotation between current angle and angle to mouse per 0.5 seconds
]]--
function collider:collider_rotate_towards_mouse(p, t, dt)
  self:collider_set_angle(math.lerp_angle_dt(p, t, dt, self.r, math.angle_to_point(self.x, self.y, an.mouse.x, an.mouse.y)))
end

--[[
  Rotates the object towards another object using rotational lerp.
  p is the percentage distance covered to the target. A value of 0.9 means 90% will be covered, for instance.
  t is how much time it will take until the distance covered is the one specified by p.
  Examples:
    self:collider_rotate_towards_object(0.9, 1, dt, player) -> covers 90% of the rotation between the current angle and angle to the player per second
    self:collider_rotate_towards_object(0.5, 0.5, dt, player) -> covers 50% of the rotation between the current angle and angle to the player per 0.5 seconds
--]]
function collider:collider_rotate_towards_object(p, t, dt, object)
  self:collider_rotate_towards_point(p, t, dt, object.x, object.y)
end

--[[
  Rotates the object towards its own velocity vector using rotational lerp.
  p is the percentage distance covered to the target. A value of 0.9 means 90% will be covered, for instance.
  t is how much time it will take until the distance covered is the one specified by p.
  Examples:
    self:collider_rotate_towards_velocity(0.9, 1, dt)   -> covers 90% of the rotation between current angle and velocity angle per second
    self:collider_rotate_towards_velocity(0.5, 0.5, dt) -> covers 50% of the rotation between current angle and velocity angle per 0.5 seconds
]]--
function collider:collider_rotate_towards_velocity(p, t, dt)
  local vx, vy = self:collider_get_velocity()
  self:collider_set_angle(math.lerp_angle_dt(p, t, dt, self.r, math.angle_to_point(self.x, self.y, self.x + vx, self.y + vy)))
end

--[[
  Seeking steering behavior. Returns the force to be applied to the object.
  Example:
    ax, ay = self:collider_seek(an.mouse.x, an.mouse.y, self.max_v)
    self:collider_apply_force(math.limit(ax, ay, 1000)) -> applies the steering force with a max of 1000 force units
]]--
function collider:collider_seek(x, y, max_speed, max_force)
  local dx, dy = x - self.x, y - self.y
  dx, dy = math.normalize(dx, dy)
  dx, dy = dx*max_speed, dy*max_speed
  local vx, vy = self:collider_get_velocity()
  dx, dy = dx - vx, dy - vy
  dx, dy = math.limit(dx, dy, max_force or 1000)
  return dx, dy
end

--[[
  Arrive steering behavior. Stops accelering when within radius rs and returns the force to be applied to the object.
  Example:
    ax, ay = self:collider_arrive(an.mouse.x, an.mouse.y, 64, self.max_v)
    self:collider_apply_force(math.limit(ax, ay, 1000)) -> applies the steering force with a max of 1000 force units
--]]
function collider:collider_arrive(x, y, rs, max_speed, max_force)
  local dx, dy = x - self.x, y - self.y
  local d = math.length(dx, dy)
  local dx, dy = math.normalize(dx, dy)
  if d < rs then
    dx, dy = dx*math.remap(d, 0, rs, 0, max_speed), dy*math.remap(d, 0, rs, 0, max_speed)
  else
    dx, dy = dx*max_speed, dy*max_speed
  end
  local vx, vy = self:collider_get_velocity()
  dx, dy = dx - vx, dy - vy
  dx, dy = math.limit(dx, dy, max_force or 1000)
  return dx, dy
end

--[[
  Wander steering behavior. Returns the force to be applied to the object.
  Example:
    ax, ay = self:collider_seek(an.mouse.x, an.mouse.y)
    wx, wy = self:collider_wander(50, 50, 20, 200)
    self:collider_apply_force(math.limit(ax+2*wx, ay+2*wy, 1000)) -> applies the steering force while making wander force stronger than seek
]]--
function collider:collider_wander(d, rs, jitter, max_speed, max_force)
  local jitter = jitter*an.rate
  local cx, cy = math.cos(self.r), math.sin(self.r)
  cx, cy = self.x + cx*d, self.y + cy*d
  if not self.wander_r then self.wander_r = an:random_angle() end
  self.wander_r = self.wander_r + an:random_float(-jitter, jitter)
  return self:collider_seek(cx + rs*math.cos(self.wander_r), cy + rs*math.sin(self.wander_r), max_speed, max_force or 1000)
end

--[[
  Separation steering behavior. Separates this object from others if they're inside the circle of radius rs.
  Returns the force/acceleration to be applied to the object.
  Example:
    sx, sy = self:collider_separate(50, enemies, self.max_v)
    self:collider_apply_force(math.limit(sx, sy, 1000)) -> applies the separation force with a max of 1000 force units
--]]
function collider:collider_separate(rs, others, max_speed, max_force)
  local dx, dy, number_of_separators = 0, 0, 0
  for _, object in ipairs(others) do
    if object.id ~= self.id and math.distance(self.x, self.y, object.x, object.y) < rs then
      local tx, ty = self.x - object.x, self.y - object.y
      local nx, ny = math.normalize(tx, ty)
      local l = math.length(nx, ny)
      dx = dx + rs*(nx/l)
      dy = dy + rs*(ny/l)
      number_of_separators = number_of_separators + 1
    end
  end
  if number_of_separators > 0 then dx, dy = dx/number_of_separators, dy/number_of_separators end
  if math.length(dx, dy) > 0 then
    dx, dy = math.normalize(dx, dy)
    dx, dy = dx*max_speed, dy*max_speed
    local vx, vy = self:collider_get_velocity()
    dx, dy = dx - vx, dy - vy
    dx, dy = math.limit(dx, dy, max_force or 1000)
  end
  return math.limit(dx, dy, max_force or 1000)
end

--[[
  Prevents the object from going below position y. The object will be pushed out of it with some force.
  Returns the force/acceleration to be applied to the object.
  Example:
    dx, dy = self:collider_do_not_go_below(an.h/2)
    self:collider_apply_force(math.limit(dx, dy, 1000)) -> applies the separation force with a max of 1000 force units
--]]
function collider:collider_do_not_go_below(y, max_force)
  local dx, dy = 0, 0
  if self.y > y then
    local ty = self.y - y
    local nx, ny = math.normalize(0, ty)
    local l = math.length(nx, ny)
    dx, dy = 0, -ty*(ny/l)
  end
  return math.limit(dx, dy, max_force or 1000)
end

--[[
  Follows the given flow field. Returns the force to be applied to the object.
  The flow field is a grid object where each cell has a value in the [0, 2*math.pi] range representing movement direction.
  Example:
    -- Create a flow field where cells swirl in circles around its center:
    flow_field = object():grid(20, 20):grid_set_dimensions(an.w/2, an.h/2, 24, 24)
    for i, j, v in flow_field:grid_pairs() do
      local x, y = flow_field:grid_get_cell_position(i, j)
      flow_field:grid_set(i, j, math.angle_to_point(x, y, flow_field.x, flow_field.y) + math.pi/2
    -- Then in some collider's update function
    local ax, ay = self:collider_follow_flow_field(flow_field, self.max_v)
--]]
function collider:collider_follow_flow_field(flow_field, max_speed, max_force)
  local x, y = math.ceil(self.x/flow_field.cell_w), math.ceil(self.y/flow_field.cell_h)
  local v = flow_field:grid_get(x, y)
  if v then
    local dx, dy = max_speed*math.cos(v), max_speed*math.sin(v)
    local vx, vy = self:collider_get_velocity()
    dx, dy = dx - vx, dy - vy
    dx, dy = math.limit(dx, dy, max_force or 1000)
    return dx, dy
  end
  return 0, 0
end
