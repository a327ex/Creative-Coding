require 'anchor'

function init()
  an:anchor_start('001', 512, 512, 2, 2, 'twitter_emoji')
  an:input_bind_all()

  an:shader('replace', nil, [[
    vec4 effect(vec4 color, Image texture, vec2 tc, vec2 pc) {
      return vec4(color.rgb, Texel(texture, tc).a);
    }
  ]])

  an:shader('shadow', nil, [[
    vec4 effect(vec4 color, Image texture, vec2 tc, vec2 pc) {
      return vec4(0.15, 0.15, 0.15, Texel(texture, tc).a*0.5);
    }
  ]])

  an:font('JPN12', 'assets/Mx437_DOS-V_re_JPN12.ttf', 12)
  an:font('FatPixel', 'assets/FatPixelFont.ttf', 8)
  an:image('hit_effect', 'assets/hit_effect.png')
  an:animation_frames('hit_effect', 'hit_effect', 96, 48)

  back = object():layer()
  shadow = object():layer()
  game_1 = object():layer()
  game_2 = object():layer()
  effects = object():layer()
  front = object():layer()
  ui = object():layer()

  function an:draw_layers()
    back:layer_draw_commands()
    game_1:layer_draw_commands()
    game_2:layer_draw_commands()
    effects:layer_draw_commands()
    front:layer_draw_commands()
    ui:layer_draw_commands()

    shadow:layer_draw_to_canvas('main', function()
      game_1:layer_draw('main', 0, 0, 0, 1, 1, an.colors.white[0], 'shadow', true)
      game_2:layer_draw('main', 0, 0, 0, 1, 1, an.colors.white[0], 'shadow', true)
      effects:layer_draw('main', 0, 0, 0, 1, 1, an.colors.white[0], 'shadow', true)
      front:layer_draw('main', 0, 0, 0, 1, 1, an.colors.white[0], 'shadow', true)
      ui:layer_draw('main', 0, 0, 0, 1, 1, an.colors.white[0], 'shadow', true)
    end)

    self:layer_draw_to_canvas('main', function()
      back:layer_draw()
      shadow.x, shadow.y = 1.5, 1.5
      shadow:layer_draw()
      game_1:layer_draw()
      game_2:layer_draw()
      effects:layer_draw()
      front:layer_draw()
      ui:layer_draw()
    end)

    self:layer_draw('main', 0, 0, 0, self.sx, self.sy)
  end

  an:physics_world(128, 0, 0)
  an:physics_world_set_physics_tags({'node', 'solid'})

  flash_color = an.colors.white[0]
  an:action(function(self, dt)
    if an:is_pressed('k') then
      an:add(arena())
    end
    if an:is_pressed('l') then
      an.arena.dead = true
    end
  end)
end

arena = class:class_new(object)
function arena:new(x, y, args)
  self:object('arena', args)
  self:timer()
  self:add(object('nodes'))
  self:add(object('lines'))
  self:add(solid(-10, an.h/2, {w = 20, h = an.h}))
  self:add(solid(an.w + 10, an.h/2, {w = 20, h = an.h}))
  self:add(solid(an.w/2, -10, {w = an.w, h = 20}))
  self:add(solid(an.w/2, an.h + 10, {w = an.w, h = 20}))
  self.node_collisions = {}
  self.arena_time = 0

  local points = math.generate_poisson_disc_sampled_points_2d(an.w/2, an.h/2, an.w - 32, an.h - 32, 32)
  for i = 1, 40 do
    local point = array.remove_random(points)
    self.nodes:add(node(point.x, point.y))
  end

  self.flow_field = object():grid(32, 32):grid_set_dimensions(an.w/2, an.h/2, 16, 16)
  for i, j, v in self.flow_field:grid_pairs() do
    local x, y = self.flow_field:grid_get_cell_position(i, j)
    self.flow_field:grid_set(i, j, math.angle_to_point(x, y, self.flow_field.x, self.flow_field.y) + math.pi/2 - math.pi/32)
  end
  self.added_flow_field_angle = 0
  self.square_xs = {10, an.w - 10, 10, an.w - 10}
  self.square_ys = {10, 10, an.h - 10, an.h - 10}
  self.square_index = 1
end

