-- Base code and idea was taken from https://github.com/argonautcode/animal-proc-anim
local Vec2 = require 'vec2'

local Chain = {}

local function initJoints(origin, link_size, joint_count)
  local joints = { origin }
  for i = 2, joint_count, 1 do
    table.insert(joints, joints[i - 1] + Vec2:new(0, link_size))
  end
  return joints
end

local function initAngles(joint_count)
  local angles = {}
  for _ = 1, joint_count, 1 do
    table.insert(angles, 0.0)
  end
  return angles
end

function Chain:new(origin, joint_count, link_size, angle_constraint, speed)
  origin = origin or Vec2:new(0, 0)
  joint_count = joint_count or 2
  link_size = link_size or 100
  angle_constraint = angle_constraint or (2 * math.pi)
  return setmetatable(
    {
      joints = initJoints(origin, link_size, joint_count),
      angles = initAngles(joint_count),
      link_size,
      angle_constraint,
      speed
    },
    self
  )
end

function Chain:__index(key)
  if key == nil then
    return Chain
  end

  if type(key) == 'number' then
    return self.joints[key]
  end

  if type(key) ~= 'string' then
    return
  end

  return Chain[key]
end

function Chain:__tostring()
  local chain_str = '['
  for i = 1, #self.joints, 1 do
    chain_str = chain_str .. tostring(self.joints[i]) .. '/' .. tostring(self.angles[i])
    if i < #self.joints then
      chain_str = chain_str .. ', '
    end
  end
  return chain_str .. ']'
end

function Chain:draw()
  for i = 1, #self.joints - 1, 1 do
    local start_joint = self.joints[i]
    local end_joint = self.joints[i + 1]
    love.graphics.line(start_joint.x, start_joint.y, end_joint.x, end_joint.y)
  end

  for _, joint in ipairs(self.joints) do
    love.graphics.ellipse("fill", joint.x, joint.y, 4, 4)
  end
end

return Chain
