--[[
  Functions that call love.graphics.* functions are stored in this graphics table.
  When commands are queued, they're stored in each layer's .draw_commands table, and then when layer_draw_commands is called, that data is fed to these graphics.* functions to do the actual drawing.
  This is done this way so that I can tell the computer to draw from anywhere in the codebase without having to worry about where or the order in which those calls happen.
]]--
local graphics = {}

function graphics.arc(x, y, rs, r1, r2, arctype, color, line_width)
  graphics.shape('arc', color, line_width, arctype or 'pie', x, y, rs, r1, r2)
end

function graphics.circle(x, y, rs, color, line_width)
  graphics.shape('circle', color, line_width, x, y, rs)
end

function graphics.dashed_line(x1, y1, x2, y2, dash_size, gap_size, color, line_width)
  local r, g, b, a = love.graphics.getColor()
  if color then love.graphics.setColor(color.r, color.g, color.b, color.a) end
  if line_width then love.graphics.setLineWidth(line_width) end

  local line_angle, line_length = math.angle_to_point(x1, y1, x2, y2), math.distance(x1, y1, x2, y2)
  local dash_and_gap_count, remainder_length = math.modf(line_length/(dash_size + gap_size))
  if remainder_length >= dash_size then
    remainder_length = remainder_length - dash_size
    dash_and_gap_count = dash_and_gap_count + 1
  end
  local x1, y1 = x1 + 0.5*remainder_length*math.cos(line_angle), y1 + 0.5*remainder_length*math.sin(line_angle)
  local ox, oy = 0, 0
  for i = 1, dash_and_gap_count do
    love.graphics.line(x1 + ox, y1 + oy, x1 + dash_size*math.cos(line_angle) + ox, y1 + dash_size*math.sin(line_angle) + oy)
    ox, oy = ox + (dash_size + gap_size)*math.cos(line_angle), oy + (dash_size + gap_size)*math.sin(line_angle)
  end
end

function graphics.dashed_line_2(x1, y1, x2, y2, dash_size, gap_size, color, line_width)
  local r, g, b, a = love.graphics.getColor()
  if color then love.graphics.setColor(color.r, color.g, color.b, color.a) end
  if line_width then love.graphics.setLineWidth(line_width) end

  local line_angle, line_length = math.angle_to_point(x1, y1, x2, y2), math.distance(x1, y1, x2, y2)
  local gap_and_dash_count, remainder_length = math.modf(line_length/(dash_size + gap_size))
  if remainder_length >= gap_size then
    remainder_length = remainder_length - gap_size
    gap_and_dash_count = gap_and_dash_count + 1
  end
  local x1, y1 = x1 + 0.5*remainder_length*math.cos(line_angle), y1 + 0.5*remainder_length*math.sin(line_angle)
  local ox, oy = gap_size*math.cos(line_angle), gap_size*math.sin(line_angle)
  for i = 1, gap_and_dash_count do
    love.graphics.line(x1 + ox, y1 + oy, x1 + dash_size*math.cos(line_angle) + ox, y1 + dash_size*math.sin(line_angle) + oy)
    ox, oy = ox + (dash_size + gap_size)*math.cos(line_angle), oy + (dash_size + gap_size)*math.sin(line_angle)
  end
end

function graphics.dashed_rectangle(x, y, w, h, dash_size, gap_size, color, line_width)
  graphics.dashed_line(x-w/2, y-h/2, x+w/2, y-h/2, dash_size, gap_size, color, line_width)
  graphics.dashed_line(x+w/2, y-h/2, x+w/2, y+h/2, dash_size, gap_size, color, line_width)
  graphics.dashed_line(x+w/2, y+h/2, x-w/2, y+h/2, dash_size, gap_size, color, line_width)
  graphics.dashed_line(x-w/2, y+h/2, x-w/2, y-h/2, dash_size, gap_size, color, line_width)
end