function arena:update(dt)
  self.arena_time = self.arena_time + dt
  if self.arena_time >= 25 then self.added_flow_field_angle = self.added_flow_field_angle - 2.0e-5*dt end

  print(self.arena_time)

  for _, c in ipairs(an:physics_world_get_collision_enter('node', 'node')) do self:merge_nodes(c.a, c.b, c.x1, c.y1) end
  back:rectangle(an.w/2, an.h/2, 2*an.w, 2*an.h, 0, 0, an.colors.black[0])

  for i, j, v in self.flow_field:grid_pairs() do
    local v = self.flow_field:grid_get(i, j)
    self.flow_field:grid_set(i, j, v + self.added_flow_field_angle)
    v = self.flow_field:grid_get(i, j)
    local x, y = self.flow_field:grid_get_cell_position(i, j)
    --[[
    back:push(x, y, v)
    back:arrow(x, y, 8, an.colors.white.alpha[-9])
    back:pop()
    ]]--
  end

end

function arena:is_line_valid(n1, n2)
  local x1, y1, x2, y2 = n1.x, n1.y, n2.x, n2.y
  local r = math.angle_to_point(x1, y1, x2, y2)
  x1, y1 = x1 + 2*math.cos(r), y1 + 2*math.sin(r)
  x2, y2 = x2 + 2*math.cos(r + math.pi), y2 + 2*math.sin(r + math.pi)
  for _, line in ipairs(self.lines.children) do
    if collision.line_line(x1, y1, x2, y2, line.x1, line.y1, line.x2, line.y2) or line.src == n1 and line.dst == n2 or line.dst == n1 and line.src == n2 then
      return false
    end
  end
  return true
end

function arena:merge_nodes(a, b, x, y)
  if not self.node_collisions[a.id] then self.node_collisions[a.id] = {} end
  if not self.node_collisions[b.id] then self.node_collisions[b.id] = {} end
  if self.node_collisions[a.id][b.id] or self.node_collisions[b.id][a.id] then return end
  self.node_collisions[a.id][b.id] = true
  self.node_collisions[b.id][a.id] = true

  for _, line in ipairs(self.lines.children) do
    if line.src == a or line.src == b or line.dst == a or line.dst == b then
      line.dead = true
      line:timer_cancel('die')
    end
  end

  a.dead = true
  b.dead = true
  local target = a.rs >= b.rs and a or b
  self:add(node_merge_effect(a.x, a.y, {target_x = target.x, target_y = target.y, rs = a.rs}))
  self:add(node_merge_effect(b.x, b.y, {target_x = target.x, target_y = target.y, rs = b.rs}))

  self:timer_after(0.15, function()
    local n = node(x, y, {rs = math.max(a.rs, b.rs) + math.min(a.rs, b.rs)/8, from_merge = true})
    self.nodes:add(n)
    for i = 1, math.round(math.remap(n.rs, 12, 25, 3, 9), 0) do
      local r = an:random_angle()
      self:add(hit_particle(x + n.rs*math.cos(r), y + n.rs*math.sin(r), {v = math.remap(n.rs, 12, 25, 1, 2)*an:random_float(50, 150), r = r, 
        duration = an:random_float(0.2, 0.5)*math.remap(n.rs, 12, 25, 1, 3)}))
    end
  end)

  self:add(squares_with_fading_line(self.square_xs[self.square_index], self.square_ys[self.square_index], {direction = (self.square_index == 1 or self.square_index == 2) and 1 or -1,
    side = (self.square_index == 1 or self.square_index == 3) and 1 or -1, arena = self}))
  local add_sign = (self.square_index == 1 or self.square_index == 3) and 1 or -1
  self.square_xs[self.square_index] = self.square_xs[self.square_index] + add_sign*8
  self.square_index = self.square_index + 1
  if self.square_index > 4 then self.square_index = 1 end
end


node = class:class_new(object)
function node:new(x, y, args)
  self:object(nil, args)
  self.x, self.y = x, y
  self:collider('node', 'dynamic', 'circle', self.rs or an:random_float(6, 12))
  self:collider_set_restitution(1)
  self.nearby_nodes = {}
  self:spring()
  if self.from_merge then
    self:spring_pull('main', 0.5)
    self:timer()
    self:flash(0.15)
  end
end

