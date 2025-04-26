local Lizard = {}
Lizard.__index = Lizard

local Vec2 = require 'vec2'
local Chain = require 'chain'
local Splines = require 'splines'

local body_color = { 58 / 255, 124 / 255, 165 / 255 }
local body_width = { 52, 58, 40, 60, 68, 71, 65, 50, 28, 15, 11, 9, 7, 7 };

local function getSidePoints(m, main_pos, secondary_pos)
  local dx = secondary_pos.x - main_pos.x
  local dy = secondary_pos.y - main_pos.y
  return Vec2:new(-dy, dx):setMagnitude(m) + main_pos, Vec2:new(dy, -dx):setMagnitude(m) + main_pos
end

local function scaleBodyWidth(scale)
  local scaled_body_width = {}
  for i, w in ipairs(body_width) do
    scaled_body_width[i] = scale * w
  end
  return scaled_body_width
end

function Lizard:new(origin, scale, speed)
  scale = scale or 1
  speed = speed or 200
  return setmetatable(
    {
      scale = scale,
      spine = Chain:new(origin, 14, 64, math.pi / 8, speed, scale),
      arms = { -- TODO: put from the start in the proper position
        Chain:new(origin, 3, 52, nil, nil, scale),
        Chain:new(origin, 3, 52, nil, nil, scale),
        Chain:new(origin, 3, 36, nil, nil, scale),
        Chain:new(origin, 3, 36, nil, nil, scale),
      },

      arm_desired = {
        Vec2:new(0, 0),
        Vec2:new(0, 0),
        Vec2:new(0, 0),
        Vec2:new(0, 0),
      },
      body_width = scaleBodyWidth(scale),
    },
    self
  )
end

function Lizard:distance(point)
  return self.spine.joints[1]:distance(point)
end

function Lizard:setScale(scale)
  if self.scale == scale then
    return
  end
  self.spine:setScale(scale)
  self.body_width = scaleBodyWidth(scale)
  self.scale = scale
end

local function unused()
  for i, arm in ipairs(self.arms) do
    local side = 1
    if i % 2 == 0 then
      side = -1
    end
    local body_index = 8
    local angle = math.pi / 3
    if i < 3 then
      body_index = 4
      angle = math.pi / 4
    end
    local desired_pos, side_2 = getSidePoints(
      self.body_width[body_index],
      joints[body_index],
      self.scale * 80 + joints[body_index - 1]
    )
    if desired_pos:distance(self.arm_desired[i]) > self.scale * 200 then
      self.arm_desired[i] = desired_pos
    end
    local anchor_1, anchor_2 = getSidePoints(
      self.body_width[body_index],
      joints[body_index],
      joints[body_index - 1]
    )
    --arm:fabrikResolve(
    -- arm.joints[1]:lerp(self.arm_desired[i], 0.4),
    --anchor_2
    --)
  end
end

local function resolveArms(self)
  local joints = self.spine.joints
  local arms = self.arms

  local idx_l = 1
  local idx_r = 2
  local body_idx = 4

  local desired_pos_1, desired_pos_2 = getSidePoints(
    self.scale * 80 + self.body_width[body_idx],
    joints[body_idx],
    joints[body_idx - 1]
  )
  if desired_pos_1:distance(self.arm_desired[idx_l]) > self.scale * 200 then
    self.arm_desired[idx_l] = desired_pos_1
  end
  if desired_pos_2:distance(self.arm_desired[idx_r]) > self.scale * 200 then
    self.arm_desired[idx_r] = desired_pos_2
  end
  local anchor_1, anchor_2 = getSidePoints(
    self.scale * -20 + self.body_width[body_idx],
    joints[body_idx],
    joints[body_idx - 1]
  )
  arms[idx_l]:fabrikResolve(
    arms[idx_l].joints[1]:lerp(self.arm_desired[idx_l], 0.4),
    anchor_1
  )
  arms[idx_r]:fabrikResolve(
    arms[idx_r].joints[1]:lerp(self.arm_desired[idx_r], 0.4),
    anchor_2
  )

  idx_l = 3
  idx_r = 4
  body_idx = 8

  desired_pos_1, desired_pos_2 = getSidePoints(
    self.scale * 80 + self.body_width[body_idx],
    joints[body_idx],
    joints[body_idx - 1]
  )
  if desired_pos_1:distance(self.arm_desired[idx_l]) > self.scale * 200 then
    self.arm_desired[idx_l] = desired_pos_1
  end
  if desired_pos_2:distance(self.arm_desired[idx_r]) > self.scale * 200 then
    self.arm_desired[idx_r] = desired_pos_2
  end
  anchor_1, anchor_2 = getSidePoints(
    self.scale * -20 + self.body_width[body_idx],
    joints[body_idx],
    joints[body_idx - 1]
  )
  arms[idx_l]:fabrikResolve(
    arms[idx_l].joints[1]:lerp(self.arm_desired[idx_l], 0.4),
    anchor_1
  )
  arms[idx_r]:fabrikResolve(
    arms[idx_r].joints[1]:lerp(self.arm_desired[idx_r], 0.4),
    anchor_2
  )