function graphics.draw(drawable, x, y, r, sx, sy, ox, oy, color, shader)
  _r, g, b, a = love.graphics.getColor()
  if color then love.graphics.setColor(color.r, color.g, color.b, color.a) end
  if shader then love.graphics.setShader(an.shaders[shader].source) end
  love.graphics.draw(drawable.source, x, y, r or 0, sx or 1, sy or sx or 1, drawable.w*0.5 + (ox or 0), drawable.h*0.5 + (oy or 0))
  if shader then love.graphics.setShader() end
  if color then love.graphics.setColor(_r, g, b, a) end
end

function graphics.draw_animation(animation, x, y, r, sx, sy, ox, oy, color, shader)
  local af = animation.animation_frames
  local frame = animation.animation_frame
  graphics.draw_quad(af.source, af.frames[frame].quad, x, y, r or 0, sx or 1, sy or sx or 1, af.frames[frame].w/2 + (ox or 0),
    af.frames[frame].h/2 + (oy or 0), color, shader and an.shaders[shader].source)
end

function graphics.draw_animation_frames(name, frame, x, y, r, sx, sy, ox, oy, color, shader)
  local af = an._animation_frames[name]
  graphics.draw_quad(af.source, af.frames[frame].quad, x, y, r or 0, sx or 1, sy or sx or 1, af.frames[frame].w/2 + (ox or 0),
    af.frames[frame].h/2 + (oy or 0), color, shader and an.shaders[shader].source)
end

function graphics.draw_image(name, x, y, r, sx, sy, ox, oy, color, shader)
  local drawable = an.images[name]
  _r, g, b, a = love.graphics.getColor()
  if color then love.graphics.setColor(color.r, color.g, color.b, color.a) end
  if shader then love.graphics.setShader(an.shaders[shader].source) end
  love.graphics.draw(drawable.source, x, y, r or 0, sx or 1, sy or sx or 1, drawable.w*0.5 + (ox or 0), drawable.h*0.5 + (oy or 0))
  if shader then love.graphics.setShader() end
  if color then love.graphics.setColor(_r, g, b, a) end
end

function graphics.draw_quad(drawable, quad, x, y, r, sx, sy, ox, oy, color, shader)
  _r, g, b, a = love.graphics.getColor()
  if color then love.graphics.setColor(color.r, color.g, color.b, color.a) end
  if shader then love.graphics.setShader(an.shaders[shader].source) end
  love.graphics.draw(drawable.source, quad, x, y, r or 0, sx or 1, sy or sx or 1, (ox or 0), (oy or 0))
  if shader then love.graphics.setShader() end
  if color then love.graphics.setColor(_r, g, b, a) end
end

function graphics.draw_text(text, font_name, x, y, r, sx, sy, ox, oy, color)
  _r, g, b, a = love.graphics.getColor()
  if color then love.graphics.setColor(color.r, color.g, color.b, color.a) end
  love.graphics.print(text, an.fonts[font_name].source, x, y, r or 0, sx or 1, sy or sx or 1, (ox or 0) + an:font_get_text_width(font_name, text)/2,
    (oy or 0) + an.fonts[font_name].h/2)
  if color then love.graphics.setColor(_r, g, b, a) end
end

function graphics.draw_text_lt(text, font_name, x, y, r, sx, sy, ox, oy, color)
  _r, g, b, a = love.graphics.getColor()
  if color then love.graphics.setColor(color.r, color.g, color.b, color.a) end
  love.graphics.print(text, an.fonts[font_name].source, x, y, r or 0, sx or 1, sy or sx or 1, ox or 0, oy or 0)
  if color then love.graphics.setColor(_r, g, b, a) end
end

function graphics.ellipse(x, y, w, h, color, line_width)
  graphics.shape('ellipse', color, line_width, x, y, w, h)
end

