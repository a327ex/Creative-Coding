--[[
  Module that implements UI behavior.
  Each UI behavior is independent and there is no central system or idea that connects them.
  A button has its own attributes and methods and ways of working, while a scrollbar, or a frame, or anything else, will have other properties.
  For now this is this way because I just want something that works, and I can try to generalize it into something better later.
--]]
ui = class:class_new()

--[[
  Creates a grid centered on position x, y, with size w, h, and with i, j columns and rows, respectively.
  The size of each cell in the grid is calculated automatically, and the function returns a grid object (see grid.lua file).
  Inside each cell, there's a rectangle object with the properties .x, .y (rectangle center), .x1, .y1 (rectangle left-top), .x2, .y2 (rectangle right-bottom) and .w, .h (rectangle size).
  Example:
    TODO
--]]
function ui:ui_grid(x, y, w, h, i, j)
  local grid = object():grid(i, j)
  local x1, y1 = x - w/2, y - h/2
  local x2, y2 = x + w/2, y + h/2
  local cell_w, cell_h = w/i, h/j
  grid:grid_set_dimensions(x, y, cell_w, cell_h)
  for k, l, v in grid:grid_pairs() do
    v = object()
    v.x1 = x1 + (k-1)*cell_w
    v.y1 = y1 + (l-1)*cell_h
    v.x2 = x1 + k*cell_w
    v.y2 = y1 + l*cell_h
    v.x = x1 + (k-1)*cell_w + cell_w/2
    v.y = y1 + (l-1)*cell_h + cell_h/2
    v.w = cell_w
    v.h = cell_h
    grid:grid_set(k, l, v)
  end
  return grid
end

--[[
  Same as ui_grid except x, y are the top-left positions of the grid instead of its center.
--]]
function ui:ui_grid_lt(x, y, w, h, i, j)
  local grid = object():grid(i, j)
  local x1, y1 = x, y
  local x2, y2 = x + w, y + h
  local cell_w, cell_h = w/i, h/j
  grid:grid_set_dimensions(x1 + w/2, y1 + h/2, cell_w, cell_h)
  for k, l, v in grid:grid_pairs() do
    v = object()
    v.x1 = x1 + (k-1)*cell_w
    v.y1 = y1 + (l-1)*cell_h
    v.x2 = x1 + k*cell_w
    v.y2 = y1 + l*cell_h
    v.x = x1 + (k-1)*cell_w + cell_w/2
    v.y = y1 + (l-1)*cell_h + cell_h/2
    v.w = cell_w
    v.h = cell_h
    grid:grid_set(k, l, v)
  end
  return grid
end

--[[
  Creates a text button centered on position x, y, with size w, h, that when clicked will call the given click action.
  The button is returned as a normal engine object with properties .x, .y (button's center), .x1, .y1 (button's left-top), .x2, .y2 (button's right-bottom) and .w, .h (button's size).
  The user is responsible for taking the returned button object and attaching an action to it so that it is drawn.
--]]
function ui:ui_button(x, y, w, h, click_action)
  return object():build(function(self)
    self.x, self.y = x, y
    self.w, self.h = w, h
    self.x1, self.y1 = self.x - self.w/2, self.y - self.h/2
    self.x2, self.y2 = self.x + self.w/2, self.y + self.h/2
    self:mouse_hover()
    self.click_action = click_action
  end):action(function(self, dt)
    if self.mouse_active and an:is_pressed('1') then
      self:click_action()
    end
  end)
end

--[[
  Same as ui_button except x, y are the top-left positions of the grid instead of its center.
--]]
function ui:ui_button_lt(x, y, w, h, click_action)
  return object():build(function(self)
    self.x, self.y = x + w/2, y + h/2
    self.w, self.h = w, h
    self.x1, self.y1 = self.x, self.y
    self.x2, self.y2 = self.x + self.w, self.y + self.h
    self:mouse_hover()
    self.click_action = click_action
  end):action(function(self, dt)
    if self.mouse_active and an:is_pressed('1') then
      self:click_action()
    end
  end)
end



