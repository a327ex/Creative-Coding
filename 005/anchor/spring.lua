--[[
  This module implements springs based on https://github.com/a327ex/blog/issues/60.
  The arguments passed in are: the initial value of the spring, its stiffness and its damping.
  The class below implements a single spring object.
]]--
spring_1d = class:class_new()
function spring_1d:spring_1d(x, k, d)
  self.tags.spring_1d = true
  self.x = x or 0
  self.k = k or 100
  self.d = d or 10
  self.target_x = self.x
  self.v = 0
  return self
end

function spring_1d:spring_1d_update(dt)
  local a = -self.k*(self.x - self.target_x) - self.d*self.v
  self.v = self.v + a*dt
  self.x = self.x + self.v*dt
end

function spring_1d:spring_1d_pull(f, k, d)
  if k then self.k = k end
  if d then self.d = d end
  self.x = self.x + f
end

--[[
  Adds spring functionalities to an object using spring_1d.
  Multiple spring_1d objects can be added using spring_add and then referenced by name.
  Springs should be used by using their .x value on some variable you want to modify in a springy way, like an object's scale.
]]--
spring = class:class_new()
function spring:spring()
  self.tags.spring = true
  self.springs = {}
  self:spring_add('main', 1)
  return self
end

--[[
  Updates all spring_1d objects stored in self.springs.
  This is called automatically by whatever group the spring object is added to.
  Each spring's .x value can be accessed via self.springs.spring_name.x.
]]--
function spring:spring_update(dt)
  for name, spring_1d in pairs(self.springs) do
    spring_1d:spring_1d_update(dt)
  end
end

--[[
  Adds a new string to this object.
  Each string is identified by the given name and can have its value accessed via self.springs.name.x.
  Every spring object has a 'main' string added to it by default with a resting value of 1.
  Example:
    self:spring_add('shoot_scale', 1)
    self:spring_pull('shoot_scale', 0.25)
    print(self.springs.shoot_scale.x)
]]--
function spring:spring_add(name, x, k, d)
  self.springs[name] = object():spring_1d(x, k, d)
end

--[[
  Pulls the spring with the given name with a certain amount of force x.
  This force should be related to the spring's initial value self.x.
  Values k and d are stiffness and damping respectively.
  Examples:
    self:spring_pull('main', 0.5) -> if initial self.x was 1, this will make the spring bounce around 1.5 and until rest back at 1
    self:spring_pull('main', 0.5, 200, 5) -> same as above, but more bouncy and takes longer to stop bouncing
]]--
function spring:spring_pull(name, x, k, d)
  self.springs[name]:spring_1d_pull(x, k, d)
end
