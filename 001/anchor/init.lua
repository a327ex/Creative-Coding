-- Require external libraries.
utf8 = require 'anchor.external.utf8'
profile = require 'anchor.external.profile'
sort = require 'anchor.external.sort'
mlib = require 'anchor.external.mlib'

-- Require all modules.
-- Each module (except for the first 4) is a mixin, and all mixins are added to the "object" class, which is the only class the engine defines.
-- This addition happens via anchor/class.lua's "class_add" function.
require 'anchor.array'
require 'anchor.collision'
require 'anchor.math'
require 'anchor.string'
require 'anchor.class'
require 'anchor.animation'
require 'anchor.camera'
require 'anchor.collider'
require 'anchor.color'
require 'anchor.grid'
require 'anchor.input'
require 'anchor.layer'
require 'anchor.mouse_hover'
require 'anchor.music_player'
require 'anchor.physics_world'
require 'anchor.random'
require 'anchor.shake'
require 'anchor.sound'
require 'anchor.spring'
require 'anchor.stats'
require 'anchor.text'
require 'anchor.timer'
require 'anchor.ui'

--[[
  Performs the engine's fixed update loop.
  This is only a function because it needs to be called from both love.run and love.errorhandler.
--]]
local fixed_update = function()
  an.dt = love.timer.step()*an.timescale*an.slow_amount
  an.lag = math.min(an.lag + an.dt, an.rate*an.max_updates)

  while an.lag >= an.rate do
    if love.event then
      love.event.pump()
      for name, a, b, c, d, e, f in love.event.poll() do
        if name == 'quit' then
          return a or 0
        elseif name == 'resize' then
        elseif name == 'keypressed' then
          an.input_keyboard_state[a] = true
          an.input_latest_type = 'keyboard'
        elseif name == 'keyreleased' then
          an.input_keyboard_state[a] = false
        elseif name == 'mousepressed' then
          an.input_mouse_state[c] = true
          an.input_latest_type = 'mouse'
        elseif name == 'mousereleased' then
          an.input_mouse_state[c] = false
        elseif name == 'mousemoved' then
          an.input_mouse_state.dx = c
          an.input_mouse_state.dy = d
        elseif name == 'wheelmoved' then
          if b == 1 then an.input_mouse_state.wheel_up = true end
          if b == -1 then an.input_mouse_state.wheel_down = true end
        elseif name == 'gamepadpressed' then
          an.input_gamepad_state[b] = true
          an.input_latest_type = 'gamepad'
        elseif name == 'gamepadreleased' then
          an.input_gamepad_state[b] = false
        elseif name == 'gamepadaxis' then
          an.input_gamepad_state[b] = c
        elseif name == 'joystickadded' then
          an.input_gamepad = a
        elseif name == 'joystickremoved' then
          an.input_gamepad = nil
        end
      end
    end

    local dt = an.rate
    an.step = an.step + 1
    an.time = an.time + dt

    local all_objects = an:get_all_children()
    table.insert(all_objects, 1, an) -- insert root here since we also want actions and everything else in object to work with it
    for _, object in ipairs(all_objects) do object:_early_update(dt*an.slow_amount) end
    for _, object in ipairs(all_objects) do object:_update(dt*an.slow_amount) end
    for _, object in ipairs(all_objects) do object:_late_update(dt*an.slow_amount) end
    an:_final_update() -- only call _final_update for "an" since that's the only object it was made for, change later if more uses for it are needed
    for _, object in ipairs(all_objects) do object:cleanup() end
    for _, object in ipairs(all_objects) do object:remove_dead_branch() end

    an.lag = an.lag - dt
  end

  while an.framerate and love.timer.getTime() - an.last_frame < 1/an.framerate do
    love.timer.sleep(.0005)
  end

  an.last_frame = love.timer.getTime()
  if love.graphics and love.graphics.isActive() then
    an.frame = an.frame + 1
    love.graphics.origin()
    love.graphics.clear()
    an:draw_layers()
    love.graphics.present()
  end

  love.timer.sleep(an.sleep)
end

--[[
  This is the main internal function that everything runs from.
  The engine expects the user to define an "init" function in "main.lua" from which everything will start by the call of "an:anchor_start".
  You don't need to define an "update" function; to do something every frame either use the update functions of objects added to "an", or attach actions to such objects (or to "an" as well).
--]]
function love.run()
  an = object('anchor'):anchor():input():music_player():physics_world():timer():random()
  init()
  love.timer.step()
  return fixed_update
