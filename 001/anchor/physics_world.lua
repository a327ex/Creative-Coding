--[[
  Module that turns the object into a box2d physics world.
  This works in conjunction with the collider module.
  If your game takes place in smaller world coordinates (i.e. you set an.w and an.h to 320x240 or something) then you'll
  want smaller meter values, like 32 instead of 64. Similarly, if your game is bigger you'll want higher ones.
  Read more on meter values for box2d worlds here: https://love2d.org/wiki/love.physics.setMeter.
  Examples:
    an:physics_world()           -> a common setup for most non-platformer games
    an:physics_world(64, 0, 256) -> a common platformer setup with vertical downward gravity
  "an" is automatically a physics world, and "physics_world_update" and "physics_world_post_update" are called for it.
  If you create your own physics world instead, you must call those two functions manually yourself.
]]--
physics_world = class:class_new()
function physics_world:physics_world(meter, gx, gy)
  self.tags.physics_world = true
  love.physics.setMeter(meter or 64)
  self.world = love.physics.newWorld(gx or 0, gy or 0)
  self.collision_enter = {}
  self.collision_active = {}
  self.collision_exit = {}
  self.trigger_enter = {}
  self.trigger_active = {}
  self.trigger_exit = {}

  self.world:setCallbacks(
    function(fa, fb, c)
      local a, b = fa:getUserData(), fb:getUserData()
      if not a or not b then return end
      if fa:isSensor() and fb:isSensor() then
        if fa:isSensor() then self:physics_world_add_trigger_enter(a, b, a.physics_tag, b.physics_tag) end
        if fb:isSensor() then self:physics_world_add_trigger_enter(b, a, b.physics_tag, a.physics_tag) end
      elseif not fa:isSensor() and not fb:isSensor() then
        local x1, y1, x2, y2 = c:getPositions()
        local nx, ny = c:getNormal()
        self:physics_world_add_collision_enter(a, b, a.physics_tag, b.physics_tag, x1, y1, x2, y2, nx, ny)
        self:physics_world_add_collision_enter(b, a, b.physics_tag, a.physics_tag, x1, y1, x2, y2, nx, ny)
      end
    end,
    function(fa, fb, c)
      local a, b = fa:getUserData(), fb:getUserData()
      if not a or not b then return end
      if fa:isSensor() and fb:isSensor() then
        if fa:isSensor() then self:physics_world_add_trigger_exit(a, b, a.physics_tag, b.physics_tag) end
        if fb:isSensor() then self:physics_world_add_trigger_exit(b, a, b.physics_tag, a.physics_tag) end
      elseif not fa:isSensor() and not fb:isSensor() then
        local x1, y1, x2, y2 = c:getPositions()
        local nx, ny = c:getNormal()
        self:physics_world_add_collision_exit(a, b, a.physics_tag, b.physics_tag, x1, y1, x2, y2, nx, ny)
        self:physics_world_add_collision_exit(b, a, b.physics_tag, a.physics_tag, x1, y1, x2, y2, nx, ny)
      end
    end,
    function(fa, fb, c)
      local a, b = fa:getUserData(), fb:getUserData()
      if not a or not b then return end
      if self.pre_solve then self:pre_solve(a, b, c) end
    end,
    function(fa, fb, c, ni1, ti1, ni2, ti2)
      local a, b = fa:getUserData(), fb:getUserData()
      if not a or not b then return end
      if self.post_solve then self:post_solve(a, b, c, ni1, ti1, ni2, ti2) end
    end
  )
  return self
end

--[[
  Updates world state. This calls update on the box2d world object.
  This happens before "update" and before any groups are updated.
]]--
function physics_world:physics_world_update(dt)
  self.world:update(dt)
end

--[[
  Updates physics world state at the end of the frame.
  This resets the collision/trigger enter/exit tables, since those values should only be there for one frame.
  If you create your own physics world, make sure to call this on "post_update".
]]--
function physics_world:physics_world_post_update()
  self.collision_enter = {}
  self.collision_exit = {}
  self.trigger_enter = {}
  self.trigger_exit = {}
end

--[[
  Sets all physics tags, which will define how objects collide with each other and how they generate collision events.
  self.physics_tags is a table of strings corresponding to physics tags that will be assigned to different objects.
  This should be called manually by the user at the start of the game once.
  Example:
    an:physics_world_set_physics_tags({'player', 'enemy', 'projectile', 'ghost'})
]]--
function physics_world:physics_world_set_physics_tags(physics_tags)
  self.physics_tags = physics_tags
  self.collision_tags = {}
  self.trigger_tags = {}
  for i, tag in ipairs(self.physics_tags) do
    self.collision_tags[tag] = {category = i, masks = {}}
    self.trigger_tags[tag] = {category = i, triggers = {}}
  end
