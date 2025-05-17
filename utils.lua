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
      __type = 'Utils',
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
  return 'Utils module'
end

function M.withDefaults(t, defaults)
  for k, v in pairs(defaults) do
    if t[k] == nil then
      t[k] = v
    end
  end

  return t
end

function M.mapValue(val, start_1, end_1, start_2, end_2)
  return (val - start_1) * (end_2 - start_2) / (end_1 - start_1) + start_2
end

return M
