--[[
  Returns the substring to the left of the first instance matching the pattern passed in.
  Note that the pattern is a Lua pattern, which you can learn more about here: https://www.lua.org/pil/20.2.html.
  Examples:
    s = 'assets/images/player_32.png'
    s:left'/'  -> 'assets'
    s:left'_'  -> 'assets/images/player'
    s:left'%.' -> 'assets/images/player_32'
]]--
function string:left(p)
  local i = utf8.find(self, p)
  if i then
    local s = utf8.sub(self, 1, i-1)
    return s ~= '' and s
  end
end

--[[
  Returns the substring to the right of the first instance matching the pattern passed in.
  Note that the pattern is a Lua pattern, which you can learn more about here: https://www.lua.org/pil/20.2.html.
  Examples:
    s = 'assets/images/player_32.png'
    s:right'/'  -> 'images/player_32.png'
    s:right'_'  -> '32.png'
    s:right'%.' -> 'png'
]]--
function string:right(p)
  local _, j = utf8.find(self, p)
  if j then
    local s = utf8.sub(self, j+1)
    return s ~= '' and s
  end
end
