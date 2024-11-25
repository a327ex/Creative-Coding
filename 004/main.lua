require 'anchor'

function init()
  an:anchor_start('004', 480, 270, 2, 2, 'snkrx')
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

  an:action(function() back:rectangle(an.w/2, an.h/2, an.w, an.h, 0, 0, an.colors.black[0]) end)

  base_lines()
  notes()
end

function base_lines()
  an:add(object('base_lines'):action(function(self, dt)
    game:line(30, 60, 450, 60, an.colors.fg[0], 1)
    game:line(30, 70, 450, 70, an.colors.fg[0], 1)
    game:line(30, 80, 450, 80, an.colors.fg[0], 1)
    game:line(30, 90, 450, 90, an.colors.fg[0], 1)
    game:line(30, 100, 450, 100, an.colors.fg[0], 1)

    game:line(30, 170, 450, 170, an.colors.fg[0], 1)
    game:line(30, 180, 450, 180, an.colors.fg[0], 1)
    game:line(30, 190, 450, 190, an.colors.fg[0], 1)
    game:line(30, 200, 450, 200, an.colors.fg[0], 1)
    game:line(30, 210, 450, 210, an.colors.fg[0], 1)

    game:line(30, 59, 30, 210, an.colors.fg[0], 1)
    game:line(450, 59, 450, 210, an.colors.fg[0], 1)
    game:gapped_line(20, 59, 20, 210, 4, 4, 0.466, nil, an.colors.fg[0], 2)

    game:polyline({50, 60, 50, 80, 60, 90, 50, 100, 40, 90, 50, 80}, an.colors.fg[0], 3)
    game:polyline({50, 60, 60, 70, 60, 90}, an.colors.fg[0], 3)
    game:polyline({60, 180, 50, 190, 40, 180, 50, 170, 60, 180, 60, 200, 50, 210, 40, 200, 50, 190}, an.colors.fg[0], 3)

    game:arrow(67, 60, 10, an.colors.fg[0], 2)
    game:arrow(72, 75, 10, an.colors.fg[0], 2)
    game:arrow(67, 180, 10, an.colors.fg[0], 2)
    game:arrow(72, 195, 10, an.colors.fg[0], 2)

    game:draw_text_lt('++', 'JPN12', 437, 250)
    game:dashed_line(453, 256, 500, 256, 4, 4, an.colors.fg[0], 1)
  end))
end

function notes()
  an:add(object('notes'):action(function(self, dt)
    game:push_trs(-4, 0)
    -- Bar 1
    note(100, 80, true)
    note(100, 225, false, -1)
    note(120, 185, true)
    note(125, 180, true)
    note_decoration(110, 180, 2)
    note(125, 170, true)
    note(125, 160, true, 0)
    note_decoration(115, 160, 2)
    note(150, 80, false)
    game:dashed_line(107, 75, 147, 75, 4, 4, an.colors.fg[0], 1)
    note(165, 85, false)

    -- Bar 2
    note(180, 90, true)
    note(180, 210, false)
    note(205, 180, true)
    note_decoration(197, 180, 2)
    note(205, 165, true, -1)
    note(205, 150, true, 0)
    note_decoration(235, 80, 3)
    note(260, 95, false)
    note_decoration(252, 95, 2)

    -- Bar 3
    note(280, 105, false)
    note_decoration(268, 105, 1)
    note(300, 100, false)
    note(320, 115, false, -1)
    note(280, 230, false, 0)
    note_decoration(272, 230, 2)
    note_decoration(280, 220, 4)
    note(300, 175, true)
    note(300, 165, true)

    -- Bar 4
    note(340, 105, false)
    note(360, 110, false, 0)
    note_decoration(352, 110, 2)
    note(380, 100, false)
    note(340, 205, false)
    note(360, 175, true)
    note(365, 170, true)

    -- Bar 5
    note(415, 100, false)
    game:dashed_line(387, 95, 412, 95, 4, 4, an.colors.fg[0], 1)
    note(435, 110, false, 0)
    note_decoration(427, 110, 2)
    note(415, 225, false, -1)
    note(435, 190, true)
    note(435, 180, true)
    note_decoration(427, 180, 2)
    note(435, 170, true)
    game:pop()
  end))
end

function note(x, y, open, overwrite)
  game:diamond(x, y, 7 + (not open and 1 or 0), 0, 0, an.colors.fg[0], open and 1)
  if overwrite == 1 then
    game:line(x - 6, y + 4, x + 6, y + 4, an.colors.fg[0], 1)
  elseif overwrite == -1 then
    game:line(x - 6, y - 4, x + 6, y - 4, an.colors.fg[0], 1)
  elseif overwrite == 0 then
    game:line(x - 8, y, x + 8, y, an.colors.fg[0], 1)
  end
end

function note_decoration(x, y, type)
  if type == 1 then
    game:arrow(x, y, 8, an.colors.fg[0], 1)
  elseif type == 2 then
    game:push(x, y, -math.pi)
    game:arrow(x, y, 8, an.colors.fg[0], 1)
    game:pop()
  elseif type == 3 then
    game:polyline({x - 4, y - 4, x + 4, y - 4, x + 4, y + 4}, an.colors.fg[0], 1)
  elseif type == 4 then
    game:line(x - 6, y, x + 6, y, an.colors.fg[0], 1)
  end
end
