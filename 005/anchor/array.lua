--[[
  This is a module that focuses on functions for the array part of a Lua table.
  All operations here that modify the array modify it in-place.
  If you do not want modify the original, create a copy of it first and then do the operation.
]]--
array = {}

--[[
  Creates a Lua table. "array" refers to the list/array part of a Lua table, not the hash/map part.
  If the first argument is a table, then all values in that table will be copied over to the array object.
  If the first argument is a number, then it will create an array repeating 0s or values according to the second argument.
  The "a" function is exposed as an alias for "array.new". This alias can be changed as it isn't used internally.
  Examples:
    array.new()    -> {}
    a()            -> {}
    a{1, 2, 3}     -> {1, 2, 3}
    a{1, nil, 3}   -> {1, nil, 3}
    a(3)           -> {0, 0, 0}
    a(3, true)     -> {true, true, true}
    a(5, function(i) return i end) -> {1, 2, 3, 4, 5}
]]--
function array.new(n, v)
  local n = n or 0
  local v = v or 0
  local t = {}
  if type(n) == 'table' then
    for i, v in pairs(n) do
      t[i] = v
    end
  elseif type(n) == 'number' then
    for i = 1, n do
      if type(v) == 'function' then
        t[i] = v(i)
      else
        t[i] = v
      end
    end
  end
  return t
end
a = function(n, v) return array.new(n, v) end

--[[
  Passes each element of the array to the given function.
  Returns true if the function never returns false or nil.
  Examples:
    array.all()                                           -> nil
    array.all({})                                         -> true
    array.all({}, function(v) return v == 0 end)          -> true
    array.all({1, 2, 3}, function(v) return v > 0 end)    -> true
    array.all({1, 2, 3}, function(v) return v < 2 end)    -> false
    array.all({2, 4, 6}, function(v) return v%2 == 0 end) -> true
    array.all({2, 4, 7}, function(v) return v%2 == 0 end) -> false
]]--
--]]
function array.all(t, f)
  if not t then return nil end
  for i = 1, #t do
    if not f(t[i], i) then
      return false
    end
  end
  return true
end

--[[
  Passes each element of the array to the given function.
  Returns true if the function returns true at least once.
  Examples:
    array.any()                                           -> nil
    array.any({})                                         -> false
    array.any({}, function(v) return v == 0 end)          -> false
    array.any({1, 2, 3}, function(v) return v > 0 end)    -> true
    array.any({1, 2, 3}, function(v) return v < 2 end)    -> true
    array.any({2, 4, 6}, function(v) return v%2 == 0 end) -> true
    array.any({1, 3, 7}, function(v) return v%2 == 0 end) -> false
--]]
function array.any(t, f)
  if not t then return nil end
  for i = 1, #t do
    if f(t[i], i) then
      return true
    end
  end
  return false
end

--[[
  Returns the average of the values in the array.
  Examples:
    array.average()                                     -> nil
    array.average({1})                                  -> 1
    array.average({1, 1})                               -> 1
    array.average({1, 3})                               -> 2
    array.average({-3, 3})                              -> 0
    array.average({3, -1, 2, 10, -6, 7, 8, 1000, -950}) -> 8.11111
--]]
function array.average(t)
  if #t == 0 then return nil end
  local avg = 0
  for _, v in ipairs(t) do
    avg = avg + v
  end
  return avg/#t
end

--[[
  NOTE: this only works on Lua 5.4, so commenting it out for LÖVE
  Returns the bitwise OR of all values in the array.
  Examples:
    array.bitwise_or()           -> 0
    array.bitwise_or({1}))       -> 1
    array.bitwise_or({1, 2}))    -> 3
    array.bitwise_or({1, 2, 3})) -> 3
    array.bitwise_or({1, 255}))  -> 255
    array.bitwise_or({256, 1}))  -> 257
--]]
--[[
function array.bitwise_or(t)
  local result = 0
  for _, v in ipairs(t) do
    result = result | v
  end
  return result
end
]]--

