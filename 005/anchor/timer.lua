--[[
  Module responsible for timing related functions.
  Especially for doing things across multiple frames from the same place in code.
  This is commonly done with coroutines in other engines, but I prefer this timer approach.
  Simple usage examples:
    an:timer_after(2, function() print(1) end) -> prints 1 after 2 seconds
    an:timer_condition(function() return player.hp == 0 end, function() player.dead = true end) -> sets player.dead to true when its .hp becomes 0
    an:timer_tween(1, player, {w = 0, h = 0}, math.linear) -> tweens the player's size to 0 over 1 second linearly

  These examples use the global timer in "an". But each object can have their own timer as well if it is initialized as a timer.
  Objects might want to have their own timers because often you need to tag timers so they can be cancelled. For instance:
    if an:is_pressed'shoot' then
      self.sx, self.sy = 1.2, 1.2
      self:timer_tween(0.5, self., {sx = 1, sy = 1}, math.cubic_in_out, function() self.sx, self.sy = 1, 1 end, 'shoot_juice')

  In this example, whenever the shoot action is pressed, the object's sx and sy properties are set to 1.2 and then tweened down to 1 over 0.5 seconds. 
  This creates a little juicy effect on the object's size whenever it shoots. The problem with this is that if we were to do it without the 'shoot_juice' tag at the end, 
  if the player is pressing the shoot button faster than 0.5 seconds per press, we'd have multiple tweens acting on the same variable, which means that after each tween is done,
  it would call the function that makes sure that sx and sy values are actually 1, and so those sx and sy values would be set to 1 over and over, resulting in buggy behavior.

  To prevent this, the timer module uses the idea of tags. Each timer call can be tagged with a unique string, in this case 'shoot_juice', and whenever a new timer is called with that same string,
  the previous one is cancelled. So in this example, no matter how fast the player is pressing the shoot button, there is only ever a single tween operating on those variables.
  Because these strings should be unique, it means that each object should have their own internal timer instead of using the global one.
  The global one could still be used, but whenever you'd need a unique string you'd have to do something like this:
    if an:is_pressed'shoot' then
      self.sx, self.sy = 1.2, 1.2
      an:timer_tween(0.5, self., {sx = 1, sy = 1}, math.cubic_in_out, function() self.sx, self.sy = 1, 1 end, 'shoot_juice_' .. self.id)
  In this case, the global timer is being used but the string is unique because it's using the object's unique id in it.
  This, however is less preferable than just initializing each object that needs a timer as its own timer.

  The timer can be initialized to use seconds or frames as its unit of time:
    self:timer()         -> initialize it to use seconds
    self:timer(true)     -> initialize it to use frames
  If using frames, then the delays passed in to all functions must always be positive integers.
  The timer can also be initialized with a random number generator object (an by default) as its second argument.
  This RNG object is used when delays passed in are tables of two numbers and thus randomly generated in the range.

  This is one of the most important modules in the engine, so make sure to understand it!
]]--
timer = class:class_new()
function timer:timer(timer_use_frames, timer_rng)
  self.tags.timer = true
  self.timer_use_frames = timer_use_frames
  self.timer_rng = timer_rng or an
  self.timer_timers = {}
  return self
end

--[[
  Calls the action after delay seconds (or frames).
  If tag is passed in then any other timer actions with the same tag are automatically cancelled.
  Examples:
    self:timer_after(2, function() print(1) end)           -> prints 1 after 2 seconds
    self:timer_after(0.5, function() self.dead = true end) -> kills the object after 0.5 seconds
]]--
function timer:timer_after(delay, action, tag)
  local tag = tag or an:uid()
  self.timer_timers[tag] = {type = 'after', timer = 0, unresolved_delay = delay, delay = self:timer_resolve_delay(delay), action = action, multiplier = 1}
end

