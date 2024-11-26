--[[
  Modules responsible for anything animation related.
  It's divided into three different concepts: animation, animation_frames and animation_logic.
  animation_frames is located in the anchor/init.lua file and it's a container of all the images that make the up the animation.
  animation_logic is contained in this file, and is responsible for logically updating the animation; it can also be used individually in the case of animation-like behaviors without graphics.
  The animation class is repsonsible for merging animation_frames and animagion_logic into a complete animation.
  Example:
    an:image('player_spritesheet', 'assets/player_spritesheet.png')
    an:animation_frames('player_walk', 'player_spritesheet', 32, 32, {{1, 1}, {2, 1}})
    animation = object():animation('player_walk', 0.04, 'loop')
  The example above loads the player's spritesheet into an.images.player_spritesheet, then loads a specific walking animation as 'player_walk', and passes that into the final animation object.
  The animation object is then responsible for updating which frame the animation is in, and the player can draw it to the screen.
--]]
animation = class:class_new()
function animation:animation(animation_frames_name, delay, loop_mode, actions)
  self.tags.animation = true
  self.animation_frames = an._animation_frames[animation_frames_name]
  self.delay = delay
  self.loop_mode = loop_mode
  self.actions = actions or function() end

  self:animation_logic(self.delay, #self.animation_frames.size, self.loop_mode, self.actions)
  self.w, self.h = self.animation_frames.w, self.animation_frames.h
  return self
end

--[[
  Module responsible for logically updating an animation.
  This being separeted from the visual part of an animation is useful whenever you need animation-like behavior unrelated to graphics.
  Like when making your own animations with code only, for example:
    animation = object():animation_logic(0.04, 6, 'loop', {
      [1] = function()
        for i = 1, 3 do self:add(dust_particle(self.x, self.y)) end
        self.z = 9
      end,
      [2] = function() self:timer_tween(0.025, self, {z = 6}, math.linear, nil, 'move_2') end,
      [3] = function() self:timer_tween(0.025, self, {z = 3}, math.linear, nil, 'move_3') end,
      [4] = function()
        self:timer_tween(0.025, self, {z = 0}, math.linear, nil, 'move_4')
        self:timer_tween(0.05, self, {sx = 1}, math.linear, nil, 'move_5')
        self.sx = 1.1
      end,
    })

  This is an example of a code-only movement animation for an object for an old prototype I made.
  The arguments that animagion_logic takes are the delay between each frame, how many frames there are, the loop mode and a table of actions.
  The delay argument can be either a number or a table. If it is a table then the delay for each frame can be set individuallly:
    animation = object():animation_logic({0.02, 0.04, 0.06, 0.04}, 4, 'loop')
  In this example, it would take 0.02s to go from frame 1 to 2, 0.04s from 2 to 3, 0.06s from 3 to 4, and 0.04s from 4 to 1.
  Loop mode can be:
    'loop'   - the animation will start again from frame 1 when it reaches the end
    'once'   - the animation will stop once it reaches the end
    'bounce' - the animation will reverse once it reaches the end or the start

  Finally, the actions table can contain a list of functions, and each function will be called when that frame is reached.
  In the first example, once the second frame is reached, the function on index 2 would be called (timer tween changing z to 6).
  Index 0 can be used to call an action once the animation reaches its end, for instance:
    animation = object():animation_logic(0.04, 4, 'once', {[0] = function() self.dead = true end})
--]]
animation_logic = class:class_new()
function animation_logic:animation_logic(animation_delay, animation_size, loop_mode, animation_actions)
  self.tags.animation_logic = true
  self.animation_delay = animation_delay
  self.animation_size = animation_size
  self.loop_mode = loop_mode or 'once'
  self.animation_actions = animation_actions or function() end

  self.animation_timer = 0
  self.animation_frame = 1
  self.animation_direction = 1
  return self
end

--[[
  Updates animation logic state for this object.
  This advances the self.animation_frame value according to self.animation_delay and self.loop_mode values.
--]]
function animation_logic:animation_logic_update(dt)
  self.animation_timer = self.animation_timer + dt
  local delay = self.animation_delay
  if type(self.animation_delay) == 'table' then
    delay = self.animation_delay[self.animation_frame]
  end

  if self.animation_timer > delay then
    self.animation_timer = 0
    self.animation_frame = self.animation_frame + self.animation_direction
    if self.animation_frame > self.animation_size or self.animation_frame < 1 then
      if self.loop_mode == 'once' then
        self.animation_frame = self.animation_size
      elseif self.loop_mode == 'loop' then
        self.animation_frame = 1
      elseif self.loop_mode == 'bounce' then
        self.animation_direction = -self.animation_direction
        self.animation_frame = self.animation_frame + 2*self.animation_direction
      end
      if self.animation_actions and self.animation_actions[0] then
        self.animation_actions[0]()
      end
    end
    if self.animation_actions and self.animation_actions[self.animation_frame] then
      self.animation_actions[self.animation_frame]()
    end
  end
end

--[[
  Starts the aimation over from the first frame.
--]]
function animation_logic:animation_logic_reset()
  self.animation_frame = 1
  self.animation_timer = 0
  self.animation_direction = 1
end
