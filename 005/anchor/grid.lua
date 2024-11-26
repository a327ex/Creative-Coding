--[[
  Module responsible for turning the object into a grid that can hold arbitrary data.
  Examples:
    object():grid(10, 10, 0)                -> creates a new 10 by 10 grid with all values zeroed
    object():grid(3, 2, {1, 2, 3, 4, 5, 6}) -> creates a new 3 by 2 grid with values 1, 2, 3 in the 1st row and 3, 4, 5 in the 2nd
    object():grid(10, 10, 'assets/map.png', {{0, 0, 0, 1}, {1, 1, 1, 0}, {1, 0, 0, 2}, {0, 1, 0, 3}})
  The last example loads a pixel map from the assets folder. This map should have the same size as the grid its attached to.
  The last argument is a table containing the RGB colors of each pixel in the map, and their value as a number in the grid.
  So, in this case, black would be 1, white would be 0, red would be 2 and green would be 3.
]]--
grid = class:class_new()
function grid:grid(w, h, v, u)
  self.tags.grid = true
  self.grid_w = w
  self.grid_h = h
  local v = v or 0

  self.grid = {}
  if type(v) == 'table' then
    for j = 1, h do
      for i = 1, w do
        self.grid[w*(j-1) + i] = v[w*(j-1) + i]
      end
    end
  elseif type(v) == 'string' then
    local map = love.image.newImageData(v)
    w, h = map:getDimensions()
    local error_1 = v .. " has unmatched colors. "
    local error_2 = "The last argument of a grid's init function must have values for all colors that appear on the map image."
    if not u then error(error_1 .. error_2) end
    for y = 1, h do
      for x = 1, w do
        r, g, b, a = map:getPixel(x-1, y-1)
        local index = array.index(u, function(v) return v[1] == r and v[2] == g and v[3] == b end)
        if index then
          self.grid[w*(y-1) + x] = u[index][4]
        else
          error(error_1 .. "(#{r}, #{g}, #{b}):n" .. error_2)
        end
      end
    end
  else
    for j = 1, h do
      for i = 1, w do
        self.grid[w*(j-1) + i] = v
      end
    end
  end
  return self
end

--[[
  Creates a copy of the grid.
  This is the same as "object():grid(self.grid_w, self.grid_h, self.grid)"
  Example:
    grid = object():grid(10, 10, 0)
    grid_2 = grid:grid_copy()
    grid:grid_set(1, 1, 1)
    print grid_2:grid_get(1, 1) -> prints 0
]]--
function grid:grid_copy()
  return object():grid(self.grid_w, self.grid_h, self.grid)
end

--[[
  Draws the grid based on the values passed to grid_set_dimensions. This is mostly for debug purposes.
  If you want to draw the grid in your game with more details just copy the contents of this function and go from there.
  Example:
    grid = object():grid(10, 10, 0)
    grid:grid_set_dimensions(an.w/2, an.h/2, 24, 24)
    grid:grid_draw(game, an.colors.white[0], 1)
]]--
function grid:grid_draw(layer, color, line_width)
  for i = 1, self.grid_w do
    for j = 1, self.grid_h do
      layer:rectangle(self.x1 + self.cell_w/2 + (i-1)*self.cell_w, self.y1 + self.cell_h/2 + (j-1)*self.cell_h, self.cell_w, self.cell_h, 0, 0, color, line_width)
    end
  end
end

