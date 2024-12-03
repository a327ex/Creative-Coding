require 'anchor'

function init()
  an:anchor_start('006', 480, 480, 2, 2, 'tidal_waver')
  an:input_bind_all()

  an:font('JPN12', 'assets/Mx437_DOS-V_re_JPN12.ttf', 12)

  back = object():layer()
  game = object():layer()
  front = object():layer()

  function an:draw_layers()
    back:layer_draw_commands()
    game:layer_draw_commands()
    front:layer_draw_commands()

    self:layer_draw_to_canvas('main', function()
      back:layer_draw()
      game:layer_draw()
      front:layer_draw()
    end)

    self:layer_draw('main', 0, 0, 0, self.sx, self.sy)
  end

  an:add(arena())
end

arena = class:class_new(object)
function arena:new(x, y, args)
  self:object('arena', args)
  self:add(object('circles'))
  local j = 1
  for i = 20, 220, 10 do
    self.circles:add(object():build(function(self)
      self.x, self.y = an.w/2, an.h/2
      self.r = 0
      self.rs = i
      self.index = j
      self:add(object('lines'))
      local r = 0
      local dash_or_gap = 'dash'
      local t = 2*0.02*math.pi*self.rs
      local a, b = 0.5*math.remap(self.rs, 40, 220, 1, 0.5), 0.5*math.remap(self.rs, 40, 220, 1, 1.5)
      while r <= 2*math.pi do
        if dash_or_gap == 'dash' then
          local x1, y1 = self.x + self.rs*math.cos(r), self.y + self.rs*math.sin(r)
          r = r + math.asin(a*t/self.rs)
          local x2, y2 = self.x + self.rs*math.cos(r), self.y + self.rs*math.sin(r)
          self.lines:add(object():build(function(_)
            _.x1, _.y1 = x1, y1
            _.x2, _.y2 = x2, y2
            _.fx1, _.fy1 = math.point_trs(_.x1, _.y1, self.x - an.w/2 + 48, self.y - an.h/2 - 24, self.r)
            _.fx2, _.fy2 = math.point_trs(_.x2, _.y2, self.x - an.w/2 + 48, self.y - an.h/2 - 24, self.r)
            _.index = #self.lines.children + 1
          end):action(function(_, dt)
            _.fx1, _.fy1 = math.point_trs(_.x1, _.y1, self.x - an.w/2 + 48, self.y - an.h/2 - 24, self.r)
            _.fx2, _.fy2 = math.point_trs(_.x2, _.y2, self.x - an.w/2 + 48, self.y - an.h/2 - 24, self.r)
            -- game:line(_.fx1, _.fy1, _.fx2, _.fy2, an.colors.white[0], 1)
            --[[
            game:push_trs(self.x - an.w/2 + 48, self.y - an.h/2 - 24, self.r)
            game:line(_.x1, _.y1, _.x2, _.y2, an.colors.white[0], 1)
            game:pop()
            ]]--
          end))
          dash_or_gap = 'gap'
        elseif dash_or_gap == 'gap' then
          r = r + math.asin(b*t/self.rs)
          dash_or_gap = 'dash'
        end
      end
    end):action(function(self, dt)
      self.x = an.w/2 + 124*math.sin(5*(0.5*an.time - self.index*0.05) + math.sin(2*an.time)*math.pi/2)
      self.y = an.h/2 + 24*math.sin(6*(0.5*an.time - self.index*0.02))
      self.r = self.r + math.sin(an.time)*0.005*self.index*math.pi*dt
      local t = 2*0.02*math.pi*self.rs
      local a, b = 0.5*math.remap(self.rs, 40, 220, 1, 0.5), 0.5*math.remap(self.rs, 40, 220, 1, 1.5)
      --[[
      game:push(self.x, self.y, self.r) -- 0.1*i*dir)
      game:dashed_circle(self.x, self.y, self.rs, a*t, b*t, an.colors[0], 1)
      game:pop()
      ]]--
    end))
    j = j + 1
  end

  local white = an.colors.white:color_copy(0)
  local red = an.colors.red:color_copy(0)
  local orange = an.colors.red:color_copy(0)
  local yellow = an.colors.yellow:color_copy(0)
  local green = an.colors.green:color_copy(0)
  local blue = an.colors.blue:color_copy(0)
  local purple = an.colors.purple:color_copy(0)
  self.index_colors = {
    [1] = white,
    [2] = white:color_mix2(0, red[0], 0.84),
    [3] = white:color_mix2(0, red[0], 0.70),
    [4] = white:color_mix2(0, red[0], 0.56),
    [5] = white:color_mix2(0, red[0], 0.42),
    [6] = white:color_mix2(0, red[0], 0.28),
    [7] = white:color_mix2(0, red[0], 0.14),
    [8] = red,
    [9] = red:color_mix2(0, orange[0], 0.84),
    [10] = red:color_mix2(0, orange[0], 0.70),
    [11] = red:color_mix2(0, orange[0], 0.56),
    [12] = red:color_mix2(0, orange[0], 0.42),
    [13] = red:color_mix2(0, orange[0], 0.28),
    [14] = red:color_mix2(0, orange[0], 0.14),
    [15] = orange,
    [16] = orange:color_mix2(0, yellow[0], 0.84),
    [17] = orange:color_mix2(0, yellow[0], 0.70),
    [18] = orange:color_mix2(0, yellow[0], 0.56),
    [19] = orange:color_mix2(0, yellow[0], 0.42),
    [20] = orange:color_mix2(0, yellow[0], 0.28),
    [21] = orange:color_mix2(0, yellow[0], 0.14),
    [22] = yellow,
    [23] = yellow:color_mix2(0, green[0], 0.84),
    [24] = yellow:color_mix2(0, green[0], 0.70),
    [25] = yellow:color_mix2(0, green[0], 0.56),
    [26] = yellow:color_mix2(0, green[0], 0.42),
    [27] = yellow:color_mix2(0, green[0], 0.28),
    [28] = yellow:color_mix2(0, green[0], 0.14),
    [29] = green,
    [30] = green:color_mix2(0, blue[0], 0.84),
    [31] = green:color_mix2(0, blue[0], 0.70),
    [32] = green:color_mix2(0, blue[0], 0.56),
    [33] = green:color_mix2(0, blue[0], 0.42),
    [34] = green:color_mix2(0, blue[0], 0.28),
    [35] = green:color_mix2(0, blue[0], 0.14),
    [36] = blue,
    [37] = blue:color_mix2(0, purple[0], 0.84),
    [38] = blue:color_mix2(0, purple[0], 0.70),
    [39] = blue:color_mix2(0, purple[0], 0.56),
    [40] = blue:color_mix2(0, purple[0], 0.42),
    [41] = blue:color_mix2(0, purple[0], 0.28),
    [42] = blue:color_mix2(0, purple[0], 0.14),
    [43] = purple,
    [44] = purple:color_mix2(0, white[0], 0.875),
    [45] = purple:color_mix2(0, white[0], 0.75),
    [46] = purple:color_mix2(0, white[0], 0.652),
    [47] = purple:color_mix2(0, white[0], 0.50),
    [48] = purple:color_mix2(0, white[0], 0.375),
    [49] = purple:color_mix2(0, white[0], 0.25),
    [50] = purple:color_mix2(0, white[0], 0.125),
  }

  self:timer()
  self:timer_every(0.04, function()
    array.rotate(self.index_colors, 1)
  end)