function graphics.gapped_line(x1, y1, x2, y2, dash_size, gap_size, dash_amount, dash_position, color, line_width)
  local line_angle, line_length = math.angle_to_point(x1, y1, x2, y2), math.distance(x1, y1, x2, y2)
  local dash_amount = dash_amount or 0.2
  local dash_position = dash_position or 0.5
  local total_gap_size = line_length*dash_amount
  -- if total_gap_size <= dash_size then error("gapped_line's total gap size (" .. total_gap_size .. ") is smaller than the dash size (" .. dash_size .. ")") end
  --[[
  if 0.5*total_gap_size >= dash_position*line_length or 0.5*total_gap_size >= (1.0 - dash_position)*line_length then
    error("gapped_line's dash position (" .. dash_position .. ") is too close to one of the edges for the given total gap size (" .. total_gap_size .. ")")
  end
  ]]--

  local gap_x, gap_y = x1 + dash_position*line_length*math.cos(line_angle), y1 + dash_position*line_length*math.sin(line_angle)
  local gap_x1, gap_y1 = gap_x + 0.5*total_gap_size*math.cos(line_angle + math.pi), gap_y + 0.5*total_gap_size*math.sin(line_angle + math.pi)
  local gap_x2, gap_y2 = gap_x + 0.5*total_gap_size*math.cos(line_angle), gap_y + 0.5*total_gap_size*math.sin(line_angle)
  r, g, b, a = love.graphics.getColor()
  if color then love.graphics.setColor(color.r, color.g, color.b, color.a) end
  if line_width then love.graphics.setLineWidth(line_width) end
  love.graphics.line(x1, y1, gap_x1, gap_y1)
  graphics.dashed_line_2(gap_x1, gap_y1, gap_x2, gap_y2, dash_size, gap_size or dash_size, color, line_width)
  love.graphics.line(gap_x2, gap_y2, x2, y2)
  love.graphics.setColor(r, g, b, a)
  love.graphics.setLineWidth(1)
end

function graphics.line(x1, y1, x2, y2, color, line_width)
  r, g, b, a = love.graphics.getColor()
  if color then love.graphics.setColor(color.r, color.g, color.b, color.a) end
  if line_width then love.graphics.setLineWidth(line_width) end
  love.graphics.line(x1, y1, x2, y2)
  love.graphics.setColor(r, g, b, a)
  love.graphics.setLineWidth(1)
end

function graphics.push(x, y, r, sx, sy)
  love.graphics.push()
  love.graphics.translate(x or 0, y or 0)
  love.graphics.scale(sx or 1, sy or sx or 1)
  love.graphics.rotate(r or 0)
  love.graphics.translate(-(x or 0), -(y or 0))
end

function graphics.pop()
  love.graphics.pop()
end

function graphics.push_trs(x, y, r, sx, sy)
  love.graphics.push()
  if x and y then love.graphics.translate(x, y) end
  if sx then love.graphics.scale(sx, sy or sx or 1) end
  if r then love.graphics.rotate(r) end
end

function graphics.polygon(vertices, color, line_width)
  graphics.shape('polygon', color, line_width, vertices)
end

function graphics.polyline(vertices, color, line_width)
  r, g, b, a = love.graphics.getColor()
  if color then love.graphics.setColor(color.r, color.g, color.b, color.a) end
  if line_width then love.graphics.setLineWidth(line_width) end
  love.graphics.line(unpack(vertices))
  love.graphics.setColor(r, g, b, a)
  love.graphics.setLineWidth(1)
end

function graphics.rectangle(x, y, w, h, rx, ry, color, line_width)
  graphics.shape('rectangle', color, line_width, x - w/2, y - h/2, w, h, rx, ry)
end

function graphics.rectangle_lt(x, y, w, h, rx, ry, color, line_width)
  graphics.shape('rectangle', color, line_width, x, y, w, h, rx, ry)
end

function graphics.set_blend_mode(mode, alpha_mode)
  love.graphics.setBlendMode(mode or 'alpha', alpha_mode or 'alphamultiply')
end

function graphics.set_color(color)
  love.graphics.setColor(color.r, color.g, color.b, color.a)
end

function graphics.shader_send(name, id, ...)
  an.shaders[name].source:send(id, ...)
end

