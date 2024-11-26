--[[
  Module responsible for stats in objects. Example:
    self:stats_set('str', 0, -10, 10)
  Now self.stats.str is a table with attribute self.x = 0, self.min = -10 and self.max = 10. The current value can be accessed via self.stats.str.x.
  If you want to add to the current value of the stat:
    self:stats_add('str', 10)
  This adds 10 to self.stats.str.x and thus makes it 10. If you want to subtract from it:
    self:stats_add('str', -10)
  Now self.stats.str.x is 0. If you try to increase or decrease the value beyond its limits then it will be capped by min and max values:
    self:stats_add('str', 1000)
  self.stats.str.x is now 10, which is the maximum it can be.

  Often times in games you don't want permanent changes of value, but temporary ones due to buffs/debuffs:
    self:stats_set_adds('str', self.str_buff_1 and 1 or 0, self.str_buff_2 and 1 or 0, self.str_buff_3 and 2 or 0, self.str_buff_4 and 4 or 0)
    self:stats_set_mults('str', self.str_buff_5 and 0.2 or 0, self.str_debuff_1 and -0.2 or 0, self.str_buff_6 and 0.5 or 0)
  Calling these two functions in an object's update function will make self.stats.str have buffs that add up to 8, and it will also have its buffs
  multiplied by the addition of all mults, in this case they all add up to 0.5, so the final str value would be (base + adds)*(1 + mults),
  which, assuming base str is 2, for instance, will end up being (2 + 8)*1.5 = 15, but because max for str is 10 then it will be just 10.

  It's important to note that self:stats_set_adds and self:stats_set_mults have to be called every frame with the appropriate modifiers set,
  as additions and multipliers set through these functions are temporary and assumed to be non-existent if the functions aren't called.
]]--
stats = class:class_new()
function stats:stats()
  self.tags.stats = true
  self.stats = {} -- this overwrites the "stats" function on this object, which is fine since you only need to initialize an object like this once
  return self
end

--[[
  Resets all adds and mults for every registered stat.
  Automatically called at the end of the frame for every object that has been initialized as a stats object.
]]--
function stats:stats_post_update(dt)
  for name, stat in pairs(self.stats) do
    stat.adds = {}
    stat.mults = {}
  end
end

--[[
  Registers a stat with the given unique name and with the given value and limits.
  Example:
    self:stats_set('hp', 10, 0, 20) -> self.stats.hp.x is now 10, with minimum of 0 and maximum of 20
]]--
function stats:stats_set(name, x, min, max)
  if self.stats[name] then
    self.stats[name].x = x or self.stats[name].x
    self.stats[name].min = min or self.stats[name].min
    self.stats[name].max = max or self.stats[name].max
  else
    self.stats[name] = {x = x, min = min or -1000000, max = max or 1000000, adds = {}, mults = {}}
  end
  self.stats[name].x = math.clamp(self.stats[name].x, self.stats[name].min, self.stats[name].max)
end

--[[
  Adds a value to the stat of the given name.
  Example:
    self:stats_set('hp', 10, 0, 100)
    self:stats_add('hp', 5)
  Given self.stats.hp.x was 10, it will now be 15. The stats' value will always be clamped to its min, max limits.
]]--
function stats:stats_add(name, v)
  self.stats[name].x = self.stats[name].x + v
  self.stats[name].x = math.clamp(self.stats[name].x, self.stats[name].min, self.stats[name].max)
end

--[[
  Sets additive values to the given stat for this frame.
  This must be called in an update function every frame.
  All additions are automatically reset at the end of the frame, so if it isn't called every frame then the additions won't be applied.
  Example:
    self:stats_set_adds('str', self.str_buff_1 and 2 or 0, self.str_buff_2 and 4 or 0) -> adds 6 to self.stats.str.x whenever both buffs are true
]]--
function stats:stats_set_adds(name, ...)
  for _, v in ipairs{...} do table.insert(self.stats[name].adds, v) end
  self:stats_update_stat_value(name)
end

--[[
  Sets multiplicative values to the given stat for this frame. Multiplicatives are added together and then multiply the (base + added) values.
  This must be called in an update function every frame.
  All mults are automatically reset at the end of the frame, so if it isn't called every frame then the mults won't be applied.
  Example:
    self:stats_set_mults('str', self.str_buff_3 and 0.2 or 0, self.str_buff_4 and 0.6 or 0)
      -> multiplies (base + added) by 1.8 whenever both buffs are true
]]--
function stats:stats_set_mults(name, ...)
  for _, v in ipairs{...} do table.insert(self.stats[name].mults, v) end
  self:stats_update_stat_value(name)
end

--[[
  Internal function that shouldn't be called by the user.
  This automatically updates the stat's value whenever stats_set_adds/mults is called.
  This means that you should apply buffs with those at the start of your object's frame if you want them to apply for the rest of the frame.
]]--
function stats:stats_update_stat_value(name)
  local adds, mults = 0, 1
  for _, add in ipairs(self.stats[name].adds) do adds = adds + add end
  for _, mult in ipairs(self.stats[name].mults) do mults = mults + mult end
  self.stats[name].x = math.clamp((stat.x + adds)*mults, self.stats[name].min, self.stats[name].max)
end
