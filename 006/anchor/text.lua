--[[
  Module that adds a character based text functionality to the object.
  This implements a character based effect system that allows you to implement any kind of text effect possible.
  WARNING: currently the | character cannot be used in the text or bugs will happen, will fix when I need to use it in a game.

  Defining an effect looks like this:
    color_effect = function(dt, text, c, color)
      text.layer:set_color(color)
    end
  Every effect is a single function that gets called every frame for every character before each character is drawn.
  In the example above, we define the color effect as a function that sets the color for the next draw operations,
  which will be the oprations in which this specific character is drawn, and thus that character will be drawn with that color.

  The effect function receives the following arguments:
    dt - time step
    text - a reference to the text object
    character - an object representing the character, which contains the following attributes:
      .x, .y, .w, .h, .r, .sx, .sy, .ox. .oy,
      .c - the character as a string of size 1
      .line - the line the character is in
      .i - the character's index on the text
      .effects - effects applying to the character
    effect arguments - all arguments after the character object are the effect's arguments

  Another effect as an example:
    shake = function(dt, text, c, intensity, duration)
      if text.first_step then
        if not c:is'shake' then c:shake() end
        c:normal_shake(intensity, duration)
      end
      c.ox, c.oy = c.shake_amount.x, c.shake_amount.y
    end

  For some effects it makes sense to do most or all of its operations only when the text object is created, and to do this it's
  useful to use the an object's self.built attribute, which is false on the frame the object was created, and true otherwise.
  Both intensity and duration values are passed in from the text's defition: i.e. [this text is shaking](shake=4,2)
  Arguments for effects can theoretically be any Lua value, as internally it just loadstrings the string for each argument.

  Creating a text object looks like this:
    object():text(game, '[this text is red](color=an.colors.red[0]), [this text is shaking](shake=4,4),
                         [this text is red and shaking](color=an.colors.red[0];shake=4,4), this text is normal', {
      text_font = 'some_font',                                     -- optional, defaults to engine's default font
      text_effects = {color = color_effect, shake = shake_effect}, -- optional, defaults to no effects
      text_alignment = 'center',                                   -- otpional, defaults to 'left'
      w = 200,                                                     -- optional, defaults to 1024; this is the text's wrap width
      height_multiplier = 1 -- optional, defaults to 1; this is a multiplier on the vertical spacing between the text's lines
    })

  This is an extremely flexible text module and you should be able to do a lot with it.
  Make sure to check usage examples in my codebase, especially on games that are heavier on the text side of things.
]]--
text = class:class_new()
function text:text(text_layer, raw_text, args)
  self.tags.text = true
  for k, v in pairs(args or {}) do self[k] = v end
  self.text_layer = text_layer
  self.raw_text = raw_text
  self.text_font_name = self.text_font or 'default'
  self.text_font = an.fonts[self.text_font_name]
  self.text_effects = self.text_effects or {}
  self.text_alignment = self.text_alignment or 'left'
  self.w = self.w or 1024
  self.height_multiplier = self.height_multiplier or 1
  self:text_parse()
  self:text_format()
  return self
end

--[[
  Changes the text. This parses and formats the text anew and is thus somewhat expensive.
  It shouldn't be called every frame, but it's likely fine to call it every time an event happens that needs the text to be changed.
  TODO: provide a form of this function that doesn't reset character attributes
--]]
function text:text_change_text(raw_text)
  self.raw_text = raw_text
  self:text_parse()
  self:text_format()
end

