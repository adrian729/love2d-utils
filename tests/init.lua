local M = {}

local original_type = type
type = function(obj)
  local otype = original_type(obj)
  if otype == "table" and getmetatable(obj) == M and M.__type then
    return M.__type
  end
  return otype
end

function M:new(module_name)
  if module_name == nil then
    print('Loading default')
  end
  module_name = module_name or 'test-fish'

  print('Loading module ' .. module_name)
  local test = require('tests/' .. module_name)
  test:load()

  return setmetatable(
    {
      __type = 'Tests',
      module_name = module_name,
      test = test
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
  return 'Test: ' .. self.module_name
end

function M:update(dt)
  self.test:update(dt)
end

function M:draw()
  self.test:draw()
end

return M