--[[
  Returns the number of elements in the array that are equal to the value passed in.
  If no argument is passed then it returns the array's length.
  If the argument is a function instead, then it counts the number of elements for which the function returns true.
  Examples:
    array.count()                                                       -> 0
    array.count({}, 1)                                                  -> 0
    array.count({1, 1, 2})                                              -> 3
    array.count({1, 1, 2}, 1)                                           -> 2
    array.count({1, 1, 2, 3, 4, 4}, function(v) return v > 3 end)       -> 2
    array.count({1, 1, 2, 3, 4, 4}, function(_, i) return i%2 == 0 end) -> 3
]]--
function array.count(t, v)
  if not v then
    return #t
  elseif type(v) == 'function' then
    local count = 0
    for i = 1, #t do
      if v(t[i], i) then
        count = count + 1
      end
    end
    return count
  else
    local count = 0
    for i = 1, #t do
      if t[i] == v then
        count = count + 1
      end
    end
    return count
  end
end

--[[
  Deletes all instances of element v from the array and returns the number of removed elements.
  Examples:
    array.delete()                         -> 0
    array.delete({}, 2)                    -> 0
    array.delete({1, 2}, 1)                -> 1
    array.delete({1, 1, 2}, 1)             -> 2
    array.delete({3, 4, 4, 1, 5, 4, 3}, 4) -> 3
]]--
function array.delete(t, v)
  local count = 0
  for i = #t, 1, -1 do
    if t[i] == v then
      table.remove(t, i)
      count = count + 1
    end
  end
  return count
end

--[[
  Returns a new array is a one-dimensional flattening of itself.
  That is, for every element that is in the array, extract its elements into the new array.
  The level argument can optionally be passed to indicate the level of recursion to flatten the array by.
  Examples:
    array.flatten()                      -> nil
    array.flatten({})                    -> {}
    array.flatten({1, 2})                -> {1, 2}
    array.flatten({1, 2, {3, 4}})        -> {1, 2, 3, 4}
    array.flatten({1, {2, {3, {4}}}})    -> {1, 2, 3, 4}
    array.flatten({1, {2, {3, {4}}}}, 1) -> {1, 2, {3, {4}}}
    array.flatten({1, {2, {3, {4}}}}, 2) -> {1, 2, 3, {4}}
--]]
function array.flatten(t, level)
  if not t then return nil end
  local level = level or 1000
  local out = {}
  local stack = {table.unpack(t)}
  while #stack > 0 do
    local v = table.remove(stack)
    if type(v) == 'table' then
      if not v.__flatten_level then v.__flatten_level = 0 end
      v.__flatten_level = v.__flatten_level + 1
      if v.__flatten_level > level or getmetatable(v) then
        table.insert(out, v)
      else
        for _, u in ipairs(v) do
          if type(u) == 'table' then u.__flatten_level = v.__flatten_level end
          table.insert(stack, u)
        end
      end
    else
      table.insert(out, v)
    end
  end
  for _, v in ipairs(out) do
    if type(v) == 'table' then
      v.__flatten_level = nil
    end
  end
  return array.reverse(out)
end

--[[
  Returns the elements in the array given indexes i and j.
  If only i is passed then it returns the value at that index.
  If both i and j are passed then it returns a new array containing the values in that range (inclusive).
  Both i and j can be negative indexes, which means they start counting from the end, with -1 being the last element.
  Examples:
    array.get()                    -> nil
    array.get({}, 2)               -> nil
    array.get({4, 3, 2, 1}, 1)     -> {4}
    array.get({4, 3, 2, 1}, 1, 3)  -> {4, 3, 2}
    array.get({4, 3, 2, 1}, 2, -1) -> {3, 2, 1}
    array.get({4, 3, 2, 1}, -2, 1) -> {2, 3, 4}
]]--
function array.get(t, i, j)
  if not i then return nil end
  if i < 0 then i = #t + i + 1 end
  if not j then return {t[i]} end
  if j < 0 then j = #t + j + 1 end
  if i == j then return {t[i]} end
  local out = {}
  for k = i, j, math.sign(j-i) do
    table.insert(out, t[k])
  end
  return out
end


--[[
  Given an array t and an index i that may be any number that goes beyond the bounds of this array, returns a normalized index as if the array were a circular buffer.
  Examples:
    array.get_circular_buffer_index() -> nil
    array.get_circular_buffer_index({}, -1) -> nil
    array.get_circular_buffer_index({'a', 'b', 'c'}, 1)  -> 1
    array.get_circular_buffer_index({'a', 'b', 'c'}, 0)  -> 3 -- because 0 goes beyond the lower bound (1) so it loops back to the end of the array
    array.get_circular_buffer_index({'a', 'b', 'c'}, 4)  -> 1 -- because 4 goes beyond the upper bound (3) so it looks back to the start of the array
    array.get_circular_buffer_index({'a', 'b', 'c'}, -1) -> 2
--]]
function array.get_circular_buffer_index(t, i)
  if not t then return nil end
  if #t == 0 then return nil end
  if i < 1 then i = i + #t end
  if i > #t then i = i - #t end
  return i