--[[
  Parses self.raw_text into the self.characters table, which contains every valid character as the following table:
    character: character as an engine object, this is also the character object passed to an effect
    effects: the effects that apply to this character, as a table
]]-- 
function text:text_parse()
  local parse_arg = function(arg)
    if arg:find'#' then
      return tostring(arg)
    else
      return loadstring('return ' .. tostring(arg))()
    end
  end

  -- Parse text and store all delimiters as well as text field and effects into the parsed_text table
  local parsed_text = {}
  for i, field, j, effects, k in utf8.gmatch(self.raw_text, "()%[(.-)%]()%((.-)%)()") do
    local effects_temp = {}
    for effect in utf8.gmatch(effects, "[^;]+") do table.insert(effects_temp, effect) end

    -- Parse each effect: 'effect_name=arg1,arg2' becomes {effect_name, arg1, arg2}
    -- If there's only 'effect_name' with no arguments then it becomes {effect_name}
    local parsed_effects = {}
    for _, effect in ipairs(effects_temp) do
      if effect:find'=' then
        local effect_table = {}
        local effect_name = effect:left'='
        table.insert(effect_table, effect_name)
        local args = effect:right'='
        if args:find',' then
          for arg in utf8.gmatch(args, "[^,]+") do
            table.insert(effect_table, parse_arg(arg))
          end
        else
          table.insert(effect_table, parse_arg(args))
        end
        table.insert(effect_table, 0) -- counter for effect-based character index
        table.insert(parsed_effects, effect_table)
      else
        local effect_table = {}
        table.insert(effect_table, effect)
        table.insert(effect_table, 0)
        table.insert(parsed_effects, effect_table)
      end
    end

    table.insert(parsed_text, {i = tonumber(i), j = tonumber(j), k = tonumber(k), field = field, effects = parsed_effects})
    -- i to j-1 is [field]
    -- i+1 to j-2 is field
    -- j to k-1 is (effects)
    -- j+1 to k-2 is effects
  end

  --[[
    Read the parsed_text table to figure out which characters should be in the final text ([] and () delimiters and content
    shouldn't be in), then build the characters table containing each valid character as well as the effects that apply to it.
    Each character is transformed into an engine object, which is overall useful and consistent with the rest of the codebase.
  ]]--
  local characters = {}
  for i = 1, utf8.len(self.raw_text) do
    local c = utf8.sub(self.raw_text, i, i)
    local effects = nil
    local should_be_character = true
    for _, t in ipairs(parsed_text) do
      if i >= t.i+1 and i <= t.j-2 then effects = t.effects end
      if (i >= t.j and i <= t.k-1) or i == t.i or i == t.j-1 then should_be_character = false end
    end
    if should_be_character then
      if effects then
        for _, effect in ipairs(effects) do effect[#effect] = effect[#effect] + 1 end
        local tc = object('text_character', {c = c, effects = effects or {}})
        tc.effect = {}
        for _, effect in ipairs(tc.effects) do tc.effect[effect[1]] = {i = effect[#effect]} end
        -- c.effect.tag.i is the character's index with that tag as the base.
        -- This is useful when you need to do something with the character's index but using its local (in terms of the tags it has) instead of global index.
        -- "The [attack speed](keyword) value is 14." -> the global index (c.i) of the first 'a' in 'attack speed' is 5
        --                                               the local index (c.effect.keyword.i) is 1
        --                                               the global index of 's' in 'attack speed' is 12
        --                                               the local index (c.effect.keyword.i) is 8
        table.insert(characters, tc)
      else
        table.insert(characters, object('text_character', {c = c, effects = effects or {}}))
      end
    end
  end
  self.characters = characters
end

--[[
  Formats characters in the self.characters table by setting .x, .y, .w, .h, .r, .sx, .sy, .ox, .oy, .line and .i attributes.
  All of these values are applied locally, i.e. .x, .y is the character's local position.
  The character's world position is text object's .x + character's .x + character's .ox offset.
  Additionally, the text object's text_font, text_alignment, w and height_multiplier will affect formatting.
  From this function the text object itself will also have .text_w and .text_h attributes defined.
  self.text_w should be the same as self.w, and self.text_h will be the height of all lines + spacing added together.
]]--
function text:text_format()
  if not self.w then error('.w must be defined for the text module to work.') end
  local cx, cy = 0, 0
  local line = 1

  -- Set .x, .y, .r, .sx, .sy, .ox, .oy and .line for each character
  for i, c in ipairs(self.characters) do
    if c.c == '|' then
      cx = 0
      cy = cy + self.text_font.h*self.height_multiplier
      line = line + 1
    elseif c.c == ' ' then
      local wrapped = nil
      if #c.effects <= 1 then -- only check for wrapping if this space is not inside effect delimiters ()
        local from_space_x = cx
        -- go from next character to next space (the next word) to see if it fits this line
        for j = i+1, (array.index(array.get(self.characters, i+1, -1), function(v) return v.c == ' ' end) or 0) + i do
          from_space_x = from_space_x + an:font_get_text_width(self.text_font_name, self.characters[j].c)
        end
        if from_space_x > self.w then -- if the word doesn't fit then wrap line here
          cx = 0
          cy = cy + self.text_font.h*self.height_multiplier
          line = line + 1
          wrapped = true
        end
      end
      if not wrapped then
        c.x, c.y = cx, cy
        c.line = line
        c.r = 0
        c.sx, c.sy = 1, 1
        c.ox, c.oy = 0, 0
        c.w, c.h = an:font_get_text_width(self.text_font_name, c.c), self.text_font.h
        cx = cx + c.w
        if cx > self.w then
          cx = 0
          cy = cy + self.text_font.h*self.height_multiplier
          line = line + 1
        end
      else
        c.c = '|' -- set | to remove it in the next step, as it was already wrapped and doesn't need to be visible
      end
    else
      c.x, c.y = cx, cy
      c.line = line
      c.r = 0
      c.sx, c.sy = 1, 1
      c.ox, c.oy = 0, 0
      c.w, c.h = an:font_get_text_width(self.text_font_name, c.c), self.text_font.h
      cx = cx + c.w
      if cx > self.w then
        cx = 0
        cy = cy + self.text_font.h*self.height_multiplier
        line = line + 1
      end
    end
  end

  -- Remove line separators as they're not needed anymore
  for i = #self.characters, 1, -1 do
    if self.characters[i].c == '|' then
      table.remove(self.characters, i)
    end
  end

  -- Set .i for each character
  for i, c in ipairs(self.characters) do
    c.i = i
  end

  -- Find self.text_w (self.w), self.text_h and the width of each line to set alignments next
  local text_w = 0
  local line_widths = {}
  for i = 1, self.characters[#self.characters].line do
    local line_w = 0
    for j, c in ipairs(self.characters) do
      if c.line == i then
        line_w = line_w + an:font_get_text_width(self.text_font_name, c.c)
      end
    end
    line_widths[i] = line_w
    if line_w > text_w then
      text_w = line_w
    end
  end
  self.text_w = text_w
  self.text_h = self.characters[#self.characters].y + self.text_font.h*self.height_multiplier
  if not self.h then self.h = self.text_h end

  -- Sets .x of each character to match the given self.text_alignment, unchanged if it is 'left'
  for i = 1, self.characters[#self.characters].line do
    local line_w = line_widths[i]
    local leftover_w = self.text_w - line_w
    if self.text_alignment == 'center' then
      for _, c in ipairs(self.characters) do
        if c.line == i then
          c.x = c.x + leftover_w/2
        end
      end
    elseif self.text_alignment == 'right' then
      for _, c in ipairs(self.characters) do
        if c.line == i then
          c.x = c.x + leftover_w
        end
      end
    elseif self.text_alignment == 'justify' then
      local spaces_count = 0
      for _, c in ipairs(self.characters) do
        if c.line == i then
          if c.c == ' ' then
            spaces_count = spaces_count + 1
          end
        end
      end
      local added_width_to_each_space = math.floor(leftover_w/spaces_count)
      local total_added_width = 0
      for _, c in ipairs(self.characters) do
        if c.line == i then
          if c.c == ' ' then
            c.x = c.x + added_width_to_each_space
            total_added_width = total_added_width + added_width_to_each_space
          else
            c.x = c.x + total_added_width
          end
        end
      end
    end
  end
end

--[[
  Draws the text to the layer that was passed in on this object's creation.
  The x, y position passed corresponds to the top-left starting position for the text.
  If you want to draw the text centered on x, y then use "text_draw_centered".
  Example:
    game = object():layer()
    t1 = object():text(game, '[this text is shaking](shake=4,4), this text is normal', {
      text_alignment = 'right',
      w = 256,
      text_effects = {
        shake = function(dt, text, c, intensity, duration) ->
          if text.first_step then
            if not c:is'shake' then c:shake() end
            c:normal_shake(intensity, duration)
          end
          c.ox, c.oy = c.shake_amount.x, c.shake_amount.y
        end
      }
    }
    -- Then in some update function...
    t1:text_draw(dt, an.w/2, an.h/2)
]]--
function text:text_draw(dt, x, y, r, sx, sy)
  self.text_layer:push(x, y, r, sx, sy)
    for i, c in ipairs(self.characters) do
      -- if i == 1 then x = x + an:font_get_text_width(self.text_font_name, c.c)/2 end -- fix placement as it was half a character off
      for _, effect_table in ipairs(c.effects) do
        for effect_name, effect_function in pairs(self.text_effects) do
          if effect_name == effect_table[1] then
            local args = {}
            for i = 2, #effect_table do table.insert(args, effect_table[i]) end
            effect_function(dt, self, c, unpack(args))
          end
        end
      end
      self.text_layer:draw_text_lt(c.c, self.text_font_name, x + c.x + c.ox, y + c.y + c.oy, c.r, c.sx, c.sy)
      self.text_layer:set_color(an.colors.white[0])
    end
  self.text_layer:pop()
end

--[[
  Exactly the same as text_draw, except it draws the text centered on x instead.
--]]
function text:text_draw_centered(dt, x, y, r, sx, sy)
  self.text_layer:push(x, y, r, sx, sy)
    for i, c in ipairs(self.characters) do
      -- if i == 1 then x = x + an:font_get_text_width(self.text_font_name, c.c)/2 end -- fix placement as it was half a character off
      -- if i == 1 then x = x + c.w/2 end -- fix placement as it was half a character off
      for _, effect_table in ipairs(c.effects) do
        for effect_name, effect_function in pairs(self.text_effects) do
          if effect_name == effect_table[1] then
            local args = {}
            for i = 2, #effect_table do table.insert(args, effect_table[i]) end
            effect_function(dt, self, c, unpack(args))
          end
        end
      end
      self.text_layer:draw_text_lt(c.c, self.text_font_name, x - self.text_w/2 + c.x - c.ox, y - self.text_h/2 + c.y - c.oy, c.r or 0, c.sx, c.sy)
      self.text_layer:set_color(an.colors.white[0])
    end
  self.text_layer:pop()
end
