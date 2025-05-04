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

function M:new(pos, link_size, angle_constraint)
  return setmetatable(
    {
      __type = 'Joint',
      pos = pos or Vec2:new(),
      link_size = link_size or 0,
      angle_constraint = angle_constraint
    },
    self
  )
end

function M:__index(key)
  if key == nil then
    return M
  end

  local pos_val = self.pos[key]
  if pos_val ~= nil then
    return pos_val
  end

  if type(key) ~= 'string' then
    return
  end

  if key == 'p' then
    return self.pos
  elseif key == 'link' then
    return self.link_size
  elseif key == 'size' then
    return self.link_size
  elseif key == 'angle' then
    return self.angle_constraint
  end

  return M[key]
end

function M:__tostring()
  local joint_str = '{' .. tostring(self.pos)
  if self.angle_constraint then
    joint_str = joint_str .. '/' .. string.format('%.4f', self.angle_constraint)
  end
  joint_str = joint_str .. ', ' .. self.link_size .. '}'
  return joint_str
end

function M:update(_dt)
end

function M:draw()
end

return M