end

--[[
  Returns true if an element v is in the array.
  If the argument is a function instead, then it returns true if the function returns true for any element in the array.
  Examples:
    array.has()                                           -> false
    array.has({}, 1)                                      -> false
    array.has({1, 2})                                     -> false
    array.has({1, 2}, 1)                                  -> true
    array.has({1, 2, 3, 4}, 3)                            -> true
    array.has({1, 2, 3, 4}, 5)                            -> false
    array.has({1, 2, 3, 4}, function(v) return v > 3 end) -> true
    array.has({1, 2, 3, 4}, function(v) return v > 4 end) -> false
]]--
function array.has(t, v)
  if not v or #t < 1 then return nil end
  if type(v) == 'function' then
    for i = 1, #t do
      if v(t[i]) then
        return true
      end
    end
  else
    for i = 1, #t do
      if t[i] == v then
        return true
      end
    end
  end
  return false
end

--[[
  Returns the index of the first element in the array that is equal to v.
  If the argument is a function instead, then it returns the index of the first element for which the function returns true.
  Examples:
    array.index()                                                 -> nil
    array.index({}, 2)                                            -> nil
    array.index({2, 1}, 1)                                        -> 2
    array.index({2, 1, 2}, 2)                                     -> 1
    array.index({4, 4, 4, 2, 1}, function(v) return v%2 == 1 end) -> 5
    array.index({8, 6, 4, 1, 2}, function(v) return v*v < 30 end) -> 3
]]--
function array.index(t, v)
  if not v or #t < 1 then return nil end
  if type(v) == 'function' then
    for i = 1, #t do
      if v(t[i]) then
        return i
      end
    end
  else
    for i = 1, #t do
      if t[i] == v then
        return i
      end
    end
  end
end

--[[
  Returns the indexes of all elements in the array that are equal to v.
  If the argument is a function instead, then it returns the indexes of all elements for which the function returns true.
  Examples:
    array.indexes()                                                 -> nil
    array.indexes({}, 2)                                            -> nil
    array.indexes({2, 1}, 1)                                        -> {2}
    array.indexes({2, 1, 2}, 2)                                     -> {1, 3}
    array.indexes({4, 4, 4, 2, 1}, function(v) return v%2 == 0 end) -> {1, 2, 3, 4}
    array.indexes({8, 6, 4, 1, 2}, function(v) return v*v < 30 end) -> {3, 4, 5}
]]--
function array.indexes(t, v)
  if not v or #t < 1 then return nil end
  if type(v) == 'function' then
    local u = {}
    for i = 1, #t do
      if v(t[i]) then
        table.insert(u, i)
      end
    end
    return u
  else
    local u = {}
    for i = 1, #t do
      if t[i] == v then
        table.insert(u, i)
      end
    end
    return u
  end
end

--[[
  Returns a string created by converting each element into a string, with each element separated by the passed in separator.
  Examples:
    array.join()                                   -> ''
    array.join({1, 2, 3})                          -> '123' -- default separator is nothing
    array.join({1, 2, 3}, ', ')                    -> '1, 2, 3'
    array.join({true, function() end, a()}, ' - ') -> 'true - function: 0x0132bcf882d8 - table: 0x0132bcf88308'
]]--
function array.join(t, separator)
  local separator = separator or ''
  local s = ''
  for i = 1, #t do
    s = s .. tostring(t[i])
    if i < #t then s = s .. separator end
  end
  return s
end

--[[
  Modifies each element such that it is the result of function f being applied to it.
  If you wish to not modify the original array, then array.copy it first.
  Examples:
    array.map()                                            -> nil
    array.map({1, 2})                                      -> {1, 2} -- if f is not provided then it uses a default function that returns the original element
    array.map({1, 2}, function(v) return v*v end)          -> {1, 4}
    array.map({4, 3, 2, 1}, function(v, i) return v+i end) -> {5, 5, 5, 5}
--]]
function array.map(t, f)
  if not t then return nil end
  if not f then f = function(v) return v end end
  for i, v in ipairs(t) do
    t[i] = f(v, i)
  end
  return t
