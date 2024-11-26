--[[
  Adds mouse hovering abilities to an object.
  All this module does is set the object's .mouse_active attribute to true when the mouse is hovering over the object, and to false otherwise.
  .mouse_enter and .mouse_exit are also set to true for one frame whenever the mouse enters/exits the object's boundaries.
  The object must have .w and .h attributes set to some value before the first update is run, otherwise an error will occur.
--]]
mouse_hover = class:class_new()
function mouse_hover:mouse_hover(hover_multiplier)
  self.tags.mouse_hover = true
  self.mouse_active = false
  self.mouse_enter, self.mouse_exit = false, false
  self.mouse_hover_multiplier = hover_multiplier or 1
  if not self.w or not self.h then error('mouse_hover requires the object to have both .w and .h attributes set to numbers.') end
  return self
end

function mouse_hover:mouse_hover_update(dt)
  self.mouse_enter = false
  self.mouse_exit = false

  if collision.point_rectangle(an.mouse.x, an.mouse.y, self.x, self.y, self.w*self.mouse_hover_multiplier, self.h*self.mouse_hover_multiplier) then
    if not self.mouse_active then self.mouse_enter = true end
    self.mouse_active = true
  else
    if not self.mouse_active then self.mouse_exit = true end
    self.mouse_active = false
  end
end