function graphics.shape(shape, color, line_width, ...)
  r, g, b, a = love.graphics.getColor()
  if not color and not line_width then
    love.graphics[shape]('line', ...)
  elseif color and not line_width then
    love.graphics.setColor(color.r, color.g, color.b, color.a)
    love.graphics[shape]('fill', ...)
  else
    if color then love.graphics.setColor(color.r, color.g, color.b, color.a) end
    if line_width then love.graphics.setLineWidth(line_width) end
    love.graphics[shape]('line', ...)
    love.graphics.setLineWidth(1)
  end
  love.graphics.setColor(r, g, b, a)
end

function graphics.translate(x, y)
  love.graphics.translate(x, y)
end

function graphics.triangle(x, y, w, color, line_width)
  local h = math.sqrt(math.pow(w, 2) - math.pow(w/2, 2))
  local x1, y1 = x + h/2, y
  local x2, y2 = x - h/2, y - w/2
  local x3, y3 = x - h/2, y + w/2
  graphics.polygon({x1, y1, x2, y2, x3, y3}, color, line_width)
end

--[[
  Module responsible for anything drawing related. This module is the only way you can draw something to the screen.
  Draw commands are sent to the layer's queue of commands and then drawn to a canvas at the end of the frame.
  Create a new layer like this:
    game = object():layer()
  And then in an update function somewhere:
    game:circle(50, 50, 10, an.colors.white[0])
  This sends a draw command to the "game" layer telling it to draw a circle at 50, 50 with radius 10 and white color.
  At the end of the frame, .the circle is drawn and all draw commands cleared so they can be added anew next frame.
  Layers are drawn in the order they were created by default, but this can be changed by modifying the "draw_layers" function.

  The default draw_layers function looks like this:
    for layer in self.layers
      self:layer_draw_to_canvas('main', function()
        layer:layer_draw_commands()
        layer:layer_draw()
      end)
    self:layer_draw('main', 0, 0, 0, 1, 1)
  It loops through all layers, and calls a few functions that will draw the layer's contents to the the screen.
  Every canvas inside a layer has a name attached to it, and by default every layer has one named 'main'.
  layer_draw_to_canvas draws the action passed in to the canvas specified, in this case 'main' for the self layer.
  layer_draw_commands draws the queued commands to the given layer's 'main' canvas (when no other name is specified).
  layer_draw draws the actual 'main' canvas, so it should generally be called after layer_draw_commands.
  And so the function above is drawing each layer to this layer's 'main' canvas, and then this layer's 'main' canvas
  is being drawn to the screen using layer_draw.

  Understanding this module is necessary if you want to do anything visually with this framework, so I'd recommend looking
  at how I use it in various games and going from there. Especially look at how I overwrite the draw_layers function, since
  that's the main way in which you can change the way layers are drawn to the screen.

  It's also important to note that the engine's loop calls "an:draw_layers" to draw everything. So this is the function
  that needs to be overwritten, and ultimately all layers have to draw to to an's 'main' canvas. The example above is doing
  that, assuming that self. is an, which it is, because an was also initialized as a layer when it was created.
--]]
layer = class:class_new()
function layer:layer(layer_camera)
  self.tags.layer = true
  self.layer_camera = an 

  self.canvas = {}
  self.draw_commands = {}
  self:layer_add_canvas('main')
  table.insert(an.layers, self)
  return self
end

--[[
  Adds a new canvas to the layer.
  This canvas can be later referred to by self.canvas[name].
  A default canvas named 'main' is added to every layer.
  Example:
    game = object():layer()
    game:layer_add_canvas('outline')
]]--
function layer:layer_add_canvas(name)
  self.canvas[name] = love.graphics.newCanvas(an.w, an.h)
end

