-- Base code and idea was taken from https://github.com/argonautcode/animal-proc-anim
local Vec2 = require 'vec2'

local M = {}

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

function M:new(origin, joint_count, link_size, angle_constraint, speed, scale)
  origin = origin or Vec2:new(0, 0)
  joint_count = joint_count or 2
  scale = scale or 1
  link_size = scale * (link_size or 100)
  angle_constraint = angle_constraint or (2 * math.pi)
  speed = speed or 200

  return setmetatable(
    {
      scale = scale,
      joints = initJoints(origin, link_size, joint_count), -- list of joint positions as Vec2. #joints > 1
      angles = initAngles(joint_count),
      link_size = link_size,                               -- distance between joints
      angle_constraint = angle_constraint,                 -- Max angle diff between two adjacent joints. higher = loose, lower = rigid
      speed = speed
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
    return nil
  end

  return M[key]
end

function M:__tostring()
  local chain_str = '['
  for i, joint in ipairs(self.joints) do
    chain_str = chain_str .. tostring(joint) .. '/' .. tostring(self.angles[i])
    if i < #self.joints then
      chain_str = chain_str .. ', '
    end
  end
  return chain_str .. ']'
end

function M:draw()
  for i = 1, #self.joints - 1, 1 do
    local start_joint = self.joints[i]
    local end_joint = self.joints[i + 1]
    love.graphics.line(start_joint.x, start_joint.y, end_joint.x, end_joint.y)
  end
  for index, joint in ipairs(self.joints) do
    if index == 1 then
      love.graphics.setColor(1, 0, 0)
    else
      love.graphics.setColor(1, 1, 1)
    end
    love.graphics.ellipse("fill", joint.x, joint.y, 4, 4)
  end
end

local function simplifyAngle(angle)
  -- Simplify angle to be in the range [0, 2pi]
  local two_pi = 2 * math.pi
  return angle - math.floor(angle / two_pi) * two_pi
end
M.simplifyAngle = simplifyAngle

local function relativeAngleDiff(angle, anchor)
  -- i.e. How many radians do you need to turn the angle to match the anchor?

  -- Since angles are represented by values in [0, 2pi), it's helpful to rotate
  -- the coordinate space such that PI is at the anchor. That way we don't have
  -- to worry about the "seam" between 0 and 2pi.
  return math.pi - simplifyAngle(angle + math.pi - anchor)
end
M.relativeAngleDiff = relativeAngleDiff

local function constrainAngle(angle, anchor, constraint)
  -- Constrain the angle to be within a certain range of the anchor
  local relative_diff = relativeAngleDiff(angle, anchor)
  if math.abs(relative_diff) <= constraint then
    return simplifyAngle(angle)
  end
  if relative_diff > constraint then
    return simplifyAngle(anchor - constraint)
  end
  return simplifyAngle(anchor + constraint)
end
M.constrainAngle = constrainAngle

local function constrainDistance(pos, anchor, constraint)
  -- Constrain the vector to be at a certain range of the anchor
  return anchor + (pos - anchor):setMagnitude(constraint)
end
M.constrainDistance = constrainDistance

local function deltaTarget(target, origin, mag)
  return (target - origin):setMagnitude(mag) + origin
end
M.deltaTarget = deltaTarget

function M:resolve(pos, dt, is_scaling)
  is_scaling = is_scaling or false
  -- TODO smooth movement if rotation angle is to big
  if
      self.joints[1]:distance(pos) < 1
      or is_scaling and self.joints[1]:distance(pos) > 0
  then
    return
  end

  local target = deltaTarget(pos, self.joints[1], self.speed * dt)
  self.angles[1] = (target - self.joints[1]):angle()
  self.joints[1] = target

  for i = 2, #self.joints, 1 do
    local curr_angle = (self.joints[i - 1] - self.joints[i]):angle()
    self.angles[i] = constrainAngle(curr_angle, self.angles[i - 1], self.angle_constraint)
    self.joints[i] = self.joints[i - 1] - Vec2:fromAngle(self.angles[i]):setMagnitude(self.link_size)
  end
end

function M:setScale(scale)
  if self.scale == scale then
    return
  end
  self.link_size = scale * self.link_size / self.scale
  self.scale = scale
  for i = 2, #self.joints, 1 do
    self.joints[i] = self.joints[i - 1] - Vec2:fromAngle(self.angles[i]):setMagnitude(self.link_size)
  end
end

function M:fabrikResolve(pos, anchor)
  -- Forward pass
  self.joints[1] = pos
  for i = 2, #self.joints, 1 do
    self.joints[i] = constrainDistance(self.joints[i], self.joints[i - 1], self.link_size)
  end
  -- Backward pass
  self.joints[#self.joints] = anchor
  for i = #self.joints - 1, 1, -1 do
    self.joints[i] = constrainDistance(self.joints[i], self.joints[i + 1], self.link_size)
  end
end

return M
