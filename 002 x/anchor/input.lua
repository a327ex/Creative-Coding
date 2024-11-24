--[[
  This class is responsible for handling input.
  It allows the binding of input from keyboard, mouse and gamepad to actions.
  Actions can then be used in gameplay code in an input device agnostic way.
  For instance:
    an:input_bind('jump', {'key:x', 'key:space', 'button:a'})
  Binds keyboard keys x and space, as well as gamepad's button a, to the 'jump' action.
  In an update function, you can then call:
    if an:is_pressed'jump'
  And this will be true frames when any of bound keys or buttons have been pressed.
]]--
input = class:class_new()
function input:input()
  self.tags.input = true
  love.joystick.loadGamepadMappings('anchor/assets/gamecontrollerdb.txt')
  self.input_actions = {}
  self.input_state = {}
  self.input_sequence_state = {}
  self.input_keyboard_state = {}
  self.input_previous_keyboard_state = {}
  self.input_mouse_state = {}
  self.input_previous_mouse_state = {}
  self.input_gamepad_state = {}
  self.input_previous_gamepad_state = {}
  self.input_last_type = nil
  self.input_gamepad = love.joystick.getJoysticks()[1]
  self.input_deadzone = 0.5
  return self
end

--[[
  Binds an action to a set of controls. This allows you to code all gameplay code using action names rather than keys/buttons.
  Repeated calls to this function given the same action will add new controls to it.
  To remove a single control, such as when the player rebinds a key, call "unbind".
  To reset all controls entirely call "unbind_all".
  Controls come in the form 'type:key'.
  "type" values can be:
    key
    mouse
    button
    axis
  "key" values can be: 
    any LÖVE KeyConstant (https://love2d.org/wiki/KeyConstant)     when type == key
    1, 2, 3, 4, 5, wheel_up or wheel_down                          when type == mouse
    any LÖVE GamepadButton (https://love2d.org/wiki/GamepadButton) when type == button
    any LÖVE GamepadAxis (https://love2d.org/wiki/GamepadAxis)     when type == axis
  For the axis type, keys leftx, lefty, rightx and righty should also have + or - appended, to signify whether that action
  applies to that stick moving left/right or up/down. For instance, "axis:leftx-" will trigger when the left stick moves left.

  Examples:
    an:input_bind('left', {'key:left', 'key:a', 'axis:leftx-', 'button:dpleft'})
    an:input_bind('right', {'key:right', 'key:d', 'axis:leftx+', 'button:dpright'})
    an:input_bind('up', {'key:up', 'key:w', 'axis:lefty-', 'button:dpup'})
    an:input_bind('down', {'key:down', 'key:s', 'axis:lefty+', 'button:dpdown'})
    an:input_bind('jump', {'key:x', 'key:space', 'button:a'})
]]--
function input:input_bind(action, controls)
  if not self.input_state[action] then self.input_state[action] = {} end
  if not self.input_state[action].controls then self.input_state[action].controls = {} end
  for _, control in ipairs(controls) do
    local action_type, key = control:left':', control:right':'
    local sign = nil
    if action_type == 'axis' then
      if key:find'%+' then key, sign = key:left'%+', 1 end
      if key:find'%-' then key, sign = key:left'%-', -1 end
    end
    table.insert(self.input_state[action].controls, {action_type, key, sign})
  end
  if not array.has(self.input_actions, action) then table.insert(self.input_actions, action) end
end

--[[
  Binds all keyboard and mouse keys to actions named the same as the key.
  This should be called for convenience so you can easily use input without having bind keys to any actions.
]]--
function input:input_bind_all()
  controls = {
    'key:a', 'key:b', 'key:c', 'key:d', 'key:e', 'key:f', 'key:g', 'key:h', 'key:i', 'key:j', 'key:k', 'key:l', 'key:m',
    'key:n', 'key:o', 'key:p', 'key:q', 'key:r', 'key:s', 'key:t', 'key:u', 'key:v', 'key:w', 'key:x', 'key:y', 'key:z',
    'key:0', 'key:1', 'key:2', 'key:3', 'key:4', 'key:5', 'key:6', 'key:7', 'key:8', 'key:9', 'key:space', 'key:()', 'key:"',
    'key:#', 'key:$', 'key:&', "key:'", 'key:(', 'key:)', 'key:*', 'key:+', 'key:,', 'key:-', 'key:.', 'key:/', 'key::',
    'key:;', 'key:<', 'key:=', 'key:>', 'key:?', 'key:self.', 'key:[', 'key:::', 'key:^', 'key:_', 'key:`', 'key:kp0', 'key:kp1',
    'key:kp2', 'key:kp3', 'key:kp4', 'key:kp5', 'key:kp6', 'key:kp7', 'key:kp8', 'key:kp9', 'key:kp.', 'key:kp,', 'key:kp/',
    'key:kp*', 'key:kp-', 'key:kp+', 'key:kpenter', 'key:kp=', 'key:up', 'key:down', 'key:right', 'key:left', 'key:home',
    'key:end', 'key:pageup', 'key:pagedown', 'key:insert', 'key:backspace', 'key:tab', 'key:clear', 'key:return',
    'key:delete', 'key:numlock', 'key:capslock', 'key:rshift', 'key:lshift', 'key:rctrl', 'key:lctrl', 'key:ralt', 'key:lalt',
    'key:rgui', 'key:lgui', 'key:mode', 'key:f1', 'key:f2', 'key:f3', 'key:f4', 'key:f5', 'key:f6', 'key:f7', 'key:f8', 'key:f9',
    'key:f10', 'key:f11', 'key:f12', 'mouse:1', 'mouse:2', 'mouse:3', 'mouse:4', 'mouse:5', 'mouse:wheel_up', 'mouse:wheel_down',
  }
  for _, control in ipairs(controls) do
    self:input_bind(control:right':', {control})
  end
end

--[[
  Returns true if the given action is being held down this frame.
  For actions of the type "axis", the value is returned if it's over the self.input_deadzone value.
  Examples: (in some update function)
    if an:is_down'left' then
      -- move left
    end

    local value = an:is_down'left'
    if value then
      -- move left using value, which here will be a value from self.input_deadzone to 1 representing how far the stick is bent
    end
]]--
function input:is_down(action)
  return self.input_state[action].down
end

--[[
  Returns true if the given action was pressed this frame.
  Example: (in some update function)
    if an:is_pressed'jump' then
      -- do jump things
    end
]]--
function input:is_pressed(action)
  return self.input_state[action].pressed
end

--[[
  Returns true if the given action was released this game.
  Example: (in some update function)
    if an:is_released'jump' then
      -- do stop jump things
    end
]]---
function input:is_released(action)
  return self.input_state[action].released
end

--[[
  Returns how much the mouse has moved this frame.
  Example:
    dx, dy = an:input_get_mouse_delta()
    if an:is_down'1' then
      an:camera_move(10*dx, 10*dy)
    end
]]--
function input:input_get_mouse_delta()
  return self.input_mouse_state.dx, self.input_mouse_state.dy
end

--[[
  Unbinds a single control from the given action.
  Examples:
    an:input_unbind('left', 'key:left')
    an:input_unbind('right', 'axis:leftx+')
    an:input_unbind('up', 'button:dpup')
    an:input_unbind('down', 'key:s')
]]--
function input:input_unbind(action, control)
  local index = array.index(self.input_state[action].controls, control)
  if index then
    array.remove(self.input_state[action].controls, index)
  end
end

--[[
  Unbinds all controls from the given action.
  Examples:
    an:input_unbind_all('jump')
]]---
function input:input_unbind_all(action)
  self.input_state[action] = nil
end

--[[
  Updates input state for this frame.
  Input is collected before everything else in a frame, and this function is also called before everything else.
  This makes it so that all other modules have correct and (generally) predictable input state available every frame.
]]--
function input:input_update()
  for _, action in ipairs(self.input_actions) do
    self.input_state[action].pressed = false
    self.input_state[action].down = false
    self.input_state[action].released = false
  end

  for _, action in ipairs(self.input_actions) do
    for _, control in ipairs(self.input_state[action].controls) do
      local action_type, key, sign = control[1], control[2], control[3]
      local a = self.input_state[action]
      if action_type == 'key' then
        a.pressed = a.pressed or (self.input_keyboard_state[key] and not self.input_previous_keyboard_state[key])
        a.down = a.down or self.input_keyboard_state[key]
        a.released = a.released or (not self.input_keyboard_state[key] and self.input_previous_keyboard_state[key])
      elseif action_type == 'mouse' then
        if key == 'wheel_up' or key == 'wheel_down' then
          a.pressed = self.input_mouse_state[key]
        else
          a.pressed = a.pressed or (self.input_mouse_state[tonumber(key)] and not self.input_previous_mouse_state[tonumber(key)])
          a.down = a.down or self.input_mouse_state[tonumber(key)]
          a.released = a.released or (not self.input_mouse_state[tonumber(key)] and self.input_previous_mouse_state[tonumber(key)])
        end
      elseif action_type == 'axis' then
        if self.input_gamepad then
          local value = self.input_gamepad:getGamepadAxis(key)
          if value ~= 0 then self.input_latest_type = 'gamepad' end
          local down = false
          if sign == 1 then
            if value >= self.input_deadzone then self.input_gamepad_state[key] = value
            else self.input_gamepad_state[key] = false end
          elseif sign == -1 then
            if value <= self.input_deadzone then self.input_gamepad_state[key] = value
            else self.input_gamepad_state[key] = false end
          end
          a.pressed = a.pressed or (self.input_gamepad_state[key] and not self.input_previous_gamepad_state[key])
          a.down = a.down or self.input_gamepad_state[key]
          a.released = a.released or (not self.input_gamepad_state[key] and self.input_previous_gamepad_state[key])
        end
      elseif action_type == 'button' then
        if self.input_gamepad then
          a.pressed = a.pressed or (self.input_gamepad_state[key] and not self.input_previous_gamepad_state[key])
          a.down = a.down or self.input_gamepad_state[key]
          a.released = a.released or (not self.input_gamepad_state[key] and self.input_previous_gamepad_state[key])
        end
      end
    end
  end
end

function input:input_post_update()
  self.input_previous_keyboard_state = table.copy(self.input_keyboard_state)
  self.input_previous_mouse_state = table.copy(self.input_mouse_state)
  self.input_previous_gamepad_state = table.copy(self.input_gamepad_state)
  self.input_mouse_state.wheel_up = false
  self.input_mouse_state.wheel_down = false
  self.input_mouse_state.dx = 0
  self.input_mouse_state.dy = 0
end