end

--[===[
-- For some reason on some kinds of bugs this doesn't behave correctly, so I'm commenting it out for now
function love.errorhandler(error_text)
  if not an.error then
    an:kill_all_children()
    an:input_bind_all()
    an:add(object('error'):build(function(self)
      self.error_text = debug.traceback('Error:\n      ' .. tostring(error_text), 3):gsub('\n[^\n]+$', ''):gsub('stack traceback:', 'Traceback:')
      local s1 = [[
This crash report has been automatically sent to me, the developer, who will try to fix it by next patch.
You can turn this behavior off in the game's settings.]]
      local s2 = [[
If you turned automatic reporting off, you can also copy the crash report by pressing CTRL+C.
Then you can send it to me by e-mail, to a327ex@gmail.com.]]
      self.full_text = self.error_text .. '\n\n' .. s1 .. '\n\n' .. s2

    end):action(function(self, dt)
      if (an:is_down('lctrl') or an:is_down('rctrl')) and an:is_pressed('c') then
        if not an.copied then
          love.system.setClipboardText(self.error_text)
          an:add(object('copied'):build(function(self)
            self:timer()
            self:timer_after(2, function() self.dead = true end)
          end):action(function(self, dt)
            front:draw_text_lt('Copied to clipboard!', 'default', an.w - 95, an.h - 20, 0, 1, 1, 0, 0, an.colors.fg[0])
          end))
        end
      end

      back:rectangle(an.w/2, an.h/2, 2*an.w, 2*an.h, 0, 0, an.colors.blue[0])
      front:draw_text_lt(self.full_text, 'default', 10, 10, 0, 1, 1, 0, 0, an.colors.fg[0])
    end))
  end

  return fixed_update
end
--]===]

--[[
  There is only one instance of this class and it is automatically created and globally available as "an".
  "an" is automatically initialized as the following mixins:
    camera
    input
    layer
    music_player
    normal_shake
    physics_world
    random
    spring_shake
    timer
--]]
anchor = class:class_new()
function anchor:anchor()
  self.tags.anchor = true
  self.time = 0
  self.step = 0
  self.frame = 0
  self.timescale = 1
  self.framerate = 60
  self.rate = 1/144
  self.max_updates = 10
  self.sleep = .001
  self.lag = 0
  self.dt = 0
  self.last_frame = 0

  self._animation_frames = {}
  self.fonts = {}
  self.images = {}
  self.layers = {}
  self.shaders = {}
  self.musics = {}
  self.sounds = {}
  self.music_pitch = 1
  self.music_volume = 1
  self.sound_pitch = 1
  self.sound_volume = 1
  return self
end

--[[
  Starts the engine. This must be called at the top of the init function in main.lua or things won't work.
  Arguments passed in are:
    title - the game's title, this is also the name of the game's save data folder (currently neither functionality is not working)
    w     - the game's internal width, by default every canvas is created with this value as its width
    h     - the game's internal height
    sx    - the game's horizontal scale that will multiply by internal width to target the desired window size
    sy    - the game's vertical scale
    theme - the colors that will populate the an.colors table
--]]
function anchor:anchor_start(title, w, h, sx, sy, theme)
  self.title = title or 'Anchor'
  self.x = 0
  self.y = 0
  self.w = w or 480
  self.h = h or 270
  self.sx = sx or 3
  self.sy = sy or 3
  self.theme = theme or 'default'
  self:anchor_set_theme()

  -- love.filesystem.setIdentity(self.title)
  love.window.setTitle(self.title)
  love.graphics.setLineStyle('rough')
  love.graphics.setDefaultFilter('nearest', 'nearest', 0)

  love.window.updateMode(self.w*self.sx, self.h*self.sy)
  local _, _, flags = love.window.getMode()
  self.framerate = flags.refreshrate == 0 and 60 or flags.refreshrate
  self:layer()
  self:camera(self.w/2, self.h/2):_normal_shake():_spring_shake()
  self:font('default', 'anchor/assets/LanaPixel.ttf', 11)

  self:early_action(function(self, dt)
    self.time = self.time + dt
    for _, layer in ipairs(self.layers) do layer.draw_commands = {} end
    self:update_audio(dt)
    self:physics_world_update(dt)
  end):late_action(function(self, dt)
    self:camera_update(dt)
  end)
  
end

--[[
  Loads and adds an animation_frames object to the engine object.
  Added animation_frames can be accessed via an._animation_frames.name.
  Arguments passed in are:
    image_name       - the name of a previously loaded (with "an:image") image
    frame_w, frame_h - the size of each animation frame
    frames_list      - a list of tuples, each with the x, y position of a frame that makes up the animation
  Example:
    an:image('player_spritesheet', 'assets/player_spritesheet.png')
    an:animation_frames('player_walk', 'player_spritesheet', 32, 32, {{1, 1}, {2, 1}}) -- loads the player walk cycle, which are the first 2 images in the top row of the spritesheet
--]]
function anchor:animation_frames(name, image_name, frame_w, frame_h, frames_list)
  self._animation_frames[name] = object():build(function(self)
    self.tags.animation_frames = true
    self.source = an.images[image_name]
    self.w, self.h = frame_w, frame_h

    if type(frames_list) == 'number' then -- the source is a single row spritesheet and the number of frames is specified
      local n = frames_list
      frames_list = {}
      for i = 1, n do table.insert(frames_list, {i, 1}) end
      self.frames_list = frames_list
    elseif not frames_list then
      local frames_list = {}
      for i = 1, math.floor(self.source.w/self.w) do table.insert(frames_list, {i, 1}) end
      self.frames_list = frames_list
    end

    self.frames = {}
    for i, frame in ipairs(self.frames_list) do
      self.frames[i] = {quad = love.graphics.newQuad((frame[1]-1)*self.w, (frame[2]-1)*self.h, self.w, self.h, self.source.w, self.source.h), w = self.w, h = self.h}
    end
    self.size = #self.frames
    table.insert(an._animation_frames, self)
  end)
end

--[[
  Loads and adds a font object to the engine object.
  Added fonts can be accessed via an.fonts.name.
  Example:
    an:font('DOS/V re. JPN16', 'assets/Mx437_DOS-V_re_JPN16.ttf')
--]]
function anchor:font(name, filename, font_size)
  self.fonts[name] = object():build(function(self)
    self.tags.font = true
    self.source = love.graphics.newFont(filename, font_size, 'mono') 
    self.h = self.source:getHeight()
    table.insert(an.fonts, self)
  end)
end

--[[
  Returns the width of a given text in pixels with the font of the given name.
  Example:
    an:font_get_text_width('default', 'Some text') -> returns the width of 'Some text' in pixels using the 'default' font
]]--
function anchor:font_get_text_width(name, text)
  return self.fonts[name].source:getWidth(text)
end

--[[
  Loads and adds an image object to the engine object.
  Added images can be accessed via an.images.name.
  If w and h are defined, then the spritesheet is loaded as multiple individual images of size w, h.
  In that case, "name" should contain a list of names for each image (order is left to right, top to bottom).
  A padding value (default 0) can also be defined to specify the amount of empty space between each image on the spritesheet.
  Example:
    an:image('smile', 'assets/smile.png') -> loads a single image and stores it into an.images.smile
    an:image({'player_walk_1', 'player_walk_2', 'player_walk_3'}, 'assets/spritesheet.png', 32, 32, 1)
    -> loads a spritesheet with 3 images, each of size 32x32 and with padding of 1 pixel, into an.images.player_walk_1,2,3
]]--
function anchor:image(name, filename, w, h, padding)
  local padding = padding or 0
  if w and h then
    if type(name) ~= 'table' then error("When loading a spritesheet, 'name' must be a table of names for each image and not a single string.") end
    local source = love.graphics.newImage(filename)
    local source_w, source_h = source:getWidth(), source:getHeight()
    local source_columns, source_rows = math.floor((source_w + padding)/(w + padding)), math.floor((source_h + padding)/(h + padding))
    local source_image_data = love.image.newImageData(filename)
    local new_image_data = love.image.newImageData(w, h)
    local k = 1
    for j = 1, source_rows do
      for i = 1, source_columns do
        local u, v = 0, 0
        for x = (i-1)*(w+padding), (i*w)-1 + (i-1)*padding do
          v = 0
          for y = (j-1)*(h+padding), (j*h)-1 + (j-1)*padding do
            new_image_data:setPixel(u, v, source_image_data:getPixel(x, y))
            v = v + 1
          end
          u = u + 1
        end
        if not name[k] then return end
        self.images[name[k]] = object():build(function(self)
          self.tags.image = true
          self.source = love.graphics.newImage(new_image_data)
          self.w, self.h = self.source:getWidth(), self.source:getHeight()
          table.insert(an.images, self)
        end)
        k = k + 1
      end
    end
  else
    self.images[name] = object():build(function(self)
      self.tags.image = true
      self.source = love.graphics.newImage(filename)
      self.w, self.h = self.source:getWidth(), self.source:getHeight()
      table.insert(an.images, self)
    end)
  end
end

--[[
  Loads and adds a shader object to the engine object.
  Added shaders can be accessed via an.shaders.name.
  If the second argument isn't passed, anchor/assets/default.vert is used as the vertex shader.
  Example:
    an:shader('outline', nil, 'assets/outline.frag')
--]]
function anchor:shader(name, vs, fs)
  self.shaders[name] = object():build(function(self)
    self.tags.shader = true
    self.source = love.graphics.newShader(vs or 'anchor/assets/default.vert', fs)
    table.insert(an.shaders, self)
  end)
end

--[[
  Loads and adds a music object to the engine object.
  Example:
    an:music('song1', 'assets/song1.ogg')
    an:music_player_play_song('song1')
--]]
function anchor:music(name, filename)
  self.musics[name] = object():_sound(filename, true)
end

--[[
  Loads and adds a sound object to the engine object.
  Added sounds can be accessed via an.sounds.name.
  Example:
    an:sound_tag('sfx', 0.5)
    an:sound('jump', 'assets/jump.ogg', 'sfx')
    an.sounds.jump:sound_play()
--]]
function anchor:sound(name, filename)
  self.sounds[name] = object():_sound(filename)
end

--[[
  Sets volume and pitch for all sounds/instances and songs.
  Setting the pitch every frame, especially, is useful if you want to slow down or speed up all sounds when something happens.
  Like, if you want to, for instance, slow down everything by a certain amount whenever the player gets hit:
    an:slow(0.5, 0.5) -- slows everything to 0.5, linearly increasing to 1 during 0.5 seconds
  And then in some update function somewhere:
    an.sound_pitch = an.slow_amount
    an.music_pitch = an.slow_amount
  And this would match an's slow function with the pitch of all sounds and songs.
--]]
function anchor:update_audio(dt)
  for _, sound in ipairs(self.sounds) do sound:sound_update(dt) end
  for _, music in ipairs(self.musics) do music:sound_update(dt) end
end

--[[
  Sets the engine's color scheme.
  This populates the an.colors table with a set of colors that work nicely together in case your game is mostly drawing shapes instead of sprites.
  Colors can be accessed via an.colors.color_name[index], where index (0 for the color as declared) is a value from -20 to 20 that changes the color's brightness gradually.
  The themes available here are the ones I've used most on my prototypes, but you can add any palette you want.
  Make sure to read anchor/color.lua to understand how the color object works.
--]]
function anchor:anchor_set_theme()
  if self.theme == 'default' then
    self.colors = {
      white = object():color_255(255, 255, 255, 255, 0.025),
      black = object():color_255(0, 0, 0, 255, 0.025),
      fg = object():color_255(255, 255, 255, 255, 0.025),
      bg = object():color_255(0, 0, 0, 255, 0.025),
      gray1 = object():color_255(20, 20, 20, 255, 0.025),
      gray2 = object():color_255(60, 50, 50, 255, 0.025),
      gray3 = object():color_255(70, 70, 70, 255, 0.025),
      gray4 = object():color_255(162, 162, 162, 255, 0.025),
      gray5 = object():color_255(224, 224, 224, 255, 0.025),
      red = object():color_255(210, 63, 78, 255, 0.025),
      red1 = object():color_255(140, 50, 50, 255, 0.025),
      red2 = object():color_255(192, 63, 46, 255, 0.025),
      red3 = object():color_255(223, 173, 163, 255, 0.025),
    }
  elseif self.theme == 'snkrx' then
    self.colors = {
      white = object():color_255(255, 255, 255, 255, 0.025),
      black = object():color_255(0, 0, 0, 255, 0.025),
      gray = object():color_255(128, 128, 128, 255, 0.025),
      bg = object():color_255(48, 48, 48, 255, 0.025),
      fg = object():color_255(218, 218, 218, 255, 0.025),
      yellow = object():color_255(250, 207, 0, 255, 0.025),
      orange = object():color_255(240, 112, 33, 255, 0.025),
      blue = object():color_255(1, 155, 214, 255, 0.025),
      green = object():color_255(139, 191, 64, 255, 0.025),
      red = object():color_255(233, 29, 57, 255, 0.025),
      purple = object():color_255(142, 85, 158, 255, 0.025),
    }
  elseif self.theme == 'bytepath' then -- https://coolors.co/191516-f5efed-52b3cb-b26ca1-79b159-ffb833-f4903e-d84654
    self.colors = {
      white = object():color_255(255, 255, 255, 255, 0.025),
      black = object():color_255(0, 0, 0, 255, 0.025),
      gray = object():color_255(128, 128, 128, 255, 0.025),
      bg = object():color_hex('#111111ff', 0.025),
      fg = object():color_hex('#dededeff', 0.025),
      yellow = object():color_hex('#ffb833ff', 0.025),
      orange = object():color_hex('#f4903eff', 0.025),
      blue = object():color_hex('#52b3cbff', 0.025),
      green = object():color_hex('#79b159ff', 0.025),
      red = object():color_hex('#d84654ff', 0.025),
      purple = object():color_hex('#b26ca1ff', 0.025),
    }
  elseif self.theme == 'twitter_emoji' then -- colors taken from twitter emoji set
    self.colors = {
      white = object():color_255(255, 255, 255, 255, 0.01),
      black = object():color_255(0, 0, 0, 255, 0.01),
      gray = object():color_255(128, 128, 128, 255, 0.01),
      bg = object():color_255(48, 49, 50, 255, 0.01),
      fg = object():color_255(231, 232, 233, 255, 0.01),
      fg_dark = object():color_255(201, 202, 203, 255, 0.01),
      yellow = object():color_255(253, 205, 86, 255, 0.01),
      orange = object():color_255(244, 146, 0, 255, 0.01),
      blue = object():color_255(83, 175, 239, 255, 0.01),
      green = object():color_255(122, 179, 87, 255, 0.01),
      red = object():color_255(223, 37, 64, 255, 0.01),
      purple = object():color_255(172, 144, 216, 255, 0.01),
      brown = object():color_255(195, 105, 77, 255, 0.01),
    }
  elseif self.theme == 'tidal_waver' then -- colors initially taken from NISHIKIGATSUO's Tidal Hopper and then heavily modified
    self.colors = {
      white = object():color_255(255, 255, 255, 255, 0.01),
      black = object():color_255(0, 0, 0, 255, 0.01),
      fg_bright = object():color_255(245, 255, 237, 255, 0.01),
      bg_dark = object():color_255(19, 18, 0, 255, 0.01),
      fg = object():color_255(230, 230, 234, 255, 0.01),
      bg = object():color_255(46, 46, 58, 255, 0.01),
      red = object():color_255(211, 42, 53, 255, 0.01),
      purple = object():color_255(157, 97, 175, 255, 0.01),
      blue = object():color_255(0, 152, 182, 255, 0.01),
      orange = object():color_255(247, 104, 16, 255, 0.01),
      green = object():color_255(170, 203, 67, 255, 0.01),
      yellow = object():color_255(247, 196, 28, 255, 0.01),

      black_5 = object():color_255(32, 32, 29, 255, 0.01),
      green_1 = object():color_255(255, 244, 201, 255, 0.01),
      green_2 = object():color_255(228, 234, 157, 255, 0.01),
      gray_4 = object():color_255(205, 202, 204, 255, 0.01),
      blue_1 = object():color_255(201, 255, 240, 255, 0.01),
      blue_2 = object():color_255(139, 232, 232, 255, 0.01),
      blue_3 = object():color_255(73, 197, 209, 255, 0.01),
      blue_01 = object():color_255(82, 149, 201, 255, 0.01),
      blue_02 = object():color_255(69, 174, 204, 255, 0.01),
      purple_1 = object():color_255(226, 211, 255, 255, 0.01),
    }
  else
    error('theme name "' .. self.theme .. '" does not exist')
  end
end

require 'anchor.object' -- this needs to be last otherwise when object:class_add(anchor) is called things won't work properly, as the anchor class hasn't been defined yet
