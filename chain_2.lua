local Joint = require 'joint'

-- TODO: add angle constraints
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

local function initJoints(joints)
  if joints then
    return joints
  end

  return {
    Joint:new(nil, 10),
    Joint:new(nil, 10)
  }
end

function M:new(joints, root, target)
  return setmetatable(
    {
      __type = 'Chain',
      joints = initJoints(joints),
      root = root,
      target = target
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
  local chain_str = '[ '

  for i, joint in ipairs(self.joints) do
    chain_str = chain_str .. tostring(joint) -- .. '/' .. tostring(self.angles[i])
    if i < #self.joints then
      chain_str = chain_str .. ', '
    end
  end

  chain_str = chain_str .. ' ]'
  if self.root then
    chain_str = chain_str .. ' - ' .. tostring(self.root)
  end

  return chain_str
end

local function fabrikForward(self)
  if not self.target then
    return
  end

  self.joints[1].pos = self.target
  for i, curr in ipairs(self.joints) do
    if i < #self.joints then
      local next = self.joints[i + 1]
      next.pos = curr.pos - (curr.pos - next.pos):setMag(curr.link_size)
    end
  end
end

local function fabrikBackward(self)
  if not self.root then
    return
  end

  self.joints[#self.joints].pos = self.root
  for i = #self.joints - 1, 1, -1 do
    local curr = self.joints[i]
    local prev = self.joints[i + 1]
    curr.pos = prev.pos + (curr.pos - prev.pos):setMag(curr.link_size)
  end
end

function M:update(dt)
  fabrikForward(self)
  fabrikBackward(self)
end

function M:draw()
  local r = 3
  love.graphics.setColor(1, 0, 0)
  if self.root then
    love.graphics.circle('line', self.root.x, self.root.y, r)
  end

  for i, joint in ipairs(self.joints) do
    if i < #self.joints then
      local prev = self.joints[i + 1]
      love.graphics.setColor(1, 1, 1)
      love.graphics.line(joint.x, joint.y, prev.x, prev.y)
    end
    love.graphics.setColor(0, 1, 0)
    love.graphics.circle('line', joint.x, joint.y, r)
  end
end

return M
