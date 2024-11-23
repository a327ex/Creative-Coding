--[[
  This is a module that contains functions dealing with randomness.
  When initialized, it creates a random number generator object based on the seed passed in.
  The global "an" object is initialized as an instance of this, and thus should be used as the default RNG object.
  Do not use Lua's default random functions such as "math.random" as those have unpredictable behavior in them.
  Examples:
    rng = object():random()
    rng:random_float(0, 5)       -> returns a random float between 0 and 5
    rng:random_int(1, 10)        -> returns a random integer between 1 and 10
    an:random_int(1, 10)        -> same as above except using the an object instead
    an:random_weighted(1, 4, 5) -> 10% chance to return 1, 40% chance to return 2, 50% chance to return 3
]]--
random = class:class_new()
function random:random(seed)
  self.tags.random = true
  self.seed = seed or os.time()
  self.generator = love.math.newRandomGenerator(self.seed)
  return self
end

--[[
  Returns a random float between 0 and 2*math.pi.
  This is no different from "self:random_float(0, 2*math.pi)".
  Examples: 
    an:random_angle() -> 0
    an:random_angle() -> 1.56
    an:random_angle() -> 3.34
    an:random_angle() -> 6.28
]]--
function random:random_angle()
  return self:random_float(0, 2*math.pi)
end

--[[
  Returns true or false based on the chance passed in, which is a value from 0 to 100 representing the % chance of true.
  Examples:
    an:random_bool()     -> default value is 50, so 50% chance to return true
    an:random_bool(12)   -> 12% chance to return true
    an:random_bool(64)   -> 64% chance to return true
    an:random_bool(-8)   -> 0% chance to return true
    an:random_bool(1000) -> 100% chance to return true
]]--
function random:random_bool(chance)
  return self.generator:random(1, 1000) < 10*math.clamp(chance or 50, 0, 100)
end

--[[
  Returns a random float between min and max.
  Examples:
    an:random_float()      -> 0.5 -- default values are 0 and 1
    an:random_float(0, 5)  -> 0.01
    an:random_float(0, 5)  -> 1.00
    an:random_float(0, 5)  -> 4.82
    an:random_float(-5, 0) -> -3.55
    an:random_float(5, 0)  -> 3.14
]]--
function random:random_float(min, max)
  local min, max = min or 0, max or 1
  return (min > max and (self.generator:random()*(min - max) + max)) or (self.generator:random()*(max - min) + min)
end

--[[
  Returns a random integer between min and max.
  Examples:
    an:random_int()      -> 0 -- default values are 0 and 1
    an:random_int(0, 5)  -> 0
    an:random_int(0, 5)  -> 1
    an:random_int(0, 5)  -> 5
    an:random_int(-5, 0) -> -3
    an:random_int(5, 0)  -> 3
]]--
function random:random_int(min, max)
  return self.generator:random(min or 0, max or 1)
end

--[[
  Returns 1 or -1 based on the chance passed in, which is a value from 0 to 100 representing the % chance of 1.
  Examples:
    an:random_sign()    -> default value is 50, so 50% chance to return 1
    an:random_sign(18)  -> 18% chance to return 1
    an:random_sign(74)  -> 74% chance to return 1
    an:random_sign(-2)  -> 0% chance to return 1
    an:random_sign(128) -> 100% chance to return 1
]]--
function random:random_sign(chance)
  if self.generator:random(1, 1000) < 10*math.clamp(chance or 50, 0, 100) then return 1
  else return -1 end
end

--[[
  Returns an index with a given chance based on the weights passed in.
  The weights can be any value, as the percentage chance for any given index is based on the total sum of all values.
  Examples:
    an:random_weighted()               -> 0
    an:random_weighted(1, 1)           -> 50% chance to return 1, 50% chance to return 2
    an:random_weighted(10, 10)         -> 50% to 1, 50% to 2
    an:random_weighted(2, 2, 2)        -> 33.33% to 1, 33.33% to 2, 33.33% to 3
    an:random_weighted(20, 0, 80, 100) -> 10% to 1, 0% to 2, 40% to 3, 50% to 4
    an:random_weighted(-1, 1)          -> 0
    an:random_weighted(-2, 2, 2)       -> 3 -- in general just avoid negative values
]]--
function random:random_weighted(...)
  local weights = {...}
  local total_weight = 0
  for _, weight in ipairs(weights) do total_weight = total_weight + weight end
  total_weight = self:random_float(0, total_weight)

  local pick = 0
  for i = 1, #weights do
    if total_weight < weights[i] then
      pick = i
      break
    end
    total_weight = total_weight - weights[i]
  end
  return pick
end

--[[
  Returns a table of number_count integers, such that all numbers sum up to total, with each number having its value be [(total/number_count) +- (total/number_count)*(variation*0.01)]
  Essentially, each integer in the list is perturbed by the variation amount randomly, while the sum is always ensured to be total.
  The variation amount is given in a percentage, like 50 means 50% variation of the (total/number_count) value
  The combination of total, number_count and variation must result in a variation range equal to zero or higher than 1, values between 0 and 1 will error the function.
  Examples:
    an:random_subset_sum()           -> error, needs at least 2 values
    an:random_subset_sum(10, 2)      -> {4, 6}, if third value is omitted then it defaults to 20% variation
    an:random_subset_sum(10, 10)     -> {1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
    an:random_subset_sum(10, 8)      -> error, results in variation range between 0 and 1
    an:random_subset_sum(100, 5)     -> {24, 16, 18, 21, 21}
    an:random_subset_sum(100, 5, 50) -> {10, 25, 30, 17, 18}
--]]
function random:random_subset_sum(total, number_count, variation)
  local base_value = math.round(total/number_count, 0)
  local variation_range = base_value*((variation or 20)*0.01)
  if variation_range > 0 and variation_range < 1 then
    error('Variation range in random_subset_sum is smaller than 1 and higher than 0.\n This could be because total is too low, number_count is too high, or variation is too low.')
  end
  variation_range = math.round(variation_range, 0)
  local numbers = {}
  for i = 1, number_count do table.insert(numbers, base_value + self:random_int(-variation_range, variation_range)) end
  local sum = array.sum(numbers)
  while sum ~= total do
    local direction = -math.sign(sum - total)
    local index = self:random_int(1, #numbers)
    if (direction == -1 and numbers[index] > base_value - variation_range) or (direction == 1 and numbers[index] < base_value + variation_range) then
      numbers[index] = numbers[index] + direction
    end
    sum = array.sum(numbers)
  end
  return numbers
end