--[[
  Draws the canvas identified by the given name.
  color, shader and alphamultiply are optional arguments that change how the canvas is drawn.
  In general, you want canvasses to be drawn with alphamultiply as true when they're being drawn to another canvas.
]]--
function layer:layer_draw(name, x, y, r, sx, sy, color, shader, alphamultiply)
  local color = color or an.colors.white[0]
  if shader then love.graphics.setShader(an.shaders[shader].source) end
  if alphamultiply then
    love.graphics.setColor(color.r, color.g, color.b, color.a)
    love.graphics.draw(self.canvas[name or 'main'], x or self.x or 0, y or self.y or 0, r or 0, sx or 1, sy or sx or 1)
  else
    love.graphics.setColor(color.r, color.g, color.b, color.a)
    love.graphics.setBlendMode('alpha', 'premultiplied')
    love.graphics.draw(self.canvas[name or 'main'], x or self.x or 0, y or self.y or 0, r or 0, sx or 1, sy or sx or 1)
    love.graphics.setBlendMode('alpha')
  end
  love.graphics.setColor(1, 1, 1, 1)
  if shader then love.graphics.setShader() end
end

--[[
  Draws queued commands to the canvas identified by the given name.
  Ideally you want to call this once per frame, since then you can use the results by accessing the canvas (self.canvas[name]).
]]--
local z_sort = function(a, b) return a.z < b.z end
function layer:layer_draw_commands(name, dont_clear)
  self:layer_draw_to_canvas(name or 'main', function()
    self.layer_camera:camera_attach()
    table.stable_sort(self.draw_commands, z_sort)
    for _, command in ipairs(self.draw_commands) do
      if type(command.type) == 'string' then
        graphics[command.type](unpack(command.args))
      else
        command.type(unpack(command.args))
      end
    end
    self.layer_camera:camera_detach()
  end, dont_clear)
end

--[[
  Draws the given action function to the canvas identified by the given name.
  If you want to avoid queueing commands, you can call love.graphics.* functions directly here and everything will work fine.
]]--
function layer:layer_draw_to_canvas(name, action, dont_clear)
  love.graphics.setCanvas({self.canvas[name or 'main'], stencil=true})
  if not dont_clear then love.graphics.clear() end
  action()
  love.graphics.setCanvas()
end

--[[
  The default way in which layers are drawn to the screen. Overwrite this to draw your layers in another way.
  The only thing that matters here is that ultimately some canvas is drawn to the screen using layer_draw.
  This is the only function that gets called by the engine's game loop when the time comes to draw the game.
]]--
function layer:draw_layers()
  for _, layer in ipairs(self.layers) do
    if not layer:is('anchor') then
      layer:layer_draw_commands()
    end
  end
  for _, layer in ipairs(self.layers) do
    if not layer:is('anchor') then
      self:layer_draw_to_canvas('main', function()
        layer:layer_draw()
      end)
    end
  end
  self:layer_draw('main', 0, 0, 0, self.sx, self.sy)
end


--[[
  Draws an arc at position x, y. The arc is drawn from angle r1 to angle r2, and with the given radius rs.
  "arctype" can be 'pie', 'open' or 'closed', see https://love2d.org/wiki/ArcType for more details.
  If color is passed in then the arrow will be filled with that color.
  If line_width is passed in then the arrow will not be filled and will instead be drawn as lines of the given width.
  TODO: examples
--]]
function layer:arc(x, y, rs, r1, r2, arctype, color, line_width, z)
  table.insert(self.draw_commands, {type = 'arc', args = {x, y, rs, r1, r2, arctype, color, line_width}, z = z or 0})
end

--[[
  Draws an arrow pointing right centered on x, y with w height (distance from base to tip).
  If color is passed in then the arrow will be filled with that color.
  If line_width is passed in then the arrow will not be filled and will instead be drawn as lines of the given width.
  Examples:
    x, y = an.w/2, an.h/2
    game = object():layer()
    game:arrow(x, y, 10, an.colors.white[0])       -> draws a filled white arrow on the center of the screen
    game:arrow(x, y, 10, an.colors.white[0], 1)    -> draws an unfilled white arrow on the center of the screen
    game:push(x, y, math.pi/2)
    game:arrow(x, y, 10, an.colors.white[0])
    game:pop()                                      -> draws the arrow pointing down instead of right
]]--
function layer:arrow(x, y, w, color, line_width, z)
  table.insert(self.draw_commands, {type = 'polyline', args = {{x, y - w/2, x + w/2, y, x, y + w/2}, color, line_width}, z = z or 0})