end

function arena:update(dt)
  for j = 1, 50 do
    local vertices = self:get_all_points_for_index(j)
    local vertices_2 = self:get_all_points_for_index(j+1)
    local loop
    if j == 50 then loop = true; vertices_2 = self:get_all_points_for_index(1) end
    local k = 1
    for i = 1, #vertices-4, 4 do
      local x1, y1, x2, y2 = vertices[i], vertices[i+1], vertices[i+2], vertices[i+3]
      local x3, y3, x4, y4 = vertices[i+4], vertices[i+5], vertices[i+6], vertices[i+7]
      game:polygon({x1, y1, x2, y2, x4, y4, x3, y3}, self.index_colors[j][0].r, self.index_colors[j][0].g, self.index_colors[j][0].b, math.remap(k, 1, 21, 0, 1), 1)
      if vertices_2 then
        local x5, y5, x6, y6 = vertices_2[i], vertices_2[i+1], vertices_2[i+2], vertices_2[i+3]
        local x7, y7, x8, y8 = vertices_2[i+4], vertices_2[i+5], vertices_2[i+6], vertices_2[i+7]
        if x5 and y5 and x7 and y7 then
          game:polygon({x2, y2, x4, y4, x7, y7, x5, y5}, self.index_colors[j][0].r, self.index_colors[j][0].g, self.index_colors[j][0].b, math.remap(k, 1, 21, 0, 1), 1)
        end
      end
      -- game:line(vertices[i], vertices[i+1], vertices[i+2], vertices[i+3], an.colors.white[0], 1)
      k = k + 1
    end
  end
end

function arena:get_all_points_for_index(i)
  local vertices = {}
  for j, circle in ipairs(self.circles.children) do
    for _, line in ipairs(circle.lines.children) do
      if line.index == i then
        table.insert(vertices, line.fx1)
        table.insert(vertices, line.fy1)
        table.insert(vertices, line.fx2)
        table.insert(vertices, line.fy2)
      end
    end
  end
  return vertices
end
