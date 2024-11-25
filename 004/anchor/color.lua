--[[
  This module is responsible for creating color objects.
  The most important feature here is that each color automatically has 20 nearby colors accessible.
  For instance, suppose a color is created like this:
    c = object():color(0.5, 0.5, 0.5, 1, 0.02)
  This creates color object "c", and you can access the (0.5, 0.5, 0.5) color via c[0].
  Additionally, however, you also have access to c[-1] to c[-10] and c[1] to c[10]. These are colors created by incrementing the original color by the last argument (0.02) on each step.
  This makes it easy to access nearby colors for various purposes.
  You also have access to a color in its transparent versions via the .alpha attribute.
  For instance, "c.alpha[-5]" refers to c[0], but with its alpha value decreased by 5 alpha steps, so by 0.5 given the default alpha step is 0.1.
  Color values are always stored in the [0, 1] range, regardless of the range in which they were created.
]]--
color = class:class_new()

--[[
  Creates a new color object with r, g, b, a values in the [0, 1] range.
  Examples:
    white = object():color(1, 1, 1, 1, 0.025)
    black = object():color(0, 0, 0, 1, 0.025)
    gray = object():color(0.5, 0.5, 0.5, 1, 0.025)
]]--
function color:color(r, g, b, a, step, alpha_step)
  self.tags.color = true
  self.step = step
  self.alpha_step = alpha_step or 0.1

  for i = -20, 20, 1 do self[i] = {} end
  self[0].r = r
  self[0].g = g
  self[0].b = b
  self[0].a = a
  for i = -20, 20, 1 do
    if i < 0 or i > 0 then
      self[i].r = self[0].r
      self[i].g = self[0].g
      self[i].b = self[0].b
      self[i].a = self[0].a
      self:color_lighten(i, i*self.step)
    end
  end

  self.alpha = {}
  for i = -1, -10, -1 do
    self.alpha[i] = {r = self[0].r, g = self[0].g, b = self[0].b, a = self[0].a + i*self.alpha_step}
  end
  return self
end

--[[
  Creates a new color object with r, g, b, a values in the [0, 255] range.
  Examples:
    white = object():color_255(255, 255, 255, 255, 0.025)
    black = object():color_255(0, 0, 0, 255, 0.025)
    gray = object():color_255(128, 128, 128, 255, 0.025)
]]--
function color:color_255(r, g, b, a, step, alpha_step)
  self.tags.color = true
  self.step = step
  self.alpha_step = alpha_step or 0.1

  for i = -20, 20, 1 do self[i] = {} end
  self[0].r = r/255
  self[0].g = g/255
  self[0].b = b/255
  self[0].a = a/255
  for i = -20, 20, 1 do
    if i < 0 or i > 0 then
      self[i].r = self[0].r
      self[i].g = self[0].g
      self[i].b = self[0].b
      self[i].a = self[0].a
      self:color_lighten(i, i*self.step)
    end
  end

  self.alpha = {}
  for i = -1, -10, -1 do
    self.alpha[i] = {r = self[0].r, g = self[0].g, b = self[0].b, a = self[0].a + i*self.alpha_step}
  end
  return self
end

--[[
  Creates a new color object with r, g, b, a values as a hexadecimal string.
  Examples:
    white = object():color_hex('#ffffffff', 0.025)
    black = object():color_hex('#000000ff', 0.025)
    gray = object():color_hex('#808080ff', 0.025)
]]--
function color:color_hex(hex, step, alpha_step)
  self.tags.color = true
  self.step = step
  self.alpha_step = alpha_step or 0.1

  for i = -20, 20, 1 do self[i] = {} end
  local hex = hex:gsub('#', '')
  self[0].r = tonumber('0x' .. hex:sub(1, 2))/255
  self[0].g = tonumber('0x' .. hex:sub(3, 4))/255
  self[0].b = tonumber('0x' .. hex:sub(5, 6))/255
  self[0].a = tonumber('0x' .. hex:sub(7, 8))/255
  for i = -20, 20, 1 do
    if i < 0 or i > 0 then
      self[i].r = self[0].r
      self[i].g = self[0].g
      self[i].b = self[0].b
      self[i].a = self[0].a
      self:color_lighten(i, i*self.step)
    end
  end

  self.alpha = {}
  for i = -1, -10, -1 do
    self.alpha[i] = {r = self[0].r, g = self[0].g, b = self[0].b, a = self[0].a + i*self.alpha_step}
  end
  return self