--[[
  Calls the action when self[field] changes.
  If times is passed in then it only calls the action for that amount of times.
  If after is passed in then it is called after the last time the action is called.
  If tag is passed in then any other timer actions with the same tag are automatically cancelled.
  Examples:
    self:timer_change('hp', function(current, previous) print(current, previous) end) -> prints self.hp as well as its previous value when self.hp changes
    self:timer_change('can_attack', function(current, previous) if current then self:attack() end end, 5) -> calls self:attack() every time self.can_attack becomes true for a total of 5 times
--]]
function timer:timer_change(field, action, times, after, tag)
  local tag = tag or an:uid()
  self.timer_timers[tag] = {type = 'change', field = field, current = self[field], previous = self[field], action = action, times = times or 0, max_times = times or 0, after = after or function() end}
end

--[[
  Calls the action once the condition becomes true.
  What this does is run the condition function every frame and store its result, and then it calls the action whenever the
  condition is true for this frame and wasn't true for the previous frame.
  If times is passed in then it only calls the action for that amount of times.
  If after is passed in then it is called after the last time the action is called.
  If tag is passed in then any other timer actions with the same tag are automatically cancelled.
  Examples:
    self:timer_condition(function() return self.hp == 0 end, function() self.dead = true end) -> kills the object when .hp becomes 0
    self:timer_condition(function() return objects:get_nearby_enemies(self, 64) > 4 end, function() self:shoot() end, 4)
  The example above is a bit involved. What's happening is that the shoot function will be called whenever it goes from there
  not being more than 4 enemies nearby to there being more than 4 enemies nearby, and it will do this for a total of 4 times.

  Mastering this function, as well as the other functions in this module, allows for quite powerful types of behavior that need to happen across time.
  I recommend looking at my codebases to and searching for "timer" to see all the ways I use it.
]]--
function timer:timer_condition(condition, action, times, after, tag)
  local tag = tag or an:uid()
  self.timer_timers[tag] = {type = 'condition', condition = condition, last_condition = false, action = action, times = times or 0, max_times = times or 0, after = after or function() end}
end

