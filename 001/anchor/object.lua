--[[
  Every object in the game, except for Lua's default data types (number, string, table, etc), is an "object" instance.
  Every object has all engine functions injected to it via the mixin feature ("class_add" function in the class module).
  Thus, every object can do everything every other object can, with very few exceptions.
  This is a no-bureaucracy approach to makes games that works well for me, someone who enjoys borderless thought and action.

  There are two ways of creating objects. The first is by creating a class and then instantiating an object:
    player = class:class_new(object)
    function player:new(x, y, args)
      self:object('player', args)
      self.x, self.y = x, y
    end

    function player:update(dt)
      layer:circle(self.x, self.y, 8, an.colors.fg[0])
    end
  In this example, the "player:new" function is the player class' constructor, and the "player:update" function is the update function that gets called every frame.
  Objects can also be named, and in the example above "self:object('player', args)" names this object's .name attribute to 'player'.
  In general, if you're going to name an object, that name should be unique, because names get used to organize objects in parent/child relations so that they can be more easily referred to by names.

  The second way of creating objects is anonymously/locally:
    player = function(x, y, args)
      return object('player', args):build(function(self)
        self.x, self.y = x, y
      end):action(function(self, dt)
        layer:circle(self.x, self.y, 8, an.colors.fg[0])
      end)
    end
  This is a more convenient way of defining new types of objects because it can be contained in a single function.
  It is, however, more expensive, due to the usage of multiple closures. Although if you're using this engine as it is right now, performance shouldn't be your primary focus.
  (In the sense that the engine is poorly optimized and you should be making games with it that don't really need that much processing power).
  This second way uses functions "object:build" and "object:action", which function the same as "new" and "update" when defining a class the first way.
  An object may have multiple actions attached to it, and if an action returns true it will automatically be removed from the object at the end of the frame.

  The engine organizes objects into a tree that is processed in DFS order and ensures that each object is only updated once per frame.
  All actions attached to an object are also guaranteed to be called only once per frame.
  This tree is used for organizing object hierarchies and for ordering object updates, while drawing and draw ordering are left entirely to the layer module.
  The root of the tree is always the "an" object, and so every object must be added to it or to one its children to be updated, for instance:
    an:add(player(an.w/2, an.h/2))
  In this example, because the player object is named (its name is 'player'), when it is added to "an", several things happen:
    "an" object's .children attribute is inserted the player instance
    player object's .parents attributed is inserted "an"
    if played is named (it is), an.player now points to the player object
    if an is named (it is), player.an now points to the "an" object
  This means that, following the example above, if you want to get a reference to the player object all you have to do is say "an.player" or "an.children[1]".
  And if you want to get a reference to "an" from one of the player's functions all you have to do is say "self.an" or "self.parents[1]".
  Objects may have multiple parents and multiple children, may refer to each other in loops, and everything work fine and their update function and action functions will only be updated once.

  Objects may also be tagged. By default, whenever a mixin module is initialized, an object's .tags attribute for that mixin is set to true.
  For instance, initializing the self:timer() mixin on an object's constructor means that self.tags.timer is now true.
  However, the user may also use the "object:tag" function to explicitly tag an object with the user's own gameplay-related strings.
  This can then be checked using the "is" function:
    player = object():tag('friendly', 'controllable')
    print(player:is('friendly'))             -> true
    print(player:is('controllable'))         -> true
    print(player:is('enemy'))                -> false
    print(object():collider():is('collider') -> true

  As previously mentioned, the engine works with a tree structure. The root object is always "an", and objects must be added to it or to one of its children to be updated.
  The exact order of operations for the tree update process goes like this:
    1. Every frame, before anything else happens, all tree nodes are collected into a list in DFS order.
    2. an's early update action is run, because an is the first node on the tree, and because early update actions run first; this function is defined in anchor/init.lua.
       This is where layers get their draw commands reset, where audio is updated and where the physics world is updated.
    3. For each object, the _early_update function calls the object's "early_update" function if it exists, and then calls all early actions attached to that object.
    4. For each object, the _update function calls all mixins that need to be called, calls the object's "update" function if it exists, and then calls all actions attached to that object.
    5. For each object, the _late_update function calls all mixins to be called, calls the object's "late_update" function if it exists, and then calls all late actions attached to that object.
    6. For each object, the cleanup function removes all early actions, actions and late actions that need to be removed (if they returned true that frame).
    7. For each object, the remove_dead_branch function removes all objects under it if it is dead. This removal also unlinks parents/children and calls "destroy" on all dead branch objects.
  There are several important things to note about this setup. The first is that this is only used for organizing object update order.
  There is nothing about the tree that changes how or when objects are drawn, that's left entirely up to the layer module and the calls each object makes to it from its update function.
  Second, because objects are collected at step 1, any object that gets added in the next steps will not get updated this frame, since it's not in the list of nodes that were collected in that step.
  Third, when an object dies it also kills all objects under it, which means that care must be taken when creating objects to choose parents with similar lifetime behaviors.
  Fourth, this setup naturally adds more complexity to the engine and to gameplay code, but I deemed this complexity worth it since it solves multiple problems I've had for years at once.

  If you want to use this code, I'd highly recommend reading the code in this file as well as anchor/init.lua to understand everything that's happening clearly.
  I also recommend reading some of my codebases that are/will be made available on GitHub that use this setup to see what it looks like in action.
--]]
object = class:class_new()
object:class_add(anchor)
object:class_add(animation)
object:class_add(animation_logic)
object:class_add(camera)
object:class_add(collider)
object:class_add(color)
object:class_add(grid)
object:class_add(input)
object:class_add(layer)
object:class_add(mouse_hover)
object:class_add(music_player)
object:class_add(normal_shake)
object:class_add(physics_world)
object:class_add(random)
object:class_add(shake_1d)
object:class_add(sound)
object:class_add(spring)
object:class_add(spring_1d)
object:class_add(spring_shake)
object:class_add(stats)
object:class_add(text)
object:class_add(timer)
object:class_add(ui)

object.id = 0
-- This is here for when the object can be created directly without a class definition.
function object:new(name, t)
  self.name = name
  for k, v in pairs(t or {}) do self[k] = v end
  self.id = object.id
  object.id = object.id + 1
  self.tags = {}
  self.parents = {}
  self.children = {}
  self.early_actions = {}
  self.early_action_tags = {}
  self.early_actions_marked_for_removal = {}
  self.actions = {}
  self.action_tags = {}
  self.actions_marked_for_removal = {}
  self.late_actions = {}
  self.late_action_tags = {}
  self.late_actions_marked_for_removal = {}
  self.dead = false -- removes from parent at the end of the frame when true, also removes all children
  self.slow_amount = 1
  self.step = 0 -- counts how many steps this object has been alive for
  self.first_step = true -- only true when self.step <= 1, so only true once on its first step
  self.flashing = false
end

-- This is here for when a class needs to be initialized as an object (in the class' constructor).
function object:object(name, t)
  self.name = name
  for k, v in pairs(t or {}) do self[k] = v end
  self.id = object.id
  object.id = object.id + 1
  self.tags = {}
  self.parents = {}
  self.children = {}
  self.early_actions = {}
  self.early_action_tags = {}
  self.early_actions_marked_for_removal = {}
  self.actions = {}
  self.action_tags = {}
  self.actions_marked_for_removal = {}
  self.late_actions = {}
  self.late_action_tags = {}
  self.late_actions_marked_for_removal = {}
  self.dead = false -- removes from parent at the end of the frame when true, also removes all children
  self.slow_amount = 1
  self.step = 0 -- counts how many steps this object has been alive for
  self.first_step = true -- only true when self.step <= 1, so only true once on its first step
  self.flashing = false
  return self
end

--[[
  Alias for an immediate action that only runs once. The function passed in will immediately be called.
  This is useful when creating objects locally as using an action that returns true has a delay of one frame before the constructor action is run.
--]]
function object:build(action)
  action(self)
  return self
end

--[[
  Attaches an action to the object and returns the object.
  The action function is called exactly once per frame as long as the object its attached to can be traverse to from the root node.
  The action will be run for the first time on the frame after it was attached to the object.
  The action function should accept two arguments: the object its attached to (self) and the frame delta value (dt).
  If the action function returns true then the action will automatically be removed from its object at the end of the frame.
  Multiple actions may be attached to one object, and actions may have unique tags to differentiate between them.
  If the tag is omitted then it will be chosen automatically.
  The order in which actions within an object are run is based on the order in which they were attached to it.
--]]
function object:action(action, tag)
  local tag = tag or an:uid()
  table.insert(self.action_tags, tag)
  self.actions[tag] = action
  return self
end

--[[
  Exactly the same as "object:action", but with early actions instead.
  Early actions are actions that run at the start of the frame, before any normal actions for any nodes have been run.
--]]
function object:early_action(action, tag)
  local tag = tag or an:uid()
  table.insert(self.early_action_tags, tag)
  self.early_actions[tag] = action
  return self
end

--[[
  Exactly the same as "object:action", but with late actions instead.
  Late actions are actions that run at the end of the frame, after all normal actions for all nodes have already been run.
--]]
function object:late_action(action, tag)
  local tag = tag or an:uid()
  table.insert(self.late_action_tags, tag)
  self.late_actions[tag] = action
  return self
end

--[[
  Adds a method to the object. This is the same as defining "class:method_name".
  This is useful when creating objects locally as you can chain this with build + action to build the object's behavior entirely locally.
--]]
function object:method(name, action)
  if self[name] then error('"' .. name .. '" is already used as a field on this object - ' .. self:get_who_called_me()) end
  self[name] = action
  return self
end

--[[
  Updates this object's state. This is called exactly once per frame per object according to the tree's shape.
  An object may have multiple actions attached to it, and they all get called here in the sequence they were attached to the object.
  Some mixins are updated here, before any actions, for automation/convenience.
  This is named "_update" instead of "update" so the user can have his own "update" function named without conflicts.
--]]
function object:_update(dt)
  if not self:is('anchor') then dt = dt*self.slow_amount end -- anchor object already multiplies its own .slow_amount attribute to all objects on the tree

  if self.tags.input then self:input_update(dt) end
  if self.tags.sound then self:sound_update(dt) end
  if self.tags.timer then self:timer_update(dt) end
  if self.tags.animation_logic then self:animation_logic_update(dt) end
  if self.tags.spring then self:spring_update(dt) end
  if self.tags.normal_shake then self:normal_shake_update(dt) end
  if self.tags.spring_shake then self:spring_shake_update(dt) end
  if self.tags.mover then self:mover_update(dt) end
  if self.tags.mouse_hover then self:mouse_hover_update(dt) end

  if self.update then self:update(dt) end
  for _, action_tag in ipairs(self.action_tags) do
    if self.actions[action_tag](self, dt) then
      table.insert(self.actions_marked_for_removal, action_tag)
    end
  end
end

--[[
  Exacly the same as "_update" but with early actions instead.
  This also does object upkeep on certain things, since it's called before any other update actions.
  Early actions happen before an object's "update" function, and before all of its actions and late actions.
  Actions happen after early actions, after an object's "update" function, and before all of its late actions.
  Late actions happen after early actions, after an object's "update" function, and after all its actions.
--]]
function object:_early_update(dt)
  if not self:is('anchor') then dt = dt*self.slow_amount end
  self.step = self.step + 1
  self.first_step = self.step <= 1

  self.early_actions_marked_for_removal = {}
  self.actions_marked_for_removal = {}
  self.late_actions_marked_for_removal = {}

  if self.early_update then self:early_update(dt) end
  for _, early_action_tag in ipairs(self.early_action_tags) do
    if self.early_actions[early_action_tag](self, dt) then
      table.insert(self.early_actions_marked_for_removal, early_action_tag)
    end
  end
end

--[[
  Exactly the same as "_update" but with late actions instead.
  Some mixins are update here, after all late actions, for automation/convenience.
--]]
function object:_late_update(dt)
  if self.late_update then self:late_update(dt) end
  for _, late_action_tag in ipairs(self.late_action_tags) do
    if self.late_actions[late_action_tag](self, dt) then
      table.insert(self.late_actions_marked_for_removal, late_action_tag)
    end
  end

  if self.tags.stat then self:state_post_update() end
end

--[[
  This is a special function that happens after all late update actions have been called for every object and before "object:cleanup" is called for any object.
  This is mostly to be used by the "an" object, but in the future other objects might find use for it.
  If that happens, then that use needs to be of the "cleanup" sort and not involve actual game logic.
--]]
function object:_final_update()
  if self.tags.physics_world then self:physics_world_post_update() end
  if self.tags.input then self:input_post_update() end
end

--[[
  Removes all actions and late actions that were marked for removal in update or late_update.
  An object can have no actions or late actions attached to it and it will simply do nothing.
  TO kill it, .dead must explicitly be set to true. When that happens, the object and its children will be removed from the tree.
  Dead objects will be destroyed after "cleanup" is called for all objects in the tree, and will also have their "destroy" function called, if it exists.
--]]
function object:cleanup()
  while #self.early_actions_marked_for_removal > 0 do
    local early_action_tag = table.remove(self.early_actions_marked_for_removal)
    self.early_actions[early_action_tag] = nil
    array.delete(self.early_action_tags, early_action_tag)
  end
  while #self.actions_marked_for_removal > 0 do
    local action_tag = table.remove(self.actions_marked_for_removal)
    self.actions[action_tag] = nil
    array.delete(self.action_tags, action_tag)
  end
  while #self.late_actions_marked_for_removal > 0 do
    local late_action_tag = table.remove(self.late_actions_marked_for_removal)
    self.late_actions[late_action_tag] = nil
    array.delete(self.late_action_tags, late_action_tag)
  end
end

--[[
  Destroys anything created by the object that's not only referenced in itself and thus needs to be explicitly removed.
  For now this is only collider + joint mixins.
--]]
function object:destroy()
  if self.tags.collider then self:collider_destroy() end
  if self.tags.joint then self:joint_destroy() end
  self.destroyed = true
end

--[[
  Traverses the tree in DPS left-right order, collects all nodes into a list, and then returns it.
  This function is automatically called once per frame on the root object to define the order in which all objects will be updated.
  It's also called to prune dead branches at the end of the frame, for objects that have their .dead attribute set to true.
  Maybe later I can implement a way to call this less times per frame by reusing results from previous calls, but for now this will do.
--]]
function object:get_all_children()
  local nodes = {}
  local visited = {}
  local stack = {}
  for i = #self.children, 1, -1 do table.insert(stack, self.children[i]) end
  while #stack > 0 do
    local node = table.remove(stack)
    if not visited[node] then
      visited[node] = true
      table.insert(nodes, node)
      for i = #node.children, 1, -1 do table.insert(stack, node.children[i]) end
    end
  end
  return nodes
end

--[[
  Traverses the tree up in DFS left-right order, collects all parents into a list, and then returns it.
  I can't think of many uses for this function as usually you only want to find a specific parent with find_parent, but it's here for completion's sake.
--]]
function object:get_all_parents()
  local parents = {}
  local visited = {}
  local stack = {}
  for i = #self.parents, 1, -1 do table.insert(stack, self.parents[i]) end
  while #stack > 0 do
    local parent = table.remove(stack)
    if not visited[parent] then
      visited[parent] = true
      table.insert(parents, parent)
      for i = #parent.parents, 1, -1 do table.insert(stack, parent.parents[i]) end
    end
  end
  return parents
end

--[[
  Traverses the tree in DFS left-right order and returns the first node that has the given name or tag.
  Use this instead of get_all_children when you don't need to iterate over the entire branch and just want the first node that fits.
  Example:
    a = object('a')
    b = object('b')
    c = object('c')
    d = object('d')
    e = object('e')
    f = object('f')
    a:add(b, c)
    b:add(d, e)
    e:add(f)

    a:find_child('a') -> nil, a isn't its own child
    a:find_child('b') -> ref to object b
    a:find_child('e') -> ref to object e
    a:find_child('f') -> ref to object f
    a:find_child('g') -> nil
    b:find_child('c') -> nil, c is only a child of a
--]]
function object:find_child(name_or_tag)
  local stack = {}
  local visited = {}
  for i = #self.children, 1, -1 do table.insert(stack, self.children[i]) end
  while #stack > 0 do
    local node = table.remove(stack)
    if not visited[node] then
      visited[node] = true
      if node.name == name_or_tag or node.tags[name_or_tag] then
        return node
      else
        for i = #node.children, 1, -1 do table.insert(stack, node.children[i]) end
      end
    end
  end
end

--[[
  Traverses the tree up in DFS left-right order and returns the first parent that has the given name or tag.
  Use this instead of get_all_parents when you don't need to iterate over the entire tree and just want the first parent that fits.
  Example:
    a = object('a')
    b = object('b')
    c = object('c')
    d = object('d')
    e = object('e')
    f = object('f')
    a:add(b, c)
    b:add(d, e)
    c:add(d)
    d:add(f)

    f:find_parent('f') -> nil, f isn't its own parent
    f:find_parent('a') -> ref to object a
    f:find_parent('b') -> ref to object b
    f:find_parent('c') -> ref to object c
    f:find_parent('d') -> ref to object d
    f:find_parent('g') -> nil
    f:find_parent('e') -> nil
--]]
function object:find_parent(name_or_tag)
  local stack = {}
  local visited = {}
  for i = #self.parents, 1, -1 do table.insert(stack, self.parents[i]) end
  while #stack > 0 do
    local parent = table.remove(stack)
    if not visited[parent] then
      visited[parent] = true
      if parent.name == name_or_tag or parent.tags[name_or_tag] then
        return parent
      else
        for i = #parent.parents, 1, -1 do table.insert(stack, parent.parents[i]) end
      end
    end
  end
end

--[[
  Returns an iterator over all object's children in DFS left-right order.
  This goes over not only the object's direct children, but also the children's children and so on until leaf nodes are reached.
  Example:
    for i, child in self:child_pairs() do
      -- do something with child
    end
--]]
function object:child_pairs()
  local all_children = self:get_all_children()
  local i = 0
  return function()
    i = i + 1
    return i, all_children[i]
  end
end

--[[
  Removes all objects under this one if it is dead. This removes this entire branch from the tree by disconnecting its parents.
  All objects in this branch have "destroy" called, however internal parent/child links aren't removed, and only the link from self to its parents are.
  This means that if other objects are linking to any objects in this branch, the entire branch will leak. Need to test on how often that will actually happen.
  This function is called at the end of the frame for every .dead object that hasn't already been destroyed.
  Call order should be BFS for better performance, since .dead nodes higher up would be visited first, but for now DFS will do.
--]]
function object:remove_dead_branch(dont_destroy_self)
  if self.dead and not self.destroyed then
    local all_children = self:get_all_children()
    for i = #all_children, 1, -1 do
      local object = all_children[i]
      if #object.parents <= 1 then
        object:destroy()
      else
        local any_parent_not_part_of_this_branch = false
        for _, parent in ipairs(object.parents) do
          if not table.has(all_children, parent) and parent ~= self then
            any_parent_not_part_of_this_branch = true
            break
          end
        end
        -- Only destroy this object if all its direct parents are self's children or self itself.
        if not any_parent_not_part_of_this_branch then
          object:destroy()
        end
      end
    end
    for _, child in ipairs(self.children) do -- removed named links to children
      array.delete(child.parents, self) -- delete link to self on children
      if self[child.name] == child then
        self[child.name] = nil
      end
    end
    self.children = {} -- remove link to all children
    for _, parent in ipairs(self.parents) do
      array.delete(parent.children, self) -- delete link to self on parents
      if parent[self.name] == self then -- removed named links from parents
        parent[self.name] = nil
      end
    end
    self.parents = {} -- remove link to all parents
    if not dont_destroy_self then self:destroy() end
  end
end

--[[
  Renames this object.
  This changes its name attribute, and also changes references to and from it across all children and parents to reflect the name change.
--]]
function object:rename(new_name)
  local old_name = self.name
  self.name = new_name
  for _, child in ipairs(self.children) do -- rename on all children
    if child[old_name] == self then
      child[old_name] = nil
      child[new_name] = self
    end
  end
  for _, parent in ipairs(self.parents) do -- rename on all parents
    if parent[old_name] == self then
      parent[old_name] = nil
      parent[new_name] = self
    end
  end
end

--[[
  Removes all objects under this one.
  Internally this calls remove_dead_branch and performs the same operation that it does, but without killing or destroying self.
--]]
function object:kill_all_children()
  self.dead = true
  self:remove_dead_branch(true)
  self.dead = false
  self.destroyed = false
end

--[[
  Adds an object to the end of this object's list of children.
  This is the main way in which objects get updated, and for things to work you need to initially add objects to the tree's root node (an).
  Here are all the things that happen in this function:
    Self's .children table is added the child object.
    The added object's .parents table is added self.
    If the child object has a .name attribute and that name isn't in use by self's table, then that name on self will now point to the child object.
    If the parent object (self) has a .name attribute and that name isn't in use by the child's table, then that name on the child will now point to the parent object.
    If the name is already in use in either case, a warning message will be printed to the console and nothing will change when it comes to name references.
  Example:
    player = object('player_1')
    an:add(player) -> now an.children[1] and an.player_1 point to the player object, and player.parents[1] and player.an point to an
--]]
function object:add(...)
  for _, child in ipairs({...}) do
    table.insert(self.children, child)
    table.insert(child.parents, self)
    if child.name then
      if not self[child.name] then self[child.name] = child
      else print(child.name .. ' is already indexed by self - ' .. self:get_who_called_me()) end
    end
    if self.name then
      if not child[self.name] then child[self.name] = self
      else print(self.name .. ' is already indexed by child - ' .. self:get_who_called_me()) end
    end
  end
  return self
end


--[[
  Returns true if this object has the given name, or if it is of the given type.
  Examples:
    object'player':is'player'        -> true
    object'player':is'enemy'         -> false
    object():collider():is'collider' -> true, modules always set self.tags.module_name to true on initialization
--]]
function object:is(name_or_type)
  return self.name == name_or_type or self.tags[name_or_type]
end

--[[
  Tags this object with the given tags and returns self.
  This means self:is(tag) will return true for the passed in tags.
  This is useful when you need to identify or search for objects by some non-unique identifier that makes sense for your gameplay.
  Example:
    self:tag('projectile', 'enemy_projectile' -> now self.tags.projectile and self.tags.enemy_projectile are both true
--]]
function object:tag(...)
  for _, tag in ipairs({...}) do
    self.tags[tag] = true
  end
  return self
end

--[[
  Sets self.flashing to true for the given duration.
  This could be a function that changes any variable for a duration, but given how often flashing happens it was created for this purpose alone.
  Example:
    an:flash()     -> sets self.flashing to true for 0.1 seconds
    an:flash(0.15) -> sets self.flashing to true for 0.15 seconds
  To flash an object, as in make it flash white, you'd need to do this:
    game:draw(an.images.image, self.x, self.y, 0, 1, 1, 0, 0, an.colors.white[0], self.flashing and an.shaders.combine) -- TODO: revise this, will be different with cf most likely
  Which uses the "combine" shader with a white color to make the object turn white and thus flash as long as self.flashing is true.
]]--
function object:flash(duration)
  if not self.tags.timer then error('object must be initialized as a timer for the flash function to work') end
  self.flashing = true
  self:timer_after(duration or 0.15, function() self.flashing = false end, 'flashing')
end

--[[
  Returns the amount of time left for the current flash set by object:flash.
  Example:
    an:flash(0.15)           -> sets self.flashing to true for 0.1 seconds
    an:get_flash_time_left() -> if called after 0.05 seconds from when an:flash was called, this will return 0.1
--]]
function object:get_flash_time_left()
  return self:timer_get_time_left('flashing')
end

--[[
  Slows the object by changing self.slow_amount to some value below 1 and then tweening it up to 1 again.
  The delta value passed to an object's function automatically gets multiplied by this value.
  Importantly, the object must be initialized as a timer otherwise the function will not work.
  Calling "an:slow" will slow all of an's children, and thus all objects in the game.
  Examples:
    an:slow(0, 0)                -> stops the simulation for 1 frame, since on the next it ends and sets self.slow_amount to 1
    an:slow(1, 1)                -> does nothing
    an:slow(0.5, 0.5)            -> slows down to 0.5 for 0.5s using the math.cubic_in_out easing method
    an:slow(0.2, 1, math.linear) -> slows down to 0.2 for 1s using the math.linear easing method
]]--
function object:slow(slow_amount, duration, tween_method)
  if not self.tags.timer then error('object must be initialized as a timer for the slow function to work') end
  local slow_amount = slow_amount or 0.5
  self.slow_amount = slow_amount
  self:timer_tween(duration or 0.5, self, {slow_amount = 1}, tween_method or math.cubic_in_out, function() self.slow_amount = 1 end, 'slow')
end

--[[
  Returns a unique id.
  This just increments object's .id attribute and returns that value.
]]--
function object:uid()
  object.id = object.id + 1
  return object.id
end

--[[
  Returns a string that reports which function called the current function we're in.
  This uses debug.getinfo to get that information, so it works exactly as that does, it just formats the information out nicely.
--]]
function object:get_who_called_me()
  local info = debug.getinfo(3, 'Sl')
  return info.short_src .. '@' .. info.currentline
end