end

function Lizard:resolve(target_pos, dt)
  self.spine:resolve(target_pos, dt)
  resolveArms(self)
end

local function cleanupPoints(points)
  local new_points = {}
  table.insert(new_points, points[1])
  for _, point in ipairs(points) do
    if point:distance(new_points[#new_points]) > 0.5 then
      table.insert(new_points, point)
    end
  end
  return new_points
end

local function createCurve(points)
  local curve = {}
  for _, point in ipairs(points) do
    table.insert(curve, point.x)
    table.insert(curve, point.y)
  end
  return curve
end

local function paintPolygon(points, bg_color, color)
  local color = color or bg_color

  love.graphics.setColor(bg_color[1], bg_color[2], bg_color[3])
  local curve = createCurve(cleanupPoints(points))
  local triangles = love.math.triangulate(curve)
  for _, triangle in ipairs(triangles) do
    love.graphics.polygon('fill', triangle)
  end

  love.graphics.setColor(color[1], color[2], color[3])
  love.graphics.line(curve)
end

local function drawBody(self)
  local joints = self.spine.joints
  local left = {}
  local right = {}

  local front = (joints[1] - joints[2])
  front = front:setMagnitude(self.body_width[1] + self.spine.link_size) + joints[2]
  table.insert(left, front)
  table.insert(right, front)
  local front_left = Vec2:fromAngle(self.spine.angles[2] - math.pi / 8)
  front_left = front_left:setMagnitude(self.body_width[1])
  front_left = front_left + joints[1]
  table.insert(left, front_left)
  local front_left_2 = Vec2:fromAngle(self.spine.angles[2] - math.pi / 4)
  front_left_2 = front_left_2:setMagnitude(self.body_width[1])
  front_left_2 = front_left_2 + joints[1]
  table.insert(left, front_left_2)
  local front_right = Vec2:fromAngle(self.spine.angles[2] + math.pi / 8)
  front_right = front_right:setMagnitude(self.body_width[1])
  front_right = front_right + joints[1]
  table.insert(right, front_right)
  local front_right_2 = Vec2:fromAngle(self.spine.angles[2] + math.pi / 4)
  front_right_2 = front_right_2:setMagnitude(self.body_width[1])
  front_right_2 = front_right_2 + joints[1]
  table.insert(right, front_right_2)

  for i = 1, #joints - 2, 1 do
    local side_1, side_2 = getSidePoints(self.body_width[i], joints[i], joints[i + 1])
    table.insert(left, side_1)
    table.insert(right, side_2)
  end

  local shape = {}
  for _, v in ipairs(left) do
    table.insert(shape, v)
  end
  for i = #right, 1, -1 do
    table.insert(shape, right[i])
  end

  local points = Splines:new(shape):render({ detail = 500, type = 'v2' })
  paintPolygon(points, body_color, { 1, 1, 1 })
end

function Lizard:draw()
  drawBody(self)
  for _, arm in ipairs(self.arms) do
    arm:draw()
  end
end

return Lizard
