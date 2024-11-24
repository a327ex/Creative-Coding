require 'anchor'

function init()
  an:anchor_start('002', 480, 270, 2, 2, 'snkrx')
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

  flash_color = an.colors.white[0]
  an:add(arena())
  --[[
  an:action(function(self, dt)
    if an:is_pressed('k') then
      an:add(arena())
    end
    if an:is_pressed('l') then
      an.arena.dead = true
    end
  end)
  ]]--
end

arena = class:class_new(object)
function arena:new(x, y, args)
  self:object('arena', args)
  --[[
  self:add(square_of_squares(an.w/2 - 40, an.h/2, {square = 1}))
  self:add(square_of_squares(an.w/2, an.h/2, {square = 4}))
  self:add(square_of_squares(an.w/2 + 40, an.h/2, {square = 3}))
  ]]--
  self.x = 40
end

function arena:update(dt)
  if an:is_pressed('k') then
    self:add(square_of_squares(self.x, an.h/2, {square = array.random({1, 2, 3, 4, 5})}))
    self.x = self.x + 40
  end
end

square_of_squares = class:class_new(object)
function square_of_squares:new(x, y, args)
  self:object(nil, args)
  self.x, self.y = x, y
  local square_w, square_h = 4, 4
  local spacing = 2
  self.w, self.h = 5*square_w + 4*spacing, 5*square_h + 4*spacing
  local x1, y1 = self.x - self.w/2 + square_w/2, self.y - self.h/2 + square_h/2
  self:add(object('squares'))
  for k = 1, 25 do
    self.squares:add(object():build(function(_)
      local i, j = math.index_to_coordinate(k, 5)
      _.x, _.y = x1 + (i-1)*(square_w + spacing), y1 + (j-1)*(square_h + spacing)
      _.w, _.h = square_w, square_h
      _.s = 0
      _:timer()
    end):action(function(_, dt)
      game:rectangle(_.x, _.y, _.w*_.s, _.h*_.s, 0, 0, an.colors.white[0])
    end))
  end

  self:timer()
  if self.square == 1 then
    local d = 0.1
    self:show_s({13})
    self:timer_after(d, function()
      self:show_s({7, 9, 17, 19})
      self:hide_s({13})
      self:timer_after(d, function()
        self:show_s({1, 5, 21, 25})
        self:hide_s({7, 9, 17, 19})
        self:timer_after(d, function()
          self:show_s({2, 6, 4, 10, 22, 16, 24, 20})
          self:hide_s({7, 9, 17, 19})
          self:timer_after(d, function()
            self:show_s({3, 11, 23, 15})
          end)
        end)
      end)
    end)
  elseif self.square == 2 then
    local d = 0.0714
    self:show_s({13})
    self:timer_after(d, function()
      self:show_s({7, 9, 17, 19})
      self:timer_after(d, function()
        self:show_s({8, 12, 14, 18})
        self:timer_after(d, function()
          self:show_s({3, 11, 15, 23})
          self:timer_after(d, function()
            self:show_s({2, 4, 6, 10, 16, 22, 24, 20})
            self:timer_after(d, function()
              self:show_s({3, 11, 15, 23})
              self:timer_after(d, function()
                self:show_s({1, 5, 21, 25})
              end)
            end)
          end)
        end)
      end)
    end)
  elseif self.square == 3 then
    local d = 0.1
    self:show_s({21, 22, 23, 24, 25})
    self:timer_after(d, function()
      self:show_s({16, 17, 18, 19, 20})
      self:timer_after(d, function()
        self:show_s({11, 12, 13, 14, 15})
        self:timer_after(d, function()
          self:show_s({6, 7, 9, 10})
          self:timer_after(d, function()
            self:show_s({1, 5})
          end)
        end)
      end)
    end)
  elseif self.square == 4 then
    local d = 0.165
    self:show_s({13})
    self:timer_after(d, function()
      self:show_s({12, 8, 14, 18})
      self:timer_after(d, function()
        self:show_s({11, 3, 15, 23})
      end)
    end)
  elseif self.square == 5 then
    local d = 0.125
    self:show_s({13})
    self:timer_after(d, function()
      self:show_s({7, 9, 17, 19})
      self:timer_after(d, function()
        self:show_s({8, 12, 14, 18})
        self:timer_after(d, function()
          self:show_s({1, 5, 21, 25})
        end)
      end)
    end)
  end

  self:timer_after(0.5, function()
    self:move_row(an:random_int(1, 5))
    self:timer_after(0.5, function()
      self:move_column(an:random_int(1, 5))
      self:timer_after(0.5, function()
        self:move_row(an:random_int(1, 5))
        self:timer_after(0.5, function()
          self:move_column(an:random_int(1, 5))
        end)
      end)
    end)
  end)
end

function square_of_squares:update(dt)

end

function square_of_squares:move_row(x)
  local indexes = {(x-1)*5+1, (x-1)*5+2, (x-1)*5+3, (x-1)*5+4, (x-1)*5+5}
  local direction = array.random({-1, 1})
  for _, i in ipairs(indexes) do
    local s = self.squares.children[i]
    s:timer_tween(0.2, s, {x = s.x + direction*6}, math.linear, nil, 'movement')
  end
end

function square_of_squares:move_column(i)
  local indexes = {i, 5+i, 10+i, 15+i, 20+i}
  local direction = array.random({-1, 1})
  for _, i in ipairs(indexes) do
    local s = self.squares.children[i]
    s:timer_tween(0.2, s, {y = s.y + direction*6}, math.linear, nil, 'movement')
  end
end

function square_of_squares:show(indexes, delay)
  for k, i in ipairs(indexes) do
    self:timer_after(delay*(k-1), function()
      local s = self.squares.children[i]
      s:timer_tween(0.2, s, {s = 1}, math.linear, function() s.s = 1 end, 'visibility')
    end)
  end
end

function square_of_squares:show_s(indexes)
  for _, i in ipairs(indexes) do
    local s = self.squares.children[i]
    s:timer_tween(0.2, s, {s = 1}, math.linear, function() s.s = 1 end, 'visibility')
  end
end

function square_of_squares:hide(indexes, delay)
  for k, i in ipairs(indexes) do
    self:timer_after(delay*(k-1), function()
      local s = self.squares.children[i]
      s:timer_tween(0.2, s, {s = 0}, math.linear, function() s.s = 0 end, 'visibility')
    end)
  end
end

function square_of_squares:hide_s(indexes)
  for _, i in ipairs(indexes) do
    local s = self.squares.children[i]
    s:timer_tween(0.2, s, {s = 0}, math.linear, function() s.s = 0 end, 'visibility')
  end
end