end

--[[
  Returns the maximum value in the array.
  If f is defined then the value that is returned from that function for each element is used for the comparison instead.
  Examples:
    array.max()             -> nil
    array.max({1, 2, 3})    -> 3
    array.max({-2, 0, -10}) -> 0
    array.max({{a = 1, b = 2}, {a = 4, b = 0}, {a = 3, b = 10}}, function(v) return v.a end) -> {a = 4, b = 0}
]]--
function array.max(t, f)
  local max = -1000000
  if f then
    for v in ipairs(t) do
      if f(v) > max then
        max = v
      end
    end
  else
    for v in ipairs(t) do
      if v > max then
        max = v
      end
    end
  end
  return max
end

--[[
  Prints the array part of the object, and also returns it as a string.
  Examples:
    array.print()            -> prints and returns '{}'
    array.print({1, 2, 3})   -> prints and returns '{[1] = 1, [2] = 2, [3] = 3}'
    array.print({1, nil, 3}) -> prints and returns '{[1] = 1, [3] = 3}'
    array.print(a(3))        -> prints and returns '{[1] = 0, [2] = 0, [3] = 0}'
]]--
function array.print(t)
  local u = {}
  for k, v in pairs(t) do
    if type(k) == 'number' then
      u[k] = v
    end
  end
  local s = table.tostring(u)
  print(s)
  return s
end