end


--[[
  Draws a circle of radius rs centered on x, y.
  If color is passed in then the circle will be filled with that color.
  If line_width is passed in then the circle will not be filled and will instead be drawn as lines of the given width.
  Examples:
    x, y = an.w/2, an.h/2
    game = object():layer()
    game:circle(x, y, 10, an.colors.white[0])     -> draws a filled white circle at the center of the screen
    game:circle(x, y, 10, an.colors.white[0], 1)  -> draws an unfilled white circle at the center of the screen
]]--
function layer:circle(x, y, rs, color, line_width, z)
  table.insert(self.draw_commands, {type = 'circle', args = {x, y, rs, color, line_width}, z = z or 0})
end

--[[
  Draws a dashed line with the given points.
  dash_size and gap_size correspond to the size of the dashing behavior.
  If color is passed in then the line is drawn with that color.
  If line_width is passed in then that will be the line's width, it's 1 by default.
  TODO: examples
--]]
function layer:dashed_line(x1, y1, x2, y2, dash_size, gap_size, color, line_width, z)
  table.insert(self.draw_commands, {type = 'dashed_line', args = {x1, y1, x2, y2, dash_size, gap_size, color, line_width}, z = z or 0})
end

--[[
  Exactly the same as dashed_line, except starts the dashed line from a gap instead of a dash.
--]]
function layer:dashed_line_2(x1, y1, x2, y2, dash_size, gap_size, color, line_width, z)
  table.insert(self.draw_commands, {type = 'dashed_line', args = {x1, y1, x2, y2, dash_size, gap_size, color, line_width}, z = z or 0})
end

--[[
  Draws a dashed rectangle centered on x, y with size w, h.
  dash_size and gap_size correspond to the size of the dashing behavior.
  If color is passed in then the line is drawn with that color.
  If line_width is passed in then that will be the line's width, it's 1 by default.
  TODO: examples
--]]
function layer:dashed_rectangle(x, y, w, h, dash_size, gap_size, color, line_width, z)
  table.insert(self.draw_commands, {type = 'dashed_rectangle', args = {x, y, w, h, dash_size, gap_size, color, line_width}, z = z or 0})
end


--[[
  Draws a drawable centered on x, y.
  If color is passed in then it will tint the image.
  If shader is passed in the it will be applied before the image is drawn.
  Example:
    game = object():layer()
    game:draw(an.images.smile, an.w/2, an.h/2) -> draws the image on the center of the screen
    
]]--
function layer:draw(drawable, x, y, r, sx, sy, ox, oy, color, shader, z)
  table.insert(self.draw_commands, {type = 'draw', args = {drawable, x, y, r, sx, sy, ox, oy, color, shader}, z = z or 0})
end

--[[
  Draws an animation object centered on x, y.
  If color is passed in then it will tint the image.
  If shader is passed in the it will be applied before the image is drawn.
  TODO: examples
--]]
function layer:draw_animation(animation, x, y, r, sx, sy, ox, oy, color, shader, z)
  table.insert(self.draw_commands, {type = 'draw_animation', args = {animation, x, y, r, sx, sy, ox, oy, color, shader}, z = z or 0})
end

--[[
  Draws an animation frames object centered on x, y.
  If color is passed in then it will tint the image.
  If shader is passed in the it will be applied before the image is drawn.
  In general you shouldn't call this function yourself since animation objects do it internally on update.
  TODO: examples
]]--
function layer:draw_animation_frames(name, frame, x, y, r, sx, sy, ox, oy, color, shader, z)
  table.insert(self.draw_commands, {type = 'draw_animation_frames', args = {name, frame, x, y, r, sx, sy, ox, oy, color, shader}, z = z or 0})
