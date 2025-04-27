local Fish = {}
Fish.__index = Fish

local Vec2 = require 'vec2'
local Chain = require 'chain'
local Splines = require 'splines'

local body_color = { 58 / 255, 124 / 255, 165 / 255 }
local fin_color = { 129 / 255, 195 / 255, 215 / 255 }
local body_width = { 68, 81, 84, 83, 77, 64, 51, 38, 32, 19, 19, 19 }

local function scaleBodyWidth(scale)
  local scaled_body_width = {}
  for i, w in ipairs(body_width) do
    scaled_body_width[i] = scale * w
  end
  return scaled_body_width
end

function Fish:new(origin, scale, speed)
  scale = scale or 1
  speed = speed or 200
  return setmetatable(
    {
      scale = scale,
      spine = Chain:new(origin, 12, 64, math.pi / 8, speed, scale),
      body_width = scaleBodyWidth(scale),
    },
    self
  )
end

function Fish:distance(point)
  return self.spine.joints[1]:distance(point)
end

function Fish:setScale(scale)
  if self.scale == scale then
    return
  end
  self.spine:setScale(scale)
  self.body_width = scaleBodyWidth(scale)
  self.scale = scale
end

function Fish:resolve(target_pos, dt)
  self.spine:resolve(target_pos, dt)
end

local function getSidePoints(m, main_pos, secondary_pos)
  local dx = secondary_pos.x - main_pos.x
  local dy = secondary_pos.y - main_pos.y
  return Vec2:new(-dy, dx):setMagnitude(m) + main_pos, Vec2:new(dy, -dx):setMagnitude(m) + main_pos
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

local function drawDorsalFin(self)
  local joints = self.spine.joints
  local left = {}
  local right = {}
  local start_idx = 3
  local end_idx = 7

  table.insert(left, joints[start_idx])
  table.insert(right, joints[start_idx])
  local side_r, side_l = joints[start_idx]:perpendicular(
    joints[start_idx + 1],
    0.02 * self.body_width[start_idx]
  )
  table.insert(left, side_l)
  table.insert(right, side_r)

  for i = start_idx + 1, end_idx - 1, 1 do
    side_r, side_l = joints[i]:perpendicular(
      joints[i + 1],
      0.1 * self.body_width[i]
    )
    table.insert(left, side_l)
    table.insert(right, side_r)
  end

  side_r, side_l = joints[end_idx]:perpendicular(
    joints[end_idx + 1],
    0.03 * self.body_width[end_idx]
  )
  table.insert(left, side_l)
  table.insert(right, side_r)
  table.insert(left, joints[end_idx])
  table.insert(right, joints[end_idx])

  local shape = {}
  for _, p in ipairs(left) do
    table.insert(shape, p)
  end
  for i = #right, 1, -1 do
    table.insert(shape, right[i])
  end

  local points = Splines:new(shape):render({ detail = 200, type = 'v2' })
  paintPolygon(points, fin_color, { 1, 1, 1, })
end

local function drawEyes(self)
  local joints = self.spine.joints

  local eye_size = 24 * self.scale
  local eye_left, eye_right = getSidePoints(self.body_width[1] - 0.6 * eye_size, joints[1], joints[2])
  love.graphics.setColor(0.7, 0.7, 0.7)
  love.graphics.circle("fill", eye_left.x, eye_left.y, eye_size)
  love.graphics.circle("fill", eye_right.x, eye_right.y, eye_size)
  local pupil_size = 18 * self.scale
  local pupil_left, pupil_right = getSidePoints(self.body_width[1] - 0.4 * eye_size, joints[1], joints[2])
  love.graphics.setColor(0.05, 0.05, 0.05)
  love.graphics.circle("fill", pupil_left.x, pupil_left.y, pupil_size)
  love.graphics.circle("fill", pupil_right.x, pupil_right.y, pupil_size)
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

local function drawLateralFin(self, side, sign)
  sign = sign or 1
  local r_x = self.scale * 75
  local r_y = r_x / 2
  love.graphics.translate(side.x, side.y)
  love.graphics.rotate(self.spine.angles[3] + sign * math.pi / 3)
  love.graphics.setColor(fin_color[1], fin_color[2], fin_color[3])
  love.graphics.ellipse("fill", 0, 0, r_x, r_y)
  love.graphics.setColor(1, 1, 1)
  love.graphics.ellipse("line", 0, 0, r_x, r_y)
  love.graphics.rotate(-self.spine.angles[3] - sign * math.pi / 3)
  love.graphics.translate(-side.x, -side.y)
end

local function drawLateralFins(self)
  local joints = self.spine.joints
  local side_1, side_2 = getSidePoints(self.body_width[3], joints[3], joints[4])
  drawLateralFin(self, side_1)
  drawLateralFin(self, side_2, -1)
end

local function drawTail(self)
  local joints = self.spine.joints
  local left = {}
  local right = {}

  local side_1, side_2 = getSidePoints(0.8 * self.body_width[#joints - 2], joints[#joints - 2], joints[#joints - 1])
  table.insert(left, side_1)
  table.insert(right, side_2)

  local tail_2, tail_1 = getSidePoints(1.4 * self.body_width[#joints], joints[#joints], joints[#joints - 1])
  table.insert(left, tail_1)
  table.insert(right, tail_2)

  local tail_end = (joints[#joints] - joints[#joints - 1])
  tail_end = tail_end:setMagnitude(self.body_width[#joints] + self.spine.link_size)
  tail_end = tail_end + joints[#joints - 1]
  table.insert(left, tail_end)

  local shape = {}
  for _, v in ipairs(left) do
    table.insert(shape, v)
  end
  for i = #right, 1, -1 do
    table.insert(shape, right[i])
  end

  local points = Splines:new(shape):render({ detail = 100, type = 'v2' })
  paintPolygon(points, fin_color, { 1, 1, 1, })
end

function Fish:draw()
  drawLateralFins(self)
  drawTail(self)
  drawBody(self)
  drawDorsalFin(self)
  drawEyes(self)
end

return Fish