--[[
  Returns n random elements from the array that always come from unique indexes.
  An optional second argument can be passed to be used as the random number generator, uses "an" by default.
  Examples:
    array.random()                                       -> nil
    array.random({1, 2, 3})                              -> 3 -- default value for n is 1
    array.random({1, 2, 3}, 2)                           -> {3, 1}
    array.random({1, 2, 3}, 4)                           -> {1, 3, 2}
    array.random({4, 5, 6, 7, 8}, 1, object():random(1)) -> 4
    array.random({4, 5, 6, 7, 8}, 3, object():random(1)) -> {4, 5, 6}
]]--
function array.random(t, n, rng)
  local n = n or 1
  local rng = rng or an
  if n == 1 then
    return t[rng:random_int(1, #t)]
  else
    local u = {}
    local selected_indexes = {}
    while #u < n and #selected_indexes < #t do
      local i = rng:random_int(1, #t)
      if not array.has(selected_indexes, i) then
        table.insert(selected_indexes, i)
        table.insert(u, t[i])
      end
    end
    return u
  end
end

--[[
  Removes an element from the array at a specific position and returns it.
  This is no different from Lua's "table.remove".
  Examples:
    array.remove()                   -> nil
    array.remove({}, 1)              -> nil
    array.remove({3, 2, 1}, 1)       -> 3
    array.remove({1, 2, 3, 5, 8}, 4) -> 5
]]--
function array.remove(t, i)
  return table.remove(t, i)
end

--[[
  Returns n random elements from the array while also removing them.
  An optional second argument can be passed to be used as the random number generator, uses "an" by default.
  Examples:
    array.remove_random()                                       -> nil
    array.remove_random({1, 2, 3})                              -> 3         -- array is now {1, 2}
    array.remove_random({1, 2, 3}, 2)                           -> {3, 1}    -- array is now {2}
    array.remove_random({1, 2, 3}, 4)                           -> {1, 3, 2} -- array is now {}
    array.remove_random({4, 5, 6, 7, 8}, 1, object():random(1)) -> 4         -- array is now {5, 6, 7, 8}
    array.remove_random({4, 5, 6, 7, 8}, 3, object():random(1)) -> {4, 5, 6} -- array is now {7, 8}
]]--
function array.remove_random(t, n, rng)
  local n = n or 1
  local rng = rng or an
  if n == 1 then
    return table.remove(t, rng:random_int(1, #t))
  else
    local u = {}
    while #u < n and #u < #t do
      table.insert(u, table.remove(t, rng:random_int(1, #t)))
    end
    return u
  end
end

--[[
  Returns the array with all its elements reversed.
  If both i and j are passed then it returns the array but only with values in that range reversed.
  Both i and j can be negative indexes, which means they start counting from the end, with -1 being the last element.
  Examples:
    array.reverse()                    -> nil
    array.reverse({})                  -> {}
    array.reverse({1, 2, 3, 4})        -> {4, 3, 2, 1}
    array.reverse({1, 2, 3, 4}, 1, 2)  -> {2, 1, 3, 4}
    array.reverse({1, 2, 3, 4}, 2, -1) -> {1, 4, 3, 2}
--]]
function array.reverse(t, i, j)
  if not t then return nil end
  if not i then i = 1 end
  if i < 0 then i = #t + i + 1 end
  if not j then j = #t end
  if j < 0 then j = #t + j + 1 end
  if i == j then return t end
  for k = 0, (j-i+1)/2-1, math.sign(j-i) do
    t[i+k], t[j-k] = t[j-k], t[i+k]
  end
  return t
end

--[[
  Returns a new array containing all elements for which function f returns true.
  Examples:
    array.select()                                              -> nil
    array.select({1, 2, 3}, function(v) return v == 2 end)      -> {2}
    array.select({1, 2, 3, 4}, function(v) return v > 2 end)    -> {3, 4}
    array.select({4, 3, 2, 1}, function(_, i) return i > 1 end) -> {3, 2, 1}
]]--
function array.select(t, f)
  if not f then return nil end
  local u = {}
  for i = 1, #t do
    if f(t[i], i) then
      table.insert(u, t[i])
    end
  end
  return u
end

--[[
  Shuffles the array and returns it.
  An optional argument can be passed to be used as the random number generator, uses "an" by default.
  Examples:
    array.shuffle()                              -> {}
    array.shuffle({1, 2, 3})                     -> {2, 3, 1}
    array.shuffle({1, 2, 3}, object():random(1)) -> {3, 2, 1}
]]--  
function array.shuffle(t, rng)
  local rng = rng or an 
  for i = #t, 2, -1 do
    local j = rng:random_int(1, i)
    t[i], t[j] = t[j], t[i]
  end
  return t
end

--[[
  Returns the sum of all elements in the array.
  If f is defined then the value that is returned from that function for each element is used for the sum instead.
  Examples:
    array.sum()                                                                                   -> 0
    array.sum({1, 2, 3})                                                                          -> 6
    array.sum({-2, 0, 2}                                                                          -> 0
    array.sum({{a = 1, b = 1}, {a = 4, b = 0}, {a = 3, b = 3}}, function(v) return v.a + v.b end) -> 12
--]]
function array.sum(t, f)
  if f then
    local sum = 0
    for _, v in ipairs(t) do sum = sum + f(v) end
    return sum
  else
    local sum = 0
    for _, v in ipairs(t) do sum = sum + v end
    return sum
  end
end

--[[
  Copies the array passed in.
  All array.* functions modify the array passed in, so copying it first is useful if you don't want to lose the original.
  Examples:
    array.copy()                                 -> {}
    array.copy({1, 2, 3})                        -> {1, 2, 3}
    array.copy(a(3, function(i) return 2*i end)) -> {2, 4, 6}
    array.copy(a(3, true))                       -> {true, true, true}
]]--
function array.copy(t)
  local u = {}
  for i, v in pairs(t) do
    if type(i) == 'number' then
      u[i] = v
    end
  end
  return u
end

--[[
  Copies a table deeply.
  This should rarely be used (use array.copy instead) and is here only for convenience.
]]--
function table.copy(t)
  local copy = nil
  if type(t) == 'table' then
    copy = {}
    for k, v in next, t, nil do
      copy[table.copy(k)] = table.copy(v)
    end
  else
    copy = t
  end
  return copy
end

--[[
  Returns a string that represents the table's state.
  This should rarely be used (use array.print instead) and is here only for convenience.
]]--
function table.tostring(t)
  local t = t or {}
  if type(t) == 'table' then
    local s = '{'
    for k, v in pairs(t) do
      local u = k
      if type(k) ~= 'number' then u = '"' .. k .. '"' end
      s = s .. '[' .. u .. '] = ' .. table.tostring(v) .. ', '
    end
    if s ~= '{' then
      return s:sub(1, -3) .. '}'
    elseif s == '{' then
      return s .. '}'
    end
  elseif type(t) == 'string' then
    return '"' .. tostring(t) .. '"'
  else
    return tostring(t)
  end
end