--[[
  Calls the action every delay seconds if the condition is true.
  If the condition isn't true when delay seconds are up then it waits for the condition to become true, waits for delay seconds and then calls the action.
  When the condition becomes true, the timer wil wait for delay seconds and then perform the action.
  If times is passed in then it only calls action for that amount of times.
  If immediate is passed in the it calls the action immediately once the condition becomes true.
  If after is passed in then it is called after the last time the action is called.
  If tag is passed in the any other timer actions with the same tag are automatically cancelled.
  Examples:
    self:timer_cooldown(2, function() return #self:get_objects_in_shape(self.attack_sensor, enemies) > 0 end, function() self:attack() end)
      -> only attacks when 2 seconds have passed and there are more then 0 enemies around
]]--
function timer:timer_cooldown(delay, condition, action, times, immediate, after, tag)
  local tag = tag or an:uid()
  self.timer_timers[tag] = {type = 'cooldown', timer = 0, index = 1, unresolved_delay = delay, delay = self:timer_resolve_delay(delay),
    condition = condition, last_condition = false, action = action, times = times or 0, max_times = times or 0, immediate = immediate, after = after or function() end, multiplier = 1}
end

--[[
  Calls the action every delay seconds (or frames).
  If times is passed in then it only calls the action for that amount of times.
  If immediate is passed in the it calls the action immediately once the timer starts.
  If after is passed in then it is called after the last time the action is called.
  If tag is passed in then any other timer actions with the same tag are automatically cancelled.
  Examples:
    self:timer_every(2, function() print(1) end)                             -> prints 1 every 2 seconds
    self:timer_every(2, function() print(1) end, 5, function() print(2) end) -> prints 1 every 2 seconds 5 times, then prints 2
]]--
function timer:timer_every(delay, action, times, immediate, after, tag)
  local tag = tag or an:uid()
  self.timer_timers[tag] = {type = 'every', timer = 0, index = 1, unresolved_delay = delay, delay = self:timer_resolve_delay(delay),
    action = action, times = times or 0, max_times = times or 0, after = after or function() end, multiplier = 1}
  if immediate then action() end
end

--[[
  Calls the action every start_delay to end_delay seconds times times.
  If start_delay = 1, end_delay = 5 and times = 3, then we want 3 numbers between 1 and 5, including 1 and 5; so our delays will be 1, 3, 5.
    self:timer_every_step(1, 5, 3, function() print(1) end) -> prints 1 after 1 second, then again after 3 seconds, then again after 5 seconds
  This is useful whenever you want to call a function multiple times with a delay that varies in a predictable manner. For instance:
    self:timer_every_step(0.05, 0.5, 20, function() player:spawn_particle() end) -> will start spawning particles fast then get slower over time
  If immediate is passed in then it calls the action immediately once the timer starts.
  If step_method is passed in then it is used to modify the step curve, by default it is math.linear but it can be any of the easing functions.
  If after is passed in then it is called after the last time action is called.
  If tag is passed in then any other timer actions with the same tag are automatically cancelled.
]]--
function timer:timer_every_step(start_delay, end_delay, times, action, immediate, step_method, after, tag)
  local tag = tag or an:uid()
  if times < 2 then error("timer_step_every's times must be >= 2") end
  local step = (end_delay - start_delay)/(times - 1)
  local delays = {}
  for i = 1, times do delays[i] = start_delay + (i-1)*step end
  if step_method then
    local steps = {}
    for i = 1, times-2 do table.insert(steps, i/(times-1)) end
    for i, step in ipairs(steps) do steps[i] = step_method(step) end
    local j = 1
    for i = 2, #delays-1 do
      delays[i] = math.remap(steps[j], 0, 1, start_delay, end_delay)
      j = j + 1
    end
  end
  self.timer_timers[tag] = {type = 'every_step', timer = 0, index = 1, delays = delays, action = action, times = times or 0, max_times = times or 0, after = after or function() end, multiplier = 1}
  if immediate then action() end
end

--[[
  Calls the action every frame for delay seconds.
  If after is passed in then it is called after the duration ends.
  If tag is passed in then any other timer actions with the same tag are automatically cancelled.
  Examples:
    self:timer_for(5, function() print(an:random_float(0, 100)) end) -> prints a float between 0 and 100 every frame for 5 seconds
--]]
function timer:timer_for(delay, action, after, tag)
  local tag = tag or an:uid()
  self.timer_timers[tag] = {type = 'for', timer = 0, unresolved_delay = delay, delay = self:timer_resolve_delay(delay), action = action, after = after or function() end, multiplier = 1}
end

--[[
  Calls the action every start_delay to end_delay seconds for the given duration.
  This is similar to timer_every_step, except that this only wants to make sure that the steps will fit within the given duration, without caring about how many times the action will be called.
  If duration = 5, start_delay = 0.5 and end_delay = 2, then we want to fit as many actions as possible starting with a 0.5s delay and ending with a 2s delay within a 5s interval.
  So in this example our delays would be: 0.5, 1, 1.5, 2, for a total of 4 action calls. Remember, with this function you don't have control over the amount of times the action will be called!
  It's also worth noting that sometimes the delays will add up to more than the duration value, as in some cases there exists no solution to the problem that doesn't under/overshoot it.
  I might add a setting that never allows overshooting, however I haven't tested it yet, in general changing math.ceil(times) to math.floor(times) should do it.

  This function is useful whenever you want to call a function multiple times with a delay that varies within a duration in a predictable manner. For instance:
    self:timer_for_step(1, 0.05, 0.2, function() player.hidden = not player.hidden end) -> will make the player blink over 1 second, starting with 0.05s per blink up to 0.2s per blink
  If immediate is passed in then it calls the action immediately once the timer starts.
  If step_method is passed in then it is used to modify the step curve, by default it is math.linear but it can be any of the easing functions.
  If after is passed in then it is called after the last time action is called.
  If tag is passed in then any other timer actions with the same tag are automatically cancelled.
--]]
function timer:timer_for_step(duration, start_delay, end_delay, action, immediate, step_method, after, tag)
  local tag = tag or an:uid()
  if start_delay > duration or end_delay > duration then error("timer_for_step's start_delay and end_delay must be < duration") end
  local times = math.ceil(2*duration/(start_delay + end_delay))
  local step = (end_delay - start_delay)/(times - 1)
  local delays = {}
  for i = 1, times do delays[i] = start_delay + (i-1)*step end
  if step_method then -- TODO: this is not entirely correct, but I can't be bothered to fix it at the moment
    local steps = {}
    for i, delay in ipairs(delays) do steps[i] = delay - start_delay end
    for i, step in ipairs(steps) do delays[i] = math.remap(step_method(step), 0, 1, start_delay, end_delay) end
  end
  self.timer_timers[tag] = {type = 'for_step', timer = 0, index = 1, delays = delays, action = action, after = after or function() end, multiplier = 1}
  if immediate then action() end
end

--[[
  Tweens target's values specified by the source table over delay seconds (or frames) using the given tweening method.
  All tween methods can be found in the math.lua file.
  If after is passed in then it is called after the tween ends.
  If tag is passed in then any other timer actions with the same tag are automatically cancelled.
  Examples:
    self:timer_tween(0.2, self, {sx = 0, sy = 0}, math.linear)                         -> tweens this object's scale to 0 linearly over 0.2 seconds
    self:timer_tween(0.2, self, {sx = 0, sy = 0}, math.cubic_in_out, function() self.dead = true end) -> same as above except also kills the object
]]--
function timer:timer_tween(delay, target, source, method, after, tag)
  local tag = tag or an:uid()
  local initial_values = {}
  for k, _ in pairs(source) do initial_values[k] = target[k] end
  self.timer_timers[tag] = {type = 'tween', timer = 0, unresolved_delay = delay, delay = self:timer_resolve_delay(delay), target = target,
    initial_values = initial_values, source = source, method = method or math.linear, after = after or function() end, multiplier = 1}
end

--[[
  Cancels a timer with the given tag.
  This happens automatically whenever the same tag is given to any timer action.
  Example:
    self:timer_after(2, function() print(1) end, 'print_1')
    self:timer_cancel('print_1')                 -> will not print 1 after 2 seconds since it was cancelled
]]--
function timer:timer_cancel(tag)
  self.timer_timers[tag] = nil
end

--[[
  Internal function that resolves the delay passed in when it is a table.
  All timer functions that take in a delay can also take it in as a range, like this:
    self:timer_after({2, 4}, function() print(1) end)
  And in this case it will print 1 after between 2 to 4 seconds randomly. timer_resolve_delay is called every time this range
  has to be resolved into a value. This happens only once for most timer actions, but multiple times for timer_every* calls.
]]--
function timer:timer_resolve_delay(delay)
  if type(delay) == 'table' then
    if self.timer_use_frames then
      return self.timer_rng:random_int(delay[1], delay[2])
    else
      return self.timer_rng:random_float(delay[1], delay[2])
    end
  else
    return delay
  end
end

--[[
  Sets a multiplier for a given tag.
  This is useful when you need the event to happen in a varying interval, like based on the player's attack speed, which might change every frame based on buffs.
  Call this on the update function with the appropriate multiplier.
--]]
function timer:timer_set_multiplier(tag, multiplier)
  if not self.timer_timers[tag] then return end
  self.timer_timers[tag].multiplier = multiplier or 1
end

--[[
  Returns the amount of time left on a given tag until it ends or until its next activation.
  This function doesn't work for timer_change and timer_condition, since those are events that aren't based on time.
  On delays that can be changed each time they're activated, like on "self:timer_every({2, 5}, ...)",
  this function will return the amount of time left based on the currently selected delay, and it will also return that delay as the second result.
  If the timer uses frames instead, then it will return the amount of frames left instead of time.
--]]
function timer:timer_get_time_left(tag)
  if not self.timer_timers[tag] then return end
  if self.timer_timers[tag].type == 'change' or self.timer_timers[tag].type == 'condition' then return end
  local t = self.timer_timers[tag]
  if type(t.unresolved_delay) == 'table' then
    return t.delay*t.multiplier - t.timer, t.delay*t.multiplier
  else
    return t.delay*t.multiplier - t.timer
  end
end

--[[
  Updates timer state for this object.
  This just goes over all tags (even timers without tags passed in get a default unique one assigned to them), and then
  advances the timer for that tag's type and does whatever job it's supposed to do. Adding a new type of timer call is fairly
  easy, although you shouldn't need to do this since the existing ones cover most behaviors:
    1. Add timer_your_timer_behavior method
    2. Add the table with the data for that type of timer behavior to self.timer_timers[tag]
    3. In this update, add a switch case handling your particular timer behavior
]]--
function timer:timer_update(dt)
  for tag, t in pairs(self.timer_timers) do
    if t.timer then
      if self.timer_use_frames then
        t.timer = t.timer + 1
      else
        t.timer = t.timer + dt
      end
    end
    if t.type == 'change' then
      t.previous = t.current
      t.current = self[t.field]
      if t.previous ~= t.current then
        t.action(t.current, t.previous)
        if t.times > 0 then
          t.times = t.times - 1
          if t.times <= 0 then
            t.after()
            self.timer_timers[tag] = nil
          end
        end
      end
    elseif t.type == 'condition' then
      local condition = t.condition()
      if condition and not t.last_condition then
        t.action(condition)
        if t.times > 0 then
          t.times = t.times - 1
          if t.times <= 0 then
            t.after()
            self.timer_timers[tag] = nil
          end
        end
      end
      t.last_condition = condition
    elseif t.type == 'cooldown' then
      local condition = t.condition()
      if not t.immediate then
        if condition and not t.last_condition then
          t.timer = 0
        end
      end
      if t.timer > t.delay*t.multiplier and condition then
        t.action()
        t.timer = 0
        t.delay = self:timer_resolve_delay(t.unresolved_delay)
        if t.times > 0 then
          t.times = t.times - 1
          if t.times <= 0 then
            t.after()
            self.timer_timers[tag] = nil
          end
        end
      end
      t.last_condition = condition
    elseif t.type == 'after' then
      if t.timer > t.delay*t.multiplier then
        t.action()
        self.timer_timers[tag] = nil
      end
    elseif t.type == 'every' then
      if t.timer > t.delay*t.multiplier then
        t.action()
        t.timer = t.timer - t.delay*t.multiplier
        t.index = t.index + 1
        t.delay = self:timer_resolve_delay(t.unresolved_delay)
        if t.times > 0 then
          t.times = t.times - 1
          if t.times <= 0 then
            t.after()
            self.timer_timers[tag] = nil
          end
        end
      end
    elseif t.type == 'every_step' then
      if t.timer > t.delays[t.index]*t.multiplier then
        t.action()
        t.timer = t.timer - t.delays[t.index]*t.multiplier
        t.index = t.index + 1
        if t.times > 0 then
          t.times = t.times - 1
          if t.times <= 0 then
            t.after()
            self.timer_timers[tag] = nil
          end
        end
      end
    elseif t.type == 'for' then
      t.action(dt)
      if t.timer > t.delay*t.multiplier then
        t.after()
        self.timer_timers[tag] = nil
      end
    elseif t.type == 'for_step' then
      if t.timer > t.delays[t.index]*t.multiplier then
        t.action()
        t.timer = t.timer - t.delays[t.index]*t.multiplier
        t.index = t.index + 1
        if t.index > #t.delays then
          t.after()
          self.timer_timers[tag] = nil
        end
      end
    elseif t.type == 'tween' then
      for k, v in pairs(t.source) do
        t.target[k] = math.lerp(t.method(t.timer/(t.delay*t.multiplier)), t.initial_values[k], v)
      end
      if t.timer > t.delay*t.multiplier then
        t.after()
        self.timer_timers[tag] = nil
      end
    end
  end
end
