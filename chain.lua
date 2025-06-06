local Joint = require 'joint'
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

local function initUniformJoints(opts)
  opts = opts or {}

  local link_size = opts.link_size or 10
  local angle_constraint = opts.angle_constraint
  if angle_constraint then
    angle_constraint = Vec2.simplifyAngle(angle_constraint)
  end

  local joints = {}
  for _ = 1, opts.joint_count or 3, 1 do
    table.insert(
      joints,
      Joint:new({
        link_size = link_size,
        angle_constraint = angle_constraint
      })
    )
  end

  return joints
end

function M:new(opts)
  opts = opts or {}

  local joints = opts.joints or initUniformJoints(opts)

  return setmetatable(
    {
      __type = 'Chain',
      joints = joints,
      anchor = opts.anchor,
      target = opts.target
    },
    self
  )
end

function M:__index(key)
  if key == nil then
    return M
  end

  if type(key) == 'number' then
    return self.joints[key]
  end

  if type(key) ~= 'string' then
    return
  end

  return M[key]
end

function M:__tostring()
  local chain_str = '[ '

  for i, joint in ipairs(self.joints) do
    chain_str = chain_str .. tostring(joint)
    if i < #self.joints then
      chain_str = chain_str .. ', '
    end
  end

  chain_str = chain_str .. ' ]'
  if self.anchor then
    chain_str = chain_str .. ' - ' .. tostring(self.anchor)
  end

  return chain_str
end

function M:setScale(scale)
  scale = scale or 1
  for _, joint in ipairs(self.joints) do
    joint.link_size = scale * joint.link_size
  end
end

local function fabrikForward(self)
  if not self.target or self.joints[1].pos:distance(self.target) < 2 then
    return
  end

  self.joints[1].pos = self.target
  for i, curr in ipairs(self.joints) do
    if i < #self.joints then
      local next = self.joints[i + 1]
      if curr.angle_constraint and i > 1 then
        local prev = self.joints[i - 1]
        local prev_angle = (prev.pos - curr.pos):angle()
        local next_angle = (curr.pos - next.pos):angle()
        next.pos = curr.pos - Vec2:fromAngle(
          Vec2.constrainAngle(next_angle, prev_angle, curr.angle_constraint)
        )
      end
      next.pos = curr.pos:constrainDistance(next.pos, curr.link_size)
    end
  end
end

local function fabrikBackward(self)
  if not self.anchor
      or self.joints[#self.joints].pos:distance(self.anchor) < 2
  then
    return
  end

  self.joints[#self.joints].pos = self.anchor
  for i = #self.joints - 1, 1, -1 do
    local curr = self.joints[i]
    local next = self.joints[i + 1]
    curr.pos = next.pos:constrainDistance(curr.pos, curr.link_size)
  end
end

function M:update(_dt)
  fabrikForward(self)
  fabrikBackward(self)
end

function M:draw()
  local r = 3
  love.graphics.setColor(1, 0, 0)
  if self.anchor then
    love.graphics.circle('line', self.anchor.x, self.anchor.y, r)
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