end

--[[
  Enables physical collision between the first and the other tags.
  By default, every object physically collides with every other object, so calling this isn't generally necessary.
  Example:
    an:physics_world_enable_collision_between('player', {'enemy'}) -> 'player' now physically collides with 'enemy'
]]--
function physics_world:physics_world_enable_collision_between(tag, tags)
  for _, t in ipairs(tags) do
    array.delete(self.collision_tags[tag].masks, self.collision_tags[t].category)
  end
end

--[[
  Disables physical collision between the first and the other tags.
  This is useful when you need objects to go through each other without generating realistic collision responses.
  In general, it's useful to have a 'ghost' tag that is applied to objects that don't need to physically collide at all.
  Example:
    an:physics_world_disable_collision_between('ghost', {'enemy', 'ghost', 'projectile', 'player'})
]]--
function physics_world:physics_world_disable_collision_between(tag, tags)
  for _, t in ipairs(tags) do
    table.insert(self.collision_tags[tag].masks, self.collision_tags[t].category)
  end
end

--[[
  Enables trigger collisions between the first and the other tags.
  When objects have physical collisions disabled between on another, you might still want to have enter/exit collision events
  generated when those objects start/stop overlapping, and this setting achieves that.
  Example:
    an:physics_world_disable_collision_between('ghost', {'enemy', 'ghost', 'projectile', 'player'})
    an:physics_world_enable_trigger_between('ghost', {'player'}) -> now when 'ghost' passes through 'player', enter and exit
                                                                     trigger events will be generated
]]--
function physics_world:physics_world_enable_trigger_between(tag, tags)
  for _, t in ipairs(tags) do
    table.insert(self.trigger_tags[tag].triggers, self.trigger_tags[t].category)
  end
end

--[[
  Disables trigger collisions between the first and the other tags.
  By default, every object isn't generating trigger events with every other object, so calling this isn't generally necessary.
  Example:
    an:physics_world_disable_trigger_between 'ghost', {'player'}
]]--
function physics_world:physics_world_disable_trigger_between(tag, tags)
  for _, t in ipairs(tags) do
    array.delete(self.trigger_tags[tag].triggers, self.trigger_tags[t].category)
  end
end

--[[
  Adds collision_enter and collision_active events to this object.
  These events can then be read by the user with "self.collision_enter['tag_1']['tag_2']".
  collision_enter event lasts for 1 frame only.
  collision_active events last for however many frames there are between collision_enter and collision_exit events.
  This function is called automatically by the engine and shouldn't be called directly by the user.
]]--
function physics_world:physics_world_add_collision_enter(a, b, a_tag, b_tag, x1, y1, x2, y2, xn, yn)
  if not self.collision_enter[a_tag] then self.collision_enter[a_tag] = {} end
  if not self.collision_enter[a_tag][b_tag] then self.collision_enter[a_tag][b_tag] = {} end
  if not self.collision_active[a_tag] then self.collision_active[a_tag] = {} end
  if not self.collision_active[a_tag][b_tag] then self.collision_active[a_tag][b_tag] = {} end
  local a_vx, a_vy = a:collider_get_velocity()
  table.insert(self.collision_enter[a_tag][b_tag], {a = a, b = b, x1 = x1, y1 = y1, x2 = x2, y2 = y2, nx = xn, ny = yn, vx = a_vx, vy = a_vy})
  table.insert(self.collision_active[a_tag][b_tag], {a = a, b = b})
end

--[[
  Adds collision_exit and removes collision_active events from this object.
  These events can then be read by the user with "self.collision_exit['tag_1']['tag_2']".
  collision_exit event lasts for 1 frame only.
  collision_active events last for however many frames there are between collision_enter and collision_exit events.
  This function is called automatically by the engine and shouldn't be called directly by the user.
]]--
function physics_world:physics_world_add_collision_exit(a, b, a_tag, b_tag, x1, y1, x2, y2, xn, yn)
  if not self.collision_exit[a_tag] then self.collision_exit[a_tag] = {} end
  if not self.collision_exit[a_tag][b_tag] then self.collision_exit[a_tag][b_tag] = {} end
  if not self.collision_active[a_tag] then self.collision_active[a_tag] = {} end
  if not self.collision_active[a_tag][b_tag] then self.collision_active[a_tag][b_tag] = {} end
  table.insert(self.collision_exit[a_tag][b_tag], {a = a, b = b, x1 = x1, y1 = y1, x2 = x2, y2 = y2, nx = xn, ny = yn})
  for i = #self.collision_active[a_tag][b_tag], 1, -1 do
    local c = self.collision_active[a_tag][b_tag][i]
    if c.a.id == a.id and c.b.id == b.id then
      array.remove(self.collision_active[a_tag][b_tag], i)
      break -- copy trigger_exit note here
    end
  end