function node:update(dt)
  self:collider_update_transform()
  local distance_to_center = math.distance(self.x, self.y, an.w/2, an.h/2)
  local ax, ay = self:collider_follow_flow_field(self.nodes.arena.flow_field, math.remap(distance_to_center, 0, 400, 0.1, 1.2)*math.clamp(math.remap(self.rs, 6, 16, 48, 24), 64, 24))
  self:collider_apply_force(ax, ay)
  game_2:circle(self.x, self.y, self.rs*self.springs.main.x, self.flashing and an.colors.white[0] or an.colors.black[0])
  game_2:circle(self.x, self.y, self.rs*self.springs.main.x, an.colors.white[0], 1)
  -- game_2:draw_text(math.round(self.rs, 0), 'JPN12', self.x, self.y, 0, self.springs.main.x, self.springs.main.x)

  local distance_multiplier = 1
  if self.rs >= 12 then distance_multiplier = math.remap(self.rs, 12, 24, 1, 1.5) end

  for _, n in ipairs(self.nodes.children) do
    if n ~= self then
      local d = math.distance(self.x, self.y, n.x, n.y)
      if d <= 96*distance_multiplier and not self.nearby_nodes[n] then
        self.nearby_nodes[n] = true
        if self.nodes.arena:is_line_valid(self, n) then
          local r = math.angle_to_point(self.x, self.y, n.x, n.y)
          local x1, y1, x2, y2 = self.x + self.rs*math.cos(r), self.y + self.rs*math.sin(r), n.x + n.rs*math.cos(r + math.pi), n.y + n.rs*math.sin(r + math.pi)
          self.nodes.arena.lines:add(line(self, n))
        end

      elseif d > 96*distance_multiplier and self.nearby_nodes[n] then
        self.nearby_nodes[n] = false
        for _, line in ipairs(self.nodes.arena.lines.children) do
          if line.src == self and line.dst == n or line.src == n and line.dst == self then
            line:die()
          end
        end
      end
    end
  end
end


line = class:class_new(object)
function line:new(src, dst, args)
  self:object(nil, args)
  self.src, self.dst = src, dst
  self:set_line_position()
  self:timer()
end

function line:update(dt)
  self:set_line_position()
  if self.hidden then return end
  local distance_multiplier_src, distance_multiplier_dst = 1, 1
  if self.src.rs >= 12 then distance_multiplier_src = math.remap(self.src.rs, 12, 24, 1, 1.5) end
  if self.dst.rs >= 12 then distance_multiplier_dst = math.remap(self.dst.rs, 12, 24, 1, 1.5) end
  local distance_multiplier = math.max(distance_multiplier_src, distance_multiplier_dst)
  local d = math.distance(self.src.x, self.src.y, self.dst.x, self.dst.y)
  if d < 64*distance_multiplier then
    game_1:line(self.x1, self.y1, self.x2, self.y2, an.colors.white[0], 1)
  elseif d >= 64*distance_multiplier then
    game_1:gapped_line(self.x1, self.y1, self.x2, self.y2, math.remap(d, 64*distance_multiplier, 96*distance_multiplier, 7*distance_multiplier, 1),
      distance_multiplier*16*math.cubic_in(math.remap(d, 64*distance_multiplier, 96*distance_multiplier, 0, 1)),
      d < 80*distance_multiplier and math.remap(d, 64*distance_multiplier, 80*distance_multiplier, 0.125, 0.5) or math.remap(d, 80*distance_multiplier, 96*distance_multiplier, 0.5, 1),
      0.5, an.colors.white[0], 1)
  end
end

function line:set_line_position()
  local r = math.angle_to_point(self.src.x, self.src.y, self.dst.x, self.dst.y)
  self.x1, self.y1 = self.src.x + self.src.rs*math.cos(r), self.src.y + self.src.rs*math.sin(r)
  self.x2, self.y2 = self.dst.x + self.dst.rs*math.cos(r + math.pi), self.dst.y + self.dst.rs*math.sin(r + math.pi)
end

function line:die()
  self:timer_every(0.075, function() self.hidden = not self.hidden end, 7, nil, function() self.dead = true end, 'die')
end