-- Assume the following grid:
-- g = grid(10, 10, {
--   1, 1, 1, 0, 0, 0, 0, 1, 1, 0,
--   1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
--   1, 0, 0, 0, 1, 0, 1, 0, 1, 0,
--   0, 0, 0, 1, 1, 1, 0, 0, 1, 0,
--   0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
--   1, 0, 0, 0, 0, 0, 0, 1, 0, 0,
--   1, 1, 0, 0, 0, 0, 1, 1, 0, 0,
--   1, 1, 0, 1, 1, 0, 0, 1, 1, 1,
--   1, 1, 0, 1, 1, 0, 0, 0, 0, 1,
--   0, 0, 1, 0, 0, 0, 0, 0, 0, 0,
-- })
-- In this grid you can see that there are multiple islands of solid positions formed.
-- This function will go over the entire grid and find all the islands of solid values, mark them with different numbers, and return them.
-- Essentially, it would do this: {
--   1, 1, 1, 0, 0, 0, 0, 2, 2, 0,
--   1, 1, 0, 0, 0, 0, 2, 2, 2, 2,
--   1, 0, 0, 0, 3, 0, 2, 0, 2, 0,
--   0, 0, 0, 3, 3, 3, 0, 0, 2, 0,
--   0, 0, 0, 0, 3, 0, 0, 0, 0, 0,
--   4, 0, 0, 0, 0, 0, 0, 5, 0, 0,
--   4, 4, 0, 0, 0, 0, 5, 5, 0, 0,
--   4, 4, 0, 6, 6, 0, 0, 5, 5, 5,
--   4, 4, 0, 6, 6, 0, 0, 0, 0, 5,
--   0, 0, 7, 0, 0, 0, 0, 0, 0, 0,
-- }
-- All values form islands that are connected, and each of those islands is identified by a different number.
-- The function returns this information in two formats: an array of positions per island number, and the marked grid as shown above.
-- islands, marked_grid = g:grid_flood_fill(1) -> (the value passed in is what the solid value should be, in the case of the array we're using as an example 1 is the proper value)
-- islands is an array that looks like this: {
--  [1] = {{1, 1}, {2, 1}, {3, 1}, {1, 2}, {2, 2}, {1, 3}},
--  [2] = {{8, 1}, {9, 1}, {7, 2}, {8, 2}, {9, 2}, {10, 2}, {7, 3}, {9, 3}, {9, 4}},
--  ...
--  [7] = {{3, 10}}
-- }
-- It contains all the positions in each island, indexed by island number.
-- And marked_grid is simply a grid instance that looks exactly like the one shown above right after I said "Essentially, it would do this:"
function grid:grid_flood_fill(v)
  local islands = {}
  local marked_grid = grid(self.w, self.h, 0)

  local flood_fill = function(i, j, color)
    local queue = {}
    table.insert(queue, {i, j})
    while #queue > 0 do
      local x, y = unpack(table.remove(queue, 1))
      marked_grid:grid_set(x, y, color)
      table.insert(islands[color], {x, y})

      if self:grid_get(x, y-1) == v and marked_grid:grid_get(x, y-1) == 0 then table.insert(queue, {x, y-1}) end
      if self:grid_get(x, y+1) == v and marked_grid:grid_get(x, y+1) == 0 then table.insert(queue, {x, y+1}) end
      if self:grid_get(x-1, y) == v and marked_grid:grid_get(x-1, y) == 0 then table.insert(queue, {x-1, y}) end
      if self:grid_get(x+1, y) == v and marked_grid:grid_get(x+1, y) == 0 then table.insert(queue, {x+1, y}) end
    end
  end

  local color = 1
  islands[color] = {}
  for i = 1, self.w do
    for j = 1, self.h do
      if self:grid_get(i, j) == v and marked_grid:grid_get(i, j) == 0 then
        flood_fill(i, j, color)
        color = color + 1
        islands[color] = {}
      end
    end
  end

  islands[color] = nil
  return islands, marked_grid
end

--[[
  Generates a maze on this grid according to the given algorithm.
  The maze generation algorithm used is "Growing Tree" from https://weblog.jamisbuck.org/2011/1/27/maze-generation-growing-tree-algorithm.
  The values passed in are based on the Growing Tree's cell choice policy. The possible choices are:
    'newest' (recursive backtracking)
    'random' (prim)
    'oldest'
    'middle'
  Two additional values can be passed in, the first deciding how much the first policy affects the maze, and the second being the second policy.
  For instance, "'newest', 80, 'oldest'" will apply the 'newest' policy to 80% of cells, and the 'oldest' policy to 20% of cells.
  The initial grid should be zerod and after it is altered by this function each cell will contain a table with the following properties:
    x, y - the cell's x, y position in world units if grid_set_dimensions was previously set
    i, j - the cell's x, y position in grid units
    connections - a table with fields 'up', 'right', 'down' and 'left', each being true or false to signify if there's an opening to that neighbor
    walls - a table with fields 'up', 'right', 'down' and 'left', each being true or false to signify if there's a wall to that neighbor
      ("connections" and "walls" are opposites, if 'right' is true in one, 'right' should be false in the other and so on)
    distance_to_start - this cells' distance to the starting cell as an integer
  TODO: examples
--]]
function grid:grid_generate_maze(a, b, c)
  for i = 1, self.grid_w do
    for j = 1, self.grid_h do
      local x, y = self:grid_get_cell_position(i, j)
      self:grid_set(i, j, {x = x, y = y, i = i, j = j, connections = {}, walls = {up = true, right = true, down = true, left = true},
        distance_to_start = 0, visited = false})
    end
  end

  local all_cells = {}
  for _, _, cell in self:grid_pairs() do table.insert(all_cells, cell) end
  array.shuffle(all_cells)

  local cells = {}
  local cell = array.remove_random(all_cells)
  cell.visited = true
  table.insert(cells, cell)

  local get_index = function(a)
    if a == 'newest' then return #cells
    elseif a == 'oldest' then return 1
    elseif a == 'random' then return an:random_int(1, #cells)
    elseif a == 'middle' then return math.clamp(math.floor(#cells/2), 1, #cells)
    end
  end

  repeat
    local i = 0
    if not b and not c then
      i = get_index(a)
    elseif a and b and c then
      if an:random_bool(b) then
        i = get_index(a)
      else
        i = get_index(c)
      end
    end

    local cell = cells[i]
    local direction_opposites = {up = 'down', down = 'up', left = 'right', right = 'left'}
    local directions = {{x = 0, y = -1, name = 'up'}, {x = 1, y = 0, name = 'right'}, {x = 0, y = 1, name = 'down'}, {x = -1, y = 0, name = 'left'}}
    for _, direction in ipairs(array.shuffle(directions)) do
      local nx, ny = cell.i + direction.x, cell.j + direction.y
      local neighbor = self:grid_get(nx, ny)
      if neighbor and not neighbor.visited then
        cell.connections[direction.name] = true
        cell.walls[direction.name] = false
        neighbor.connections[direction_opposites[direction.name]] = true
        neighbor.walls[direction_opposites[direction.name]] = false
        neighbor.distance_to_start = cell.distance_to_start + 1
        i = nil
        neighbor.visited = true
        table.insert(cells, neighbor)
        break
      end
    end
    if i then table.remove(cells, i) end
  until #cells <= 0
end

--[[
  Returns the value at the given index, nil if the value isn't set or the indexes are out of bounds.
  To make things easier on yourself, consider making the default "no value" value 0 instead of nil,
  otherwise you won't be able to tell when the operation failed due to out of bounds vs. value not being set.
  Examples:
    self:grid(3, 2, {1, 2, 3, 4, 5, 6})
    self:grid_get()     -> nil
    self:grid_get(1, 1) -> 1
    self:grid_get(1, 2) -> 4
    self:grid_get(3, 2) -> 6
    self:grid_get(4, 4) -> nil due to out of bounds
]]--
function grid:grid_get(x, y)
  if not self:grid_is_outside_bounds(x, y) then
    return self.grid[self.grid_w*(y-1) + x]
  end
end

--[[
  Returns the position of the given cell, assuming self.x, self.y, self.cell_w and self.cell_h are set.
  Before using this function you must set the grid's dimensions using "grid_set_dimensions".
  Example:
    grid = object():grid(10, 10)
    grid:grid_set_dimensions(an.w/2, an.h/2, 20, 20)
    grid:grid_get_cell_position(1, 1) -> an.w/2 - 100 + 10, an.h/2 - 100 + 10)
]]--
function grid:grid_get_cell_position(i, j)
  local total_w, total_h = self.grid_w*self.cell_w, self.grid_h*self.cell_h
  local x1, y1 = self.x - total_w/2, self.y - total_h/2
  return x1 + self.cell_w/2 + (i-1)*self.cell_w, y1 + self.cell_h/2 + (j-1)*self.cell_h
end

--[[
  The opposite of grid_get_cell_position. Given positrion x, y, returns the i, j index assuming self.x, self.y, self.cell_w and self.cell_h are set.
  Before using this function you must set the grid's dimensions using "grid_set_dimensions".
  TODO: examples
--]]
function grid:grid_get_cell_index(x, y)
  return math.round((x - self.x1 + 0.5*self.cell_w)/self.cell_w, 0), math.round((y - self.y1 + 0.5*self.cell_h)/self.cell_h, 0)
end

--[[
  Internal function that checks if an index is or isn't out of bounds.
  As mentioned in the comments of grid_get, make the default "no value" value 0 instead of nil in your game.
  If you don't do this, then whenever a grid_get/set function returns nil, you won't know if it failed or not.
]]--
function grid:grid_is_outside_bounds(x, y)
  if x > self.grid_w then return true end
  if x < 1 then return true end
  if y > self.grid_h then return true end
  if y < 1 then return true end
end

--[[
  Returns an iterator over all the grid's values in left-right top-bottom order.
  Example:
    local grid = object():grid(10, 10)
    for i, j, v in grid:grid_pairs() do
      print(i, j, v)
    end
  The example above will print 1 to 10 on both axes as well as the values on each specific cell (in this example they're all zero).
--]]
function grid:grid_pairs()
  local i, j = 0, 1
  return function()
    i = i + 1
    if i > self.grid_w then i = 1; j = j + 1 end
    if i <= self.grid_w and j <= self.grid_h then
      return i, j, self:grid_get(i, j)
    end
  end
end

-- Rotates the grid in an anti-clockwise direction
-- g = grid(3, 2, {1, 2, 3, 4, 5, 6}) -> the grid looks like this:
-- [1, 2, 3]
-- [4, 5, 6]
-- g:grid_rotate_anticlockwise() -> now the grid looks like this:
-- [3, 6]
-- [2, 5]
-- [1, 4]
-- g:grid_rotate_anticlockwise() -> now the grid looks like this:
-- [6, 5, 4]
-- [3, 2, 1]
function grid:grid_rotate_anticlockwise()
  local new_grid = grid(self.h, self.w, 0)
  for i = 1, self.w do
    for j = 1, self.h do
      new_grid:grid_set(j, i, self:grid_get(i, j))
    end
  end

  for i = 1, new_grid.w do
    for k = 0, math.floor(new_grid.h/2) do
      local v1, v2 = new_grid:grid_get(i, 1+k), new_grid:grid_get(i, new_grid.h-k)
      new_grid:grid_set(i, 1+k, v2)
      new_grid:grid_set(i, new_grid.h-k, v1)
    end
  end

  return new_grid
end

-- Rotates the grid in a clockwise direction
-- g = grid(3, 2, {1, 2, 3, 4, 5, 6}) -> the grid looks like this:
-- [1, 2, 3]
-- [4, 5, 6]
-- g:grid_rotate_clockwise() -> now the grid looks like this:
-- [4, 1]
-- [5, 2]
-- [6, 3]
-- g:grid_rotate_clockwise() -> now the grid looks like this:
-- [6, 5, 4]
-- [3, 2, 1]
function grid:grid_rotate_clockwise()
  local new_grid = grid(self.h, self.w, 0)
  for i = 1, self.w do
    for j = 1, self.h do
      new_grid:grid_set(j, i, self:grid_get(i, j))
    end
  end

  for j = 1, new_grid.h do
    for k = 0, math.floor(new_grid.w/2) do
      local v1, v2 = new_grid:grid_get(1+k, j), new_grid:grid_get(new_grid.w-k, j)
      new_grid:grid_set(1+k, j, v2)
      new_grid:grid_set(new_grid.w-k, j, v1)
    end
  end

  return new_grid
end


--[[
  Sets the value on the given grid position and returns it if it was set successfully.
  Examples:
    self:grid(10, 10, 0)
    self:grid_set()                     -> nil
    self:grid_set(1, 1)                 -> nil
    self:grid_set(2, 2, 1)              -> 1
    self:grid_set(4, 8, function() end) -> returns the anonymous function passed in
    self:grid_set(11, 1, true)          -> nil due to out of bounds, so nothing is changed
]]--
function grid:grid_set(x, y, v)
  if not self:grid_is_outside_bounds(x, y) then
    self.grid[self.grid_w*(y-1) + x] = v
    return v
  end
end

--[[
  Sets the value of all cells on the grind.
  TODO: examples
--]]
function grid:grid_set_all(f)
  for j = 1, self.grid_h do
    for i = 1, self.grid_w do
      self:grid_set(i, j, f(i, j))
    end
  end
end

--[[
  Sets the grids dimensions. This sets the following attributes:
    self.x, self.y             - the grid's center position in world coordinates
    self.cell_w, self.cell_h   - the width and height of each cell
    self.x1, self.y1           - the grid's top-left corner
    self.x2, self.y2           - the grid's bottom-right corner
    self.w, self.h             - the grid's total size in world units
  The first 4 attributes should be passed in, the latter 6 are calculated automatically.
]]--
function grid:grid_set_dimensions(x, y, cell_w, cell_h)
  self.x, self.y = x, y
  self.cell_w, self.cell_h = cell_w, cell_h
  self.w, self.h = self.grid_w*self.cell_w, self.grid_h*self.cell_h
  self.x1, self.y1 = self.x - self.w/2, self.y - self.h/2
  self.x2, self.y2 = self.x + self.w/2, self.y + self.h/2
  return self
end

--[[
  Returns a string that represents the grid's state.
]]--
function grid:grid_tostring()
  local s = ''
  for j = 1, self.grid_h do
    s = s .. '['
    for i = 1, self.grid_w do
      s = s .. self:grid_get(i, j) .. ', '
    end
    s = s:sub(1, -3) .. ']\n'
  end
  return s
end

-- Converts the 2D grid to a 1D array
-- If i1,j1 and i2,j2 are passed then it applies only to the subgrid defined by those values.
-- g = grid(3, 2, 1)
-- g:grid_to_table() -> {1, 1, 1, 1, 1, 1}
-- g:grid_to_table(1, 1, 2, 2) -> {1, 1, 1, 1}
function grid:grid_to_table(i1, j1, i2, j2)
  local t = {}
  if i1 and j1 and i2 and j2 then
    for j = j1, j2 do
      for i = i1, i2 do
        if self:grid_get(i, j) then
          table.insert(t, self:grid_get(i, j))
        end
      end
    end
  else
    for j = 1, self.h do
      for i = 1, self.w do
        table.insert(t, self:grid_get(i, j))
      end
    end
  end
  return t, self.w
end