end

--[[
  Draws an image centered on x, y.
  If color is passed in then it will tint the image.
  If shader is passed in the it will be applied before the image is drawn.
  Example:
    game = object():layer()
    game:draw_image('smile', an.w/2, an.h/2) -> draws the image on the center of the screen
    
]]--
function layer:draw_image(name, x, y, r, sx, sy, ox, oy, color, shader, z)
  table.insert(self.draw_commands, {type = 'draw_image', args = {name, x, y, r, sx, sy, ox, oy, color, shader}, z = z or 0})
end

--[[
  Draws text centered on x, y with the given font.
  This is a quick alternative to using the text module.
  The font used must have been loaded first using "an:font".
  Example:
    game = object():layer()
    game:draw_text('some text', 'quicksand', an.w/2, an.h/2) -> draws 'some text' on the center of the screen
]]--
function layer:draw_text(text, font_name, x, y, r, sx, sy, ox, oy, color, z)
  table.insert(self.draw_commands, {type = 'draw_text', args = {text, font_name, x, y, r, sx, sy, ox, oy, color}, z = z or 0})
end

--[[
  Exactly the same as "text" but drawing from the text's top-left corner instead.
  This is useful when you want to draw text but you only have values for its top-left corner and not its center.
  This is also the exactly same as calling "draw_text" with x - an:font_get_text_width(font, text)/2 and y - font.h/2 as x and y.
]]--
function layer:draw_text_lt(text, font_name, x, y, r, sx, sy, ox, oy, color, z)
  table.insert(self.draw_commands, {type = 'draw_text_lt', args = {text, font_name, x, y, r, sx, sy, ox, oy, color}, z = z or 0})
end

--[[
  Draws an ellipse at the given positions.
  If color is passed in then the line is drawn with that color.
  If line_width is passed in then that will be the line's width, it's 1 by default.
  TODO: examples
]]--
function layer:ellipse(x, y, w, h, color, line_width, z)
  table.insert(self.draw_commands, {type = 'ellipse', args = {x, y, w, h, color, line_width}, z = z or 0})
end

--[[
  Draws a line where a section of it (by default its middle) is drawn as a dashed line.
  dash_size controls the size of each dash inside the gap, and dash amount controls the percentage of the line's length that should be the gap (0.2 by default, valid values from 0 to 1).
  dash_position is also a value from 0 to 1 that says where in the line the gap will appear, by default this value is 0.5 (middle).
--]]
function layer:gapped_line(x1, y1, x2, y2, dash_size, gap_size, dash_amount, dash_position, color, line_width, z)
  table.insert(self.draw_commands, {type = 'gapped_line', args = {x1, y1, x2, y2, dash_size, gap_size, dash_amount, dash_position, color, line_width}, z = z or 0})
end

--[[
  Draws a line at the given positions.
  If color is passed in then the line is drawn with that color.
  If line_width is passed in then that will be the line's width, it's 1 by default.
  TODO: examples
]]--
function layer:line(x1, y1, x2, y2, color, line_width, z)
  table.insert(self.draw_commands, {type = 'line', args = {x1, y1, x2, y2, color, line_width}, z = z or 0})
end

--[[
  Draws a polygon with the given vertices.
  If color is passed in then the polygon will be filled with that color.
  If line_width is passed in then the polygon will not be filled and will instead be drawn as lines of the given width.
  TODO: examples
]]--
function layer:polygon(vertices, color, line_width, z)
  table.insert(self.draw_commands, {type = 'polygon', args = {vertices, color, line_width}, z = z or 0})
end

--[[
  Draws multiple lines connecting the vertices.
  If color is passed in then the lines are drawn with that color.
  If line_width is passed in then that will be the width for all lines, it's 1 by default.
  TODO: examples
]]--
function layer:polyline(vertices, color, line_width, z)
  table.insert(self.draw_commands, {type = 'polyline', args = {vertices, color, line_width}, z = z or 0})
end