end

--[[
  Creates a copy of the color with the given index.
  This is the same as "object():color(self.[i].r, self.[i].g, self.[i].b, self.[i].a, self.step)".
  Example:
    white = object():color_hex('#ffffffff', 0.025)
    white_2 = white:color_copy(0)
    white[0].r = 0
    print(white_2[0].r) -> prints 1
]]--
function color:color_copy(i)
  local i = i or 0
  return object():color(self[i].r, self[i].g, self[i].b, self[i].a, self.step, self.alpha_step)
end

function color:color_lighten(i, v)
  local h, s, l = self:color_to_hsl(i)
  l = l + v
  self[i].r, self[i].g, self[i].b = self:color_to_rgb(h, s, l)
  return self
end

--[[
  Returns a new color that is a mix of the color with the given index with another color "c".
  The color mix can be weighted by changing the first color's weight, which is 1 by default and can go to 0.
  Example:
    white = object():color(1, 1, 1, 1)
    red = object():color(1, 0, 0, 1)
    white_red = white:color_mix(0, red[0])
    print(white_red[0].r, white_red[0].g, white_red[0].b) -> prints 1, 0.5, 0.5, 1
    white_more_red = white:color_mix(0, red[0], 0.5)
    print(white_more_red[0].r, white_more_red[0].g, white_more_red[0].b) -> prints 1, 0.25, 0.25, 1
--]]
function color:color_mix(i, c, weight)
  local i = i or 0
  local weight = weight or 1
  return object():color((weight*self[i].r + c.r*(2-weight))/2, (weight*self[i].g + c.g*(2-weight))/2, (weight*self[i].b + c.b*(2-weight))/2,
    (weight*self[i].a + c.a*(2-weight))/2, self.step, self.alpha_step)
end

function color:color_to_hsl(i)
  local i = i or 0
  local max, min = math.max(self[i].r, self[i].g, self[i].b), math.min(self[i].r, self[i].g, self[i].b)
  local h, s, l = nil, nil, nil
  l = (max + min)/2
  if max == min then h, s = 0, 0
  else
    local d = max - min
    if l > 0.5 then s = d/(2 - max - min) else s = d/(max + min) end
    if max == self[i].r then
      h = (self[i].g - self[i].b)/d
      if self[i].g < self[i].b then h = h + 6 end
    elseif max == self[i].g then
      h = (self[i].b - self[i].r)/d + 2
    elseif max == self[i].b then
      h = (self[i].r - self[i].g)/d + 4
    end
    h = h/6
  end
  return h, s, l
end

function color:color_to_rgb(h, s, l)
  if s == 0 then return math.clamp(l, 0, 1), math.clamp(l, 0, 1), math.clamp(l, 0, 1) end
  local to = function(p, q, t)
    if t < 0 then t = t + 1 end
    if t > 1 then t = t - 1 end
    if t < .16667 then return p + (q - p)*6*t end
    if t < .5 then return q end
    if t < .66667 then return p + (q - p)*(.66667 - t)*6 end
    return p
  end
  local q = l < .5 and l*(1 + s) or l + s - l*s
  local p = 2*l - q
  return math.clamp(to(p, q, h + .33334), 0, 1), math.clamp(to(p, q, h), 0, 1), math.clamp(to(p, q, h - .33334), 0, 1)
end

--[[
  Returns the color with the given index as a Lua table.
  If the second argument is true, then it reads from the .alpha tables instead.
  Example:
    white = object():color_255(255, 255, 255, 255, 0.025)
    array.print(white:color_to_table())        -> prints '{[1] = 1, [2] = 1, [3] = 1, [4] = 1}'
    array.print(white:color_to_table(-5, true) -> prints '{[1] = 1, [2] = 1, [3] = 1, [4] = 0.5}'
]]--
function color:color_to_table(i, a)
  local i = i or 0
  if a then
    return {self.alpha[i].r, self.alpha[i].g, self.alpha[i].b, self.alpha[i].a}
  else
    return {self[i].r, self[i].g, self[i].b, self[i].a}
  end
end