solid = class:class_new(object)
function solid:new(x, y, args)
  self:object(nil, args)
  self.x, self.y = x, y
  self.color = an.colors.white[0]
  self:collider('solid', 'static', 'rectangle', self.w, self.h)
end

function solid:update(dt)
  front:rectangle(self.x, self.y, self.w, self.h, 0, 0, self.color)
end


node_merge_effect = class:class_new(object)
function node_merge_effect:new(x, y, args)
  self:object(nil, args)
  self.x, self.y = x, y
  self:spring()
  self:spring_pull('main', 0.5, nil, nil, 0.2)
  self:timer()
  self:timer_tween(0.15, self, {x = self.target_x, y = self.target_y, rs = 0}, math.cubic_in_out, function() self.dead = true end)
end

function node_merge_effect:update(dt)
  game_2:circle(self.x, self.y, self.rs, an.colors.white[0])
end


hit_particle = class:class_new(object)
function hit_particle:new(x, y, args)
  self:object(nil, args)
  self.x, self.y = x, y
  self.w, self.h = 8, 2
  self:timer()
  self:timer_tween(self.duration, self, {v = 0}, math.linear, function() self.dead = true end)
end

function hit_particle:update(dt)
  local vx, vy = self.v*math.cos(self.r), self.v*math.sin(self.r)
  --[[
  local i, j = self.arena.flow_field:grid_get_cell_index(self.x, self.y)
  local v = self.arena.flow_field:grid_get(i, j)
  if v then vx, vy = vx + self.v*math.cos(v), vy + self.v*math.sin(v) end
  ]]--
  self.x = self.x + vx*dt
  self.y = self.y + vy*dt
  self.w = math.remap(math.length(vx, vy), 0, 150, 0, 8)
  self.h = math.remap(math.length(vx, vy), 0, 200, 0, 2)
  effects:push(self.x, self.y, math.angle(vx, vy))
  effects:rectangle(self.x, self.y, self.w, self.h, 0, 0, an.colors.white[0])
  effects:pop()
end


squares_with_fading_line = class:class_new(object)
function squares_with_fading_line:new(x, y, args)
  self:object(nil, args)
  self.x, self.y = x, y
  self.square_count = args and args.square_count or an:random_weighted(3*math.remap(self.arena.arena_time, 10, 60, 1, 0.25), 3*math.remap(self.arena.arena_time, 10, 60, 1, 0.25), 2, 
    1.5*math.remap(self.arena.arena_time, 10, 60, 1, 3))
  local square_count_to_initial_dash_size = {[1] = 2, [2] = 3, [3] = 4, [4] = 5}
  self.dash_size = square_count_to_initial_dash_size[an:random_weighted(3*math.remap(self.arena.arena_time, 10, 60, 1, 0.25), 3*math.remap(self.arena.arena_time, 10, 60, 1, 0.25), 2,
    1.5*math.remap(self.arena.arena_time, 10, 60, 1, 3))]
  self:timer()
  for i = 1, self.square_count do
    self:timer_after(0.1*(i-1), function()
      self:add(object():build(function(_)
        _:spring()
        _:timer()
        _.w = 0
        _:timer_tween(0.2, _, {w = 5}, math.linear, function() _.w = 5 end)
        _.empty = an:random_bool(20)
      end):action(function(_, dt)
        front:rectangle(self.x, self.y + self.direction*(i-1)*7, _.w - (_.empty and 1 or 0), _.w - (_.empty and 1 or 0), 0, 0, an.colors.white[0], _.empty and 1)
      end))
    end)
  end
  local y = self.y + self.direction*self.square_count*7 - self.direction*2
  if self.direction == -1 then y = y - 1 end
  for i = 1, self.dash_size do
    self:timer_after(0.1*(self.square_count) + 0.1*(i-1), function()
      self:add(object():build(function(_) 
        _.dash_size = self.dash_size
        _.y = y 
        _.s = 0
        _:timer()
        _:timer_tween(0.2, _, {s = 1}, math.linear, function() _.s = 1 end)
      end):action(function(_, dt)
        front:line(self.x, _.y, self.x, _.y + self.direction*_.dash_size*_.s, an.colors.white[0], 1)
      end))
      y = y + self.direction*(self.dash_size + 2)
      self.dash_size = self.dash_size - 1
    end)
  end
end

function squares_with_fading_line:update(dt)

end
