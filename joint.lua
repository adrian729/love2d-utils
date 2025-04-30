local Vec2 = require 'vec2'

local M = {}

-- type overwrite
local original_type = type
type = function(obj)
  local otype = original_type(obj)
  if otype == "table" and getmetatable(obj) == M and M.__type then
    return M.__type
  end
  return otype
end

function M:new(pos, link_size, angle)
  return setmetatable(
    {
      __type = 'Joint',
      pos = pos or Vec2:new(),
      link_size = link_size or 0,
      angle = angle
    },
    self
  )
end

function M:__index(key)
  if key == nil then
    return M
  end

  if type(key) == 'number' then
    return self.pos[key]
  end

  if type(key) ~= 'string' then
    return
  end

  if key == 'x' or key == 'y' then
    return self.pos[key]
  end

  return M[key]
end

function M:__tostring()
  local joint_str = '{' .. tostring(self.pos)
  if self.angle then
    joint_str = joint_str .. '/' .. tostring(self.angle)
  end
  joint_str = joint_str .. ', ' .. self.link_size .. '}'
  return joint_str
end

function M:update(dt)
end

function M:draw()
end

return M
