--[[
  Module responsible for drawing things through a viewport.
  "an" is a global camera that is attached to every layter by default. (can add ways to change it if the need arises)
  .camera_x and .camera_y are the camera's position in world coordinates, the camera is always centered around those values.
  .camera_w and .camera_h are the camera's size, generally this should be the size of a layer's canvas, which are an.w and an.h by default.
--]]
camera = class:class_new()
function camera:camera(camera_x, camera_y, camera_w, camera_h)
  self.tags.camera = true
  self.camera_x = camera_x or 0
  self.camera_y = camera_y or 0
  self.camera_w = camera_w or an.w
  self.camera_h = camera_h or an.h
  self.camera_r, self.camera_sx, self.camera_sy = 0, 1, 1

  self.parallax_base = {x = 0, y = 0}
  self.mouse = {x = 0, y = 0}
  self.last_mouse = {x = 0, y = 0}
  self.mouse_dt = {x = 0, y = 0}
  return self
end

--[[
  Attaches the camera, meaning all further draw operations will be affected by its transform.
  Accepts two values that go from 0 to 1 representing how much parallaxing there should be for the next operations.
  A value of 1 (default) means no parallaxing, meaning elements drawn will move at the same rate as all other elements.
  A value of 0 means maximum parallaxing, meaning elements drawn will not move at all.
  These values can be set on a per-layer basis, so you shouldn't need to call this function manually.
--]]
function camera:camera_attach(parallax_x, parallax_y)
  local parallax_x = parallax_x or 1
  local parallax_y = parallax_y or 1
  self.parallax_base.x, self.parallax_base.y = self.camera_x, self.camera_y
  self.camera_x = self.parallax_base.x*parallax_x
  self.camera_y = self.parallax_base.y*parallax_y
  local shake_x, shake_y = 0, 0
  if self.normal_shake_amount then
    shake_x = shake_x + self.normal_shake_amount.x
    shake_y = shake_y + self.normal_shake_amount.y
  end
  if self.spring_shake_amount then
    shake_x = shake_x + self.spring_shake_amount.x
    shake_y = shake_y + self.spring_shake_amount.y
  end
  self.camera_x = self.camera_x + shake_x
  self.camera_y = self.camera_y + shake_y
  love.graphics.push()
  love.graphics.translate(self.camera_w/2, self.camera_h/2)
  love.graphics.scale(self.camera_sx, self.camera_sy)
  love.graphics.rotate(self.camera_r)
  love.graphics.translate(-self.camera_x, -self.camera_y)
end

--[[
  Detaches the camera, meaning all further draw operations won't be affected by its transform.
--]]
function camera:camera_detach()
  love.graphics.pop()
  self.camera_x, self.camera_y = self.parallax_base.x, self.parallax_base.y
end

--[[
  Returns the coordinates passed in in world coordinates.
  This is useful when transforming from screen space to world space, like when the mouse clicks on something.
  If you look at camera_get_mouse_position you'll see that it uses this on the values returned by love.mouse.getPosition.
  The camera's self.mouse variable has the position of the mouse in world coordinates, as this often this ends up being used.
  Example:
    an:camera_get_world_coords(mouse_x(), mouse_y()) -> returns the mouse's position in world coordinates
]]--
function camera:camera_get_world_coords(x, y)
  x, y = x/an.sx, y/an.sy
  x, y = x - self.camera_x, y - self.camera_y
  x, y = x*math.cos(-self.camera_r) - y*math.sin(-self.camera_r), x*math.sin(-self.camera_r) + y*math.cos(-self.camera_r)
  x, y = x/self.camera_sx, y/self.camera_sy
  x, y = x + self.camera_x, y + self.camera_y
  x, y = x + (self.camera_x - self.camera_w/2)/self.camera_sx, y + (self.camera_y - self.camera_h/2)/self.camera_sy
  return x, y
end

--[[
  Returns the values passed in in local coordinates.
  This is useful when transforming from world space to screen space, like when displaying UI to object's world position.
  Example:
    an:camera_get_local_coords(player.x, player.y) -> returns the player's position in local/screen coordinates
]]--
function camera:camera_get_local_coords(x, y)
  x, y = x - self.camera_x, y - self.camera_y
  x, y = x*math.cos(self.camera_r) - y*math.sin(self.camera_r), x*math.sin(self.camera_r) + y*math.cos(self.camera_r)
  return x*self.camera_sx + self.camera_w/2, y*self.camera_sy + self.camera_h/2
end

--[[
  Returns the mouse's position in world coordinates.
  The camera's .mouse variable has the mouse's position in world coordinates set to it every frame.
  It can be accessed via "an.mouse.x" and "an.mouse.y", so calling this function shouldn't be necessary.
]]--
function camera:camera_get_mouse_position()
  return self:camera_get_world_coords(love.mouse.getPosition())
end

--[[
  Updates camera state, mostly sets .mouse and .mouse_dt variables to their correct values for this frame.
  This is called automatically by "an" only, so it doesn't need to be manually called, unless you create your own camera objects.
  In that case, it should also be called as a late action, after update has been run for all objects.
]]--
function camera:camera_update(dt)
  self.mouse.x, self.mouse.y = self:camera_get_mouse_position()
  self.mouse_dt.x, self.mouse_dt.y = self.mouse.x - self.last_mouse.x, self.mouse.y - self.last_mouse.y
  self.last_mouse.x, self.last_mouse.y = self.mouse.x, self.mouse.y
end

--[[
  Moves the camera by the given amount.
  TODO: examples
--]]
function camera:camera_move(dx, dy)
  self.camera_x, self.camera_y = self.camera_x + dx, self.camera_y + dy
end

--[[
  Moves the camera to the given position.
  TODO: examples
--]]
function camera:camera_move_to(x, y)
  self.camera_x, self.camera_y = x, y
end

--[[
  Zooms the camera by the given amount.
  TODO: examples, figure out different interp zoom methods too
]]--
function camera:camera_zoom(sx, sy)
  self.camera_sx, self.camera_sy = self.camera_sx + (sx or 1), self.camera_sy + (sy or sx or 1)
end

--[[
  Zooms the camera to the given scale.
  TODO: examples
]]--
function camera:camera_zoom_to(sx, sy)
  self.camera_sx, self.camera_sy = sx or 1, sy or sx or 1
end