--[===[
NOTE:
  There is some design flaw with this system because I keep trying to do things with it but I have to think way too much.
  Either the idea is too low-level and simple or it's just wrong in some important way.
  Either way it turned out to not be that useful. Leaving this here until I find something new for layouting that works better.

--[[
  Module that implements RectCut by Martin Cohen https://web.archive.org/web/20230925015548/https://halt.software/dead-simple-layouts/.
  Layout objects are rectangles containing the self.x1, self.y1, self.x2, self.y2, self.x, self.y (center) and self.w, self.h variables.
  Layouts can be created using either "layout", which takes in the centered rectangle position and width + height,
  or "layout_lt", which takes in the left-top rectangle position and width + height.
  You can then cut this rectangle with "layout_cut_left/right/top/down", which changes the existing layout while also returning a new one.
  Examples: (these follow the ones in the article posted above)
    -- Toolbar --
      toolbar = object():layout_lt(0, 0, 180, 16)
      r1 = toolbar:layout_cut_left(16)
      r2 = toolbar:layout_cut_left(16)
      r3 = toolbar:layout_cut_left(16)
      r4 = toolbar:layout_cut_right(16)
      r5 = toolbar:layout_cut_right(16)
    -- Two panel --
      layout = object():layout_lt(0, 0, 180, 128)
      top = layout:layout_cut_right(16)
      button_close = top:layout_cut_right(16)
      button_maximize = top:layout_cut_right(16)
      button_minimize = top:layout_cut_right(16)
      title = top
      bottom = layout:layout_cut_bottom(16)
      panel_left = layout:layout_cut_left(180/2)
      panel_right = layout
]]--
layout = class:class_new()
function layout:layout(x, y, w, h)
  self.tags.layout = true
  self.x, self.y = x, y
  self.w, self.h = w, h
  self.x1, self.y1 = self.x - self.w/2, self.y - self.h/2
  self.x2, self.y2 = self.x + self.w/2, self.y + self.h/2
  return self
end

function layout:layout_lt(x1, y1, w, h)
  self.tags.layout = true
  self.x1, self.y1 = x1, y1
  self.w, self.h = w, h
  self.x2, self.y2 = self.x1 + self.w, self.y1 + self.h
  self.x, self.y = self.x1 + self.w/2, self.y1 + self.h/2
  return self
end

--[[
  Cuts the layout from the left.
  The current layout's left side will be pushed to the right by v.
  The new layout's left side will be the current layout's old left side.
  The new layout's right side will be the current layout's new left side.
]]--
function layout:layout_cut_left(v, name)
  if self.x1 + v > self.x2 then error('Trying to cut more space than the layout has available. (' .. v .. ')') end
  local old_x1 = self.x1
  self.x1 = self.x1 + v
  self.w = self.x2 - self.x1
  self.x = self.x1 + self.w/2
  return object(name):layout_lt(old_x1, self.y1, self.x1-old_x1, self.y2-self.y1)
end

--[[
  Cuts the layout from the right.
  The current layout's right side will be pushed to the left by v.
  The new layout's right side will be the current layout's old right side.
  The new layout's left side will be the current layout's new right side.
]]--
function layout:layout_cut_right(v, name)
  if self.x2 - v < self.x1 then error('Trying to cut more space than the layout has available. (' .. v .. ')') end
  local old_x2 = self.x2
  self.x2 = self.x2 - v
  self.w = self.x2 - self.x1
  self.x = self.x1 + self.w/2
  return object(name):layout_lt(self.x2, self.y1, old_x2-self.x2, self.y2-self.y1)
end

--[[
  Cuts the layout from the top.
  The current layout's top side will be pushed down by v.
  The new layout's top side will be the current layout's old top side.
  The new layout's bottom side will be the current layout's new top side.
]]--
function layout:layout_cut_top(v, name)
  if self.y1 + v > self.y2 then error('Trying to cut more space than the layout has available. (' .. v .. ')') end
  local old_y1 = self.y1
  self.y1 = self.y1 + v
  self.h = self.y2 - self.y1
  self.y = self.y1 + self.h/2
  return object(name):layout_lt(self.x1, old_y1, self.x2-self.x1, self.y1-old_y1)
end

--[[
  Cuts the layout from the bottom.
  The current layout's bottom side will be pushed up by v.
  The new layout's bottom side will be the current layout's old bottom side.
  The new layout's top side will be the current layout's new bottom side.
]]--
function layout:layout_cut_bottom(v, name)
  if self.y2 - v < self.y1 then error('Trying to cut more space than the layout has available. (' .. v .. ')') end
  local old_y2 = self.y2
  self.y2 = self.y2 - v
  self.h = self.y2 - self.y1
  self.y = self.y1 + self.h/2
  return object(name):layout_lt(self.x1, self.y2, self.x2-self.x1, old_y2-self.y2)
end

--[[
  Returns a new object created with layout functions that mimics a grid.
  The number of columns and rows is given by the w and h values respectively.
  The size of each cell is calculated automatically based on the layout's initial size and the number of rows and columns.
  The name of colums follows the alphabet letters (A, B, C, ...) and the name of columns follows integers (1, 2, 3, ...).
  So when you get the layout object back (let's say you called it "frame"), if you want to refer to the second column of the top row, you'd go frame.B1.
--]]
function layout:layout_grid(w, h, name)
  local cell_w, cell_h = self.w/w, self.h/h
  local column_blocks = {}
  local letters = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'}
  for i = 1, w-1 do table.insert(column_blocks, self:layout_cut_left(cell_w)) end
  table.insert(column_blocks, self)
  for i, column_block in ipairs(column_blocks) do
    local letter = letters[i]
    for j = 1, h-1 do self:add(column_block:layout_cut_top(cell_h, letter .. j)) end
    column_block:rename(letter .. h)
    self:add(column_block)
  end
  return self
end
--]===]