end

--[[
  Adds trigger_enter and trigger_active events to this object.
  These events can then be read by the user with "self.trigger_enter['tag_1']['tag_2']".
  trigger_enter event lasts for 1 frame only.
  trigger_active events last for however many frames there are between trigger_enter and trigger_exit events.
  This function is called automatically by the engine and shouldn't be called directly by the user.
]]--
function physics_world:physics_world_add_trigger_enter(a, b, a_tag, b_tag)
  if not self.trigger_enter[a_tag] then self.trigger_enter[a_tag] = {} end
  if not self.trigger_enter[a_tag][b_tag] then self.trigger_enter[a_tag][b_tag] = {} end
  if not self.trigger_active[a_tag] then self.trigger_active[a_tag] = {} end
  if not self.trigger_active[a_tag][b_tag] then self.trigger_active[a_tag][b_tag] = {} end
  table.insert(self.trigger_enter[a_tag][b_tag], {a = a, b = b})
  table.insert(self.trigger_active[a_tag][b_tag], {a = a, b = b})
end

--[[
  Adds trigger_exit and trigger_active events to this object.
  These events can then be read by the user with "self.trigger_exit['tag_1']['tag_2']".
  trigger_exit event lasts for 1 frame only.
  trigger_active events last for however many frames there are between trigger_exit and trigger_exit events.
  This function is called automatically by the engine and shouldn't be called directly by the user.
]]--
function physics_world:physics_world_add_trigger_exit(a, b, a_tag, b_tag)
  if not self.trigger_exit[a_tag] then self.trigger_exit[a_tag] = {} end
  if not self.trigger_exit[a_tag][b_tag] then self.trigger_exit[a_tag][b_tag] = {} end
  if not self.trigger_active[a_tag] then self.trigger_active[a_tag] = {} end
  if not self.trigger_active[a_tag][b_tag] then self.trigger_active[a_tag][b_tag] = {} end
  local a_vx, a_vy = a:collider_get_velocity()
  table.insert(self.trigger_exit[a_tag][b_tag], {a = a, b = b, vx = a_vx, by = a_vy})
  for i = #self.trigger_active[a_tag][b_tag], 1, -1 do
    local c = self.trigger_active[a_tag][b_tag][i]
    if c.a.id == a.id and c.b.id == b.id then
      array.remove(self.trigger_active[a_tag][b_tag], i)
      break
      --[[ NOTE:
        This "break" used to not be here and everything worked fine, but when I added the ability for polygons to be triangulated with multiple shapes this needed to be added to fix .trigger_active.
        Consider a polygon with 2 triangles named "a", and an object "b" that enters collision with a's first triangle. When this happens, {a, b} is added to the active list.
        Now imagine that b exits the first triangle and enters collision with the second at the same time, as it will happen due to how triangulation works.
        In that frame, {a, b} is added to the exit list, and it is also added to the active list again, since a new trigger enter happened with the second triangle.
        The active list now has 2 {a, b} items, one belonging to the enter collision from the first triangle, and one belonging to the second.
        And then this loop in this function goes over the active list to remove all instances of {a, b} from it. But that's wrong!
        Because we only exited from the first triangle, so we should only remove a single instance of {a, b} from the active list and leave the instance that was just added as in.
        This is achieved most simply by using a "break", although ideally it'd probably be better to track enter/exits individually and remove them accordingly.
      --]]
    end
  end
end

--[[
  Returns a table of collision_enter events for the two given tags this frame.
  Each event is a table of the type: {object_1, object_2, x1, y1, x2, y2, xn, yn}
  Where x1, y1, x2, y2 are contact points, and xn, yn is the collision's normal vector.
  If no collision_enter events for these tags happened this frame then it returns an empty table.
  Example:
    for _, c in ipairs(an:physics_world_get_collision_enter('player', 'enemy')) do -- in some update function
      local player, enemy = c[1], c[2]
      local x1, y1, x2, y2 = c[3], c[4], c[5], c[6]
    end
]]--
function physics_world:physics_world_get_collision_enter(tag_1, tag_2)
  local collisions = {}
  if self.collision_enter[tag_1] and self.collision_enter[tag_1][tag_2] then collisions = self.collision_enter[tag_1][tag_2] end
  return collisions
end

