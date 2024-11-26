--[[
  This module implements shaking based on https://jonny.morrill.me/en/blog/gamedev-how-to-implement-a-camera-shake-effect/.
  This is a flexible shaking effect that allows for different amplitutes, durations and frequencies.
  The class below implements a shake graph in 1D, which is an array filled with randomized samples that will be used for motion.
]]--
shake_1d = class:class_new()
function shake_1d:shake_1d(amplitude, duration, frequency)
  self.tags.shake_1d = true
  self.amplitude = amplitude or 0
  self.duration = duration or 0
  self.frequency = frequency or 60

  self.samples = {}
  for i = 1, (self.duration/1000)*self.frequency do self.samples[i] = an:random_float(-1, 1) end
  self.ti = an.time*1000
  self.t = 0
  self.shaking = true
  return self
end

function shake_1d:shake_get_noise(s)
  return self.samples[s] or 0
end

function shake_1d:shake_get_decay(t)
  if t >= self.duration then return 0 end
  return (self.duration - t)/self.duration
end

function shake_1d:shake_get_amplitude(t)
  if not t then
    if not self.shaking then return 0 end
    t = self.t
  end
  local s = (t/1000)*self.frequency
  local s0 = math.floor(s)
  local s1 = s0 + 1
  local k = self:shake_get_decay(t)
  return self.amplitude*(self:shake_get_noise(s0) + (s-s0)*(self:shake_get_noise(s1) - self:shake_get_noise(s0)))*k
end

--[[
  Implements a 2d shake based on https://jonny.morrill.me/en/blog/gamedev-how-to-implement-a-camera-shake-effect/.
  This is a normal, decaying shake with intensity, duration and frequency that shakes randomly horizontally and vertically.
]]--
normal_shake = class:class_new()
function normal_shake:_normal_shake() -- this is called "_normal_shake" so that the "normal_shake" function (which is the activation for a shake) can be called that without conflicts
  self.tags.normal_shake = true
  self.shakes = {x = {}, y = {}}
  self.normal_shake_amount = {x = 0, y = 0}
  self.shake_normal_amount = {x = 0, y = 0}
  self.last_normal_shake_amount = {x = 0, y = 0}
  return self
end

--[[
  Shakes the object with a certain intensity for duration seconds and with the given frequency.
  Higher frequencies result in jerkier movement, while lower frequencies result in smoother movement.
  Example:
    self:normal_shake(10, 1, 120) -> shakes the object with 10 intensity for 1 second and 120Hz frequency
]]--
function normal_shake:normal_shake(intensity, duration, frequency)
  table.insert(self.shakes.x, object():shake_1d(intensity, 1000*duration, frequency))
  table.insert(self.shakes.y, object():shake_1d(intensity, 1000*duration, frequency))
end

--[[
  Same as "shake" except only applies the shake on the x axis.
]]--
function normal_shake:normal_shake_horizontally(intensity, duration, frequency)
  table.insert(self.shakes.x, object():shake_1d(intensity, 1000*duration, frequency))
end

--[[
  Same as "shake" except only applies the shake on the y axis.
]]--
function normal_shake:normal_shake_vertically(intensity, duration, frequency)
  table.insert(self.shakes.y, object():shake_1d(intensity, 1000*duration, frequency))
end

--[[
  Updates all shake_1d objects stored in self.shakes.x and self.shakes.y.
  This is called automatically by whatever group the shake object is added to.
  The results of the shake are stored and can be accessed via self.shake_amount.x and self.shake_amount.y.
]]--
function normal_shake:normal_shake_update(dt)
  self.shake_normal_amount.x = 0
  self.shake_normal_amount.y = 0
  for _, z in ipairs{'x', 'y'} do
    for i = #self.shakes[z], 1, -1 do
      local shake = self.shakes[z][i]
      shake.t = an.time*1000 - shake.ti
      if shake.t > shake.duration then shake.shaking = false end
      self.shake_normal_amount[z] = self.shake_normal_amount[z] + shake:shake_get_amplitude()
      if not shake.shaking then table.remove(self.shakes[z], i) end
    end
  end

  self.normal_shake_amount.x = self.normal_shake_amount.x - self.last_normal_shake_amount.x
  self.normal_shake_amount.y = self.normal_shake_amount.y - self.last_normal_shake_amount.y
  self.normal_shake_amount.x = self.normal_shake_amount.x + self.shake_normal_amount.x
  self.normal_shake_amount.y = self.normal_shake_amount.y + self.shake_normal_amount.y
  self.last_normal_shake_amount.x = self.shake_normal_amount.x
  self.last_normal_shake_amount.y = self.shake_normal_amount.y
end

--[[
  Implements a directional spring-based shake.
  This is a normal, decaying shake with intensity, duration and frequency that shakes randomly horizontally and vertically.
]]--
spring_shake = class:class_new()
function spring_shake:_spring_shake() -- this is called "_spring_shake" so that the "spring_shake" function (which is the activation for a shake) can be called that without conflicts
  self.tags.spring_shake = true
  self.shakes = {x = object():spring_1d(), y = object():spring_1d()}
  self.spring_shake_amount = {x = 0, y = 0}
  self.shake_spring_amount = {x = 0, y = 0}
  self.last_spring_shake_amount = {x = 0, y = 0}
  return self
end

--[[
  Shakes the object with a certain intensity towards angle r using a spring motion,
  k and d are the spring's stiffness and damping.
  Example:
    self:spring_shake(10, math.pi/4) -> shakes the object with 10 intensity diagonally
]]--
function spring_shake:spring_shake(intensity, r, k, d)
  self.shakes.x:spring_1d_pull(-intensity*math.cos(r or 0), k, d)
  self.shakes.y:spring_1d_pull(-intensity*math.sin(r or 0), k, d)
end

--[[
  Same as "shake" except only applies the shake on the x axis.
]]--
function spring_shake:spring_shake_horizontally(intensity, r, k, d)
  self.shakes.x:spring_1d_pull(-intensity*math.cos(r or 0), k, d)
end

--[[
  Same as "shake" except only applies the shake on the y axis.
]]--
function spring_shake:spring_shake_vertically(intensity, r, k, d)
  self.shakes.y:spring_1d_pull(-intensity*math.sin(r or 0), k, d)
end

--[[
  Updates all spring_1d objects stored in self.shakes.x and self.shakes.y.
  This is called automatically by whatever group the shake object is added to.
  The results of the shake are stored and can be accessed via self.shake_amount.x and self.shake_amount.y.
]]--
function spring_shake:spring_shake_update(dt)
  self.shakes.x:spring_1d_update(dt)
  self.shakes.y:spring_1d_update(dt)
  self.shake_spring_amount.x = self.shakes.x.x
  self.shake_spring_amount.y = self.shakes.y.x
  self.spring_shake_amount.x = self.spring_shake_amount.x - self.last_spring_shake_amount.x
  self.spring_shake_amount.y = self.spring_shake_amount.y - self.last_spring_shake_amount.y
  self.spring_shake_amount.x = self.spring_shake_amount.x + self.shake_spring_amount.x
  self.spring_shake_amount.y = self.spring_shake_amount.y + self.shake_spring_amount.y
  self.last_spring_shake_amount.x = self.shake_spring_amount.x
  self.last_spring_shake_amount.y = self.shake_spring_amount.y
end
