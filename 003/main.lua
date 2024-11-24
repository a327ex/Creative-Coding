require 'anchor'

function init()
  an:anchor_start('003', 256, 168, 3, 3, 'snkrx')
  an:input_bind_all()

  an:font('Fixedsys', 'assets/FSEX300.ttf', 12)

  back = object():layer()
  game = object():layer()
  game_2 = object():layer()
  front = object():layer()

  function an:draw_layers()
    back:layer_draw_commands()
    game:layer_draw_commands()
    game_2:layer_draw_commands(nil, an.arena)
    front:layer_draw_commands()

    self:layer_draw_to_canvas('main', function()
      back:layer_draw()
      game:layer_draw()
      game_2:layer_draw()
      front:layer_draw()
    end)

    self:layer_draw('main', 0, 0, 0, self.sx, self.sy)
  end

  an:physics_world(32, 0, 32)
  an:physics_world_set_physics_tags({'main', 'solid'})
  an:action(function()
    if an:is_pressed('j') then
      if an.arena then an.arena.dead = true
      else an:add(arena()) end
    end
  end)
end

arena = class:class_new(object)
function arena:new(x, y, args)
  self:object('arena', args)
  self:add(solid(an.w/2, an.h - 10, {w = an.w, h = 20}))
  self:add(branch(an.w/2, an.h - 20, {solid = self.solid}))
end

function arena:update(dt)
  if an:is_down('k') then
    for _, line in ipairs(self.branch.lines.children) do
      line:collider_apply_force(an:random_float(10, 20), 0)
    end
  end
  if an:is_pressed('l') then
    self.branch:die()
  end
  back:rectangle(an.w/2, an.h/2, an.w, an.h, 0, 0, an.colors.bg[-5])
end


branch = class:class_new(object)
function branch:new(x, y, args)
  self:object('branch', args)
  self.x, self.y = x, y
  self:add(object('lines'))
  self:add(object('joints'))

  self.current_r = -math.pi/2
  self.next_line_length = an:random_float(10, 12)
  self.previous_joint_object = self.solid
  self.joint_limit = 0
  for i = 1, 12 do self:add_line() end

  self.previous_p = {}
  for i = 1, 3 do table.insert(self.previous_p, {x = self.lines.children[12].x2, y = self.lines.children[12].y2}) end
  self.draw_color = an.colors.white:color_copy(0)[0]
  self.draw_color.a = 0
  self:timer()
  local colors = {'white', 'red', 'orange', 'yellow', 'green', 'blue', 'purple'}
  self.color_index = 1
  self:timer_every(1, function()
    self.color_index = self.color_index + 1
    if self.color_index > #colors then self.color_index = 1 end
    local c = an.colors[colors[self.color_index]][0]
    self:timer_tween(1, self.draw_color, {r = c.r, g = c.g, b = c.b}, math.linear)
  end)
end


function branch:update(dt)
  local l = self.lines.children[12]
  local x1, y1 = self.previous_p[3].x, self.previous_p[3].y
  local x2, y2 = self.previous_p[2].x, self.previous_p[2].y
  local x3, y3 = self.previous_p[1].x, self.previous_p[1].y
  local x4, y4 = l.x2, l.y2
  local a = math.clamp(math.sine_out(math.remap(math.distance(x1, y1, x2, y2), 0, 13, 0, 1)), 0, 1)
  self.draw_color.a = a
  game_2:polyline({x1, y1, x2, y2, x3, y3, x4, y4}, self.draw_color, 1)

  table.insert(self.previous_p, 1, {x = x4, y = y4})
  if #self.previous_p > 3 then self.previous_p[4] = nil end
end

function branch:add_line()
  local x1, y1, x2, y2 = self.x, self.y, self.x + self.next_line_length*math.cos(self.current_r), self.y + self.next_line_length*math.sin(self.current_r)
  local l = line(x1, y1, x2, y2, {index = #self.lines.children})
  self.lines:add(l)
  local j = object():joint('revolute', self.previous_joint_object, l, x1, y1)
  j:revolute_joint_set_limits_enabled(true)
  j:revolute_joint_set_limits(-self.joint_limit, self.joint_limit)
  self.joints:add(j)
  self.x, self.y = x2, y2
  self.next_line_length = an:random_float(10, 12)
  self.previous_joint_object = l
  self.joint_limit = self.joint_limit + an:random_float(0, math.pi/128)
  self.current_r = self.current_r + an:random_float(-math.pi/32, math.pi/32)
end

function branch:die()
  self.joints.children[1]:revolute_joint_set_limits_enabled(false)
  for _, line in ipairs(self.lines.children) do line:die() end
end


line = class:class_new(object)
function line:new(x1, y1, x2, y2, args)
  self:object(nil, args)
  self.x1, self.y1, self.x2, self.y2 = x1, y1, x2, y2
  self.x, self.y = (self.x1 + self.x2)/2, (self.y1 + self.y2)/2
  self.r = math.angle_to_point(self.x1, self.y1, self.x2, self.y2)
  self.w, self.h = math.distance(self.x1, self.y1, self.x2, self.y2), 1
  self:collider('main', 'dynamic', 'rectangle', self.w, self.h)
  self:collider_set_angle(self.r)

  self:timer()
  self.draw_color = an.colors.white:color_copy(0)[0]
  self.draw_color.a = math.remap(self.index, 1, 12, 1, 0.5)
end

function line:update(dt)
  self:collider_update_transform()
  self.x1, self.y1 = self.x + 0.5*self.w*math.cos(self.r + math.pi/2), self.y + 0.5*self.w*math.sin(self.r + math.pi/2)
  self.x2, self.y2 = self.x + 0.5*self.w*math.cos(self.r), self.y + 0.5*self.w*math.sin(self.r)
  game:push(self.x, self.y, self.r)
  game:rectangle(self.x, self.y, self.w, self.h, 0, 0, self.draw_color)
  game:pop()
end

function line:die()
  self:timer_tween(2, self.draw_color, {a = 0.25}, math.linear, nil, 'die')
end


solid = class:class_new(object)
function solid:new(x, y, args)
  self:object('solid', args)
  self.x, self.y = x, y
  self.color = an.colors.white[0]
  self:collider('solid', 'static', 'rectangle', self.w, self.h)
end

function solid:update(dt)
  -- front:rectangle(self.x, self.y, self.w, self.h, 0, 0, self.color)
end