--[[
  Returns a table of collision_exit events for the two given tags this frame.
  Each event is a table of the type: {object_1, object_2, x1, y1, x2, y2, xn, yn}
  Where x1, y1, x2, y2 are contact points, and xn, yn is the collision's normal vector.
  If no collision_exit events for these tags happened this frame then it returns an empty table.
  Example:
    for _, c in ipairs(an:physics_world_get_collision_exit('player', 'enemy')) do -- in some update function
      local player, enemy = c[1], c[2]
      local x1, y1, x2, y2 = c[3], c[4], c[5], c[6]
    end
]]--
function physics_world:physics_world_get_collision_exit(tag_1, tag_2)
  local collisions = {}
  if self.collision_exit[tag_1] and self.collision_exit[tag_1][tag_2] then collisions = self.collision_exit[tag_1][tag_2] end
  return collisions
end

--[[
  Returns a table of collision_active events for the two given tags this frame.
  Each event is a table of the type: {object_1, object_2}
  If no collision_active events for these tags happened this frame then it returns an empty table.
  Example:
    for _, c in ipairs(an:physics_world_get_collision_active('player', 'enemy')) do -- in some update function
      local player, enemy = c[1], c[2]
    end
]]--
function physics_world:physics_world_get_collision_active(tag_1, tag_2)
  local collisions = {}
  if self.collision_active[tag_1] and self.collision_active[tag_1][tag_2] then collisions = self.collision_active[tag_1][tag_2] end
  return collisions
end

--[[
  Exactly the same as "physics_world_get_collision_enter" except for trigger events instead.
  The only difference is that trigger events have no contact points nor normals, since no physical collision happened.
]]--
function physics_world:physics_world_get_trigger_enter(tag_1, tag_2)
  local triggers = {}
  if self.trigger_enter[tag_1] and self.trigger_enter[tag_1][tag_2] then triggers = self.trigger_enter[tag_1][tag_2] end
  return triggers
end

--[[
  Exactly the same as "physics_world_get_collision_exit" except for trigger events instead.
  The only difference is that trigger events have no contact points nor normals, since no physical collision happened.
]]--
function physics_world:physics_world_get_trigger_exit(tag_1, tag_2)
  local triggers = {}
  if self.trigger_exit[tag_1] and self.trigger_exit[tag_1][tag_2] then triggers = self.trigger_exit[tag_1][tag_2] end
  return triggers
end

--[[
  Exactly the same as "physics_world_get_collision_active" except for trigger events instead.
]]--
function physics_world:physics_world_get_trigger_active(tag_1, tag_2)
  local triggers = {}
  if self.trigger_active[tag_1] and self.trigger_active[tag_1][tag_2] then triggers = self.trigger_active[tag_1][tag_2] end
  return triggers
end

--[[
  Sets the box2d world's meter.
  By default, the physics world in "an" is set to have 64 meter size, so you can use this function to change it.
  Your meter size should be relative to how big the objects in your game are. In general, for game worlds of small sizes of
  320x240 or 480x270, you'll want a value around 32-64. For bigger worlds, like 640x360, something in the 100-200 range is
  better, and then for bigger worlds like 1920x1080, you'll probably want 400+, although I haven't tested at those sizes.
  Example:
    an:physics_world_set_meter(64)
]]--
function physics_world:physics_world_set_meter(v)
  love.physics.setMeter(v)
end

--[[
  Sets the box2d world's gravity.
  By default, the physics world in "an" is set to have 0, 0 gravity, so you can use this function to change it.
  If you're creating your own worlds instead then you can set gravity directly on the "physics_world" initialization function.
  Remember to take into account your current meter size and to set the gravity value relative to it.
  Example:
    an:physics_world_set_meter(64)
    an:physics_world_set_gravity(0, 128) -> decent downwards gravity value for a world of 64 meter size
]]--
function physics_world:physics_world_set_gravity(gx, gy)
  self.world:setGravity(gx, gy)
end

--[[
  Returns all objects whose AABBs are colliding with the rectangle formed by x, y, w, h
  The last argument can be optionally passed in to make it so that the returned table contains all elements for which that function returns true.
  Examples:
    an:physics_world_get_objects_in_area(an.w/2, an.h/2, 64, 64) -> returns all objects colliding with the 64x64 rectangle centered on an.w/2, an.h/2
    self.objects_in_range = an:physics_world_get_objects_in_area(self.x, self.y, 92, 92, function(v) return v ~= self and v.team ~= self.team end)
  The example above returns all objects in a rectangular 92x92 area around self, that are not itself and have a different .team attribute to itself.
--]]
function physics_world:physics_world_get_objects_in_area(x, y, w, h, select_function)
  local x1, y1, x2, y2 = x - w/2, y - h/2, x + w/2, y + h/2
  local shapes = self.world:getShapesInArea(x1, y1, x2, y2)
  local objects = {}
  local seen = {}
  for _, f in ipairs(shapes) do
    local object = f:getUserData()
    if not seen[object] and ((not select_function and true) or select_function(object)) then
      seen[object] = true
      table.insert(objects, object)
    end
  end
  return objects
end
