require 'anchor'

function init()
  an:anchor_start('005', 480, 270, 2, 2, 'tidal_waver')
  an:input_bind_all()

  an:font('JPN12', 'assets/Mx437_DOS-V_re_JPN12.ttf', 12)
  an:image('circle16', 'assets/circle16.png')

  back = object():layer()
  back_2 = object():layer()
  game = object():layer()
  front = object():layer()
  shadow = object():layer()

  function an:draw_layers()
    back:layer_draw_commands(nil, true)
    back_2:layer_draw_commands()
    shadow:layer_draw_commands()
    game:layer_draw_commands()
    front:layer_draw_commands()

    self:layer_draw_to_canvas('main', function()
      back_2:layer_draw()
      back:layer_draw()
      shadow:layer_draw()
      game:layer_draw()
      front:layer_draw()
    end)

    self:layer_draw('main', 0, 0, 0, self.sx, self.sy)
  end

  shadow_color = object():color(0.15, 0.15, 0.15, 0.5, 0.025)
  an:add(arena())
end

arena = class:class_new(object)
function arena:new(x, y, args)
  self:object('arena', args)
  self:add(object('projectiles'))
  self:timer()
  --[[
  self:timer_every(0.04, function()
    self.projectiles:add(projectile(an:random_int(0, an.w), an:random_int(0, an.h), 256))
  end)
  ]]--
end

function arena:update(dt)
  back_2:rectangle(an.w/2, an.h/2, an.w, an.h, 0, 0, an.colors.fg[0])
  back_2:rectangle_lt(0, 0, an.w, 0.7*an.h, 0, 0, an.colors.bg[0])
  -- shadow:rectangle(an.w/2, 0.7*an.h + 5, an.w, 10, 0, 0, an.colors.fg[0])
  if an:is_pressed('k') then
    self.projectiles:add(projectile(an:random_int(0, an.w), an:random_int(3*an.h/4, an.h), 256))
  end
  if an:is_pressed('l') then
    self:timer_every(0.03, function()
      self.projectiles:add(projectile(an:random_int(-an.w, an.w), an:random_int(3*an.h/4, an.h), 256))
    end, nil, nil, nil, 'rain')
  end
  if an:is_down('j') then
    self:timer_set_multiplier('rain', 0.5)
  end
  if an:is_released('j') then
    self:timer_set_multiplier('rain', 1)
  end
  if an:is_pressed('s') then
    self:timer_for(4, function()
      self:timer_set_multiplier('rain', math.clamp(self.timer_timers['stop'].timer, 1, 4))
    end, function() self:timer_cancel('rain') end, 'stop')
  end
end

projectile = class:class_new(object)
function projectile:new(x, y, z, args)
  self:object(nil, args)
  self.x, self.y, self.z = x, y, z
  self.vx = an:random_float(0, 32)
  self.r = math.pi/2
  self.sx, self.sy = 1, 1
  self.w, self.h = 10, 4
  self.color = array.random({an.colors.blue, an.colors.red, an.colors.purple, an.colors.orange, an.colors.green, an.colors.yellow})
  self.shadow_color = self.color:color_mix(0, shadow_color[0], 0.1)
  self.shadow_color:color_lighten(0, 0.35)
  self:spring()
  self:timer()
end

function projectile:update(dt)
  self.x = self.x + self.vx*dt
  self.r = math.pi/2 - math.remap(self.vx, 0, 32, 0, math.pi/8)
  self.z = self.z - 512*dt
  if self.z <= 5 then self:die() end

  local shadow_scale = math.remap(self.z, 256, 0, 0.25, 1)
  shadow:ellipse(self.x, self.y, 1.75*4*shadow_scale, 1.75*2*shadow_scale, self.shadow_color[0])
  game:push(self.x, self.y - self.z, self.r, self.sx*self.springs.main.x, self.sy*self.springs.main.x)
  game:rectangle(self.x, self.y - self.z, self.w, self.h, 2, 2, self.color[0])
  game:pop()
  if self.y - self.z < 0.7*an.h then
    back:push(self.x, self.y - self.z, self.r, self.sx*self.springs.main.x, self.sy*self.springs.main.x)
    back:rectangle(self.x, self.y - self.z, self.w, self.h, 2, 2, self.color[0])
    back:pop()
  end
end

function projectile:die()
  self.dead = true
  self.projectiles.arena:add(circle_effect(self.x, self.y, {color = self.color[0], target_rs = an:random_float(20, 32)}))
  self.projectiles.arena:add(projectile_death_effect(self.x, self.y, {color = self.color}))
  for i = 1, an:random_int(2, 4) do
    self.projectiles.arena:add(hit_particle(self.x, self.y, nil, {v = an:random_float(25, 50), color = self.color[0]}))
  end
end

circle_effect = class:class_new(object)
function circle_effect:new(x, y, args)
  self:object(nil, args)
  self.x, self.y = x, y
  self.rs = 0
  self.line_width = 8
  self.color = object():color(self.color.r, self.color.g, self.color.b, 1, 0.025)
  self.shadow_color = self.color:color_mix(0, shadow_color[0], 0.1)
  self.shadow_color:color_lighten(0, 0.35)
  self:timer()
  self:timer_tween(0.35, self, {rs = self.target_rs, line_width = 0}, math.cubic_out, function() self.dead = true end)
end

function circle_effect:update(dt)
  shadow:ellipse(self.x + 1, self.y + 1, self.rs, 0.5*self.rs, self.shadow_color[0], self.line_width)
  shadow:ellipse(self.x, self.y, self.rs, 0.5*self.rs, self.color[0], self.line_width)
end

hit_particle = class:class_new(object)
function hit_particle:new(x, y, z, args)
  self:object(nil, args)
  self.x, self.y, self.z = x, y, z or 2.1
  self.r = args and args.r or an:random_angle()
  self.rs = 2
  self.s = 1
  self.color = object():color(self.color.r, self.color.g, self.color.b, 1, 0.025)
  self.shadow_color = self.color:color_mix(0, shadow_color[0], 0.1)
  self.shadow_color:color_lighten(0, 0.35)
  self.vx, self.vy = self.v*math.cos(self.r), self.v*math.sin(self.r)
  self.vz = an:random_float(96, 128)
  self:timer()
end

function hit_particle:update(dt)
  self.x = self.x + self.vx*dt
  self.y = self.y + self.vy*dt
  self.z = self.z + self.vz*dt
  self.vz = self.vz - 512*dt
  self.s = self.s - 1.5*dt
  if self.z <= 2 then self.dead = true end

  local shadow_scale = math.remap(self.z, 64, 0, 0.25, 1)
  shadow:ellipse(self.x, self.y, self.rs*shadow_scale, 0.5*self.rs*shadow_scale, self.shadow_color[0])
  game:circle(self.x, self.y - self.z, self.rs*self.s, self.color[0])
end

projectile_death_effect = class:class_new(object)
function projectile_death_effect:new(x, y, args)
  self:object(nil, args)
  self.x, self.y = x, y
  self.r = self.r or math.pi/4
  self.w = self.w or 8
  self.duration = self.duration or 0.25
  self:timer()
  self:timer_after(self.duration, function() self.dead = true end)
  self:spring()
  self:spring_pull('main', 0.25)
end

function projectile_death_effect:update(dt)
  game:push(self.x, self.y, self.r, self.springs.main.x, 0.5*self.springs.main.x)
    game:rectangle(self.x, self.y, self.w, self.w, 3, 3, self.color[0])
  game:pop()
end
