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
