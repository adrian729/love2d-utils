-- requires

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

function M:new()
  return setmetatable(
    {
      __type = 'Template',
    },
    self
  )
end

function M:__index(key)
  if key == nil then
    return M
  end

  if type(key) ~= 'string' then
    return
  end

  return M[key]
end

function M:__tostring()
  return 'template module'
end

function M:update(dt)
  print('LOVE update' .. tostring(dt))
end

function M:draw()
  print('LOVE draw')
end

return M