--[[
  All operations drawn from this call will be affected by the given transform.
  This is generally useful when you want to rotate or scale objects around a certain pivot other than their center.
]]--
function layer:push(x, y, r, sx, sy, z)
  table.insert(self.draw_commands, {type = 'push', args = {x, y, r, sx, sy}, z = z or 0})
end

--[[
  All operations drawn from this call will be affected by the given transform.
  This is the same as push except it doesn't translate back to the origin after rotating and scaling.
  This is generally useful when you want to also translate objects around another position.
]]--
function layer:push_trs(x, y, r, sx, sy, z)
  table.insert(self.draw_commands, {type = 'push_trs', args = {x, y, r, sx, sy}, z = z or 0})
end

--[[
  All operations will cease being affected by the transform set by the previous push call.
  Multiple pushes and pops can be stacked, but each push must be matched by one pop, or an error will happen.
]]--
function layer:pop(z)
  table.insert(self.draw_commands, {type = 'pop', args = {}, z = z or 0})
end

--[[
  Draws a rectangle of size w, h centered on x, y.
  If rx, ry are passed in then the rectangle will have rounded corners with radius of that size.
  If color is passed in then the rectangle will be filled with that color.
  If line_width is passed in then the rectangle will not be filled and will instead be drawn as lines of the given width.
  Examples:
    x, y = an.w/2, an.h/2
    game = object():layer()
    game:rectangle(x, y, 50, 50, 0, 0, an.colors.white[0])    -> draws a white filled rectangle on the center of the screen
    game:rectangle(x, y, 50, 50, 5, 5, an.colors.white[0])    -> same as above but with rounded corners of radius 5
    game:rectangle(x, y, 50, 50, 5, 5, an.colors.white[0], 2) -> same as above but not filled and with line width of 2
]]--
function layer:rectangle(x, y, w, h, rx, ry, color, line_width, z)
  table.insert(self.draw_commands, {type = 'rectangle', args = {x, y, w, h, rx, ry, color, line_width}, z = z or 0})
end

--[[
  Exactly the same as "rectangle" but drawing from the rectangle's top-left corner instead.
  This is useful when you want to draw a rectangle but you only have values for its top-left corner and not its center.
  This is also exactly the same as calling "rectangle" but with x - w/2 and y - h/2 as x and y.
]]--
function layer:rectangle_lt(x, y, w, h, rx, ry, color, line_width, z)
  table.insert(self.draw_commands, {type = 'rectangle_lt', args = {x, y, w, h, rx, ry, color, line_width}, z = z or 0})
end

--[[
  All operations drawn from this call will be affected by the given blend mode.
  See more here: https://love2d.org/wiki/BlendMode
]]--
function layer:set_blend_mode(mode, alpha_mode, z)
  table.insert(self.draw_commands, {type = 'set_blend_mode', args = {mode, alpha_mode}, z = z or 0})
end

--[[
  All operations drawn from this call will be affected by the given color.
  Colors are by default stored in the an.colors table, see the anchor/init.lua file in the colors/themes section for more detail.
]]--
function layer:set_color(color, z)
  table.insert(self.draw_commands, {type = 'set_color', args = {color}, z = z or 0})
end

--[[
  Sends values to the shader with the given name and to the variable with the given identifier.
  See https://love2d.org/wiki/Shader:send for more information.
  This should be used when "an:shader_send" doesn't work because you need to send different values to the shader in different parts of a frame.
function layer:shader_send(name, id, ...)
  table.insert(self.draw_commands, {type = 'shader_send', args = {name, id, ...}})
end
--]]

--[[
  Draws an equilateral triangle with size w centered on x, y pointed to the right (angle 0).
  If color is passed in then the triangle will be filled with that color.
  If line_width is passed in then the triangle will not be filled and will instead be drawn as lines of the given width.
--]]
function layer:triangle(x, y, w, color, line_width, z)
  table.insert(self.draw_commands, {type = 'triangle', args = {x, y, w, color, line_width}, z = z or 0})
end
