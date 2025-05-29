local M = {}
M.__index = M

-- type overwrite
local original_type = type
type = function(obj)
  local otype = original_type(obj)
  if otype == "table" and getmetatable(obj) == M and M.__type then
    return M.__type
  end
  return otype
end

-- We swapped old chain with new chain module, which introduces breaking changes. We need to fix this things

local Vec2 = require 'vec2'
local Chain = require 'chain'
local Splines = require 'splines'

local body_width = { 68, 81, 84, 83, 77, 64, 51, 38, 32, 19, 19, 19 }

local function scaleBodyWidth(scale)
  local scaled_body_width = {}
  for i, w in ipairs(body_width) do
    scaled_body_width[i] = scale * w
  end
  return scaled_body_width
end

function M:new(opts)
  opts = opts or {}

  local scale = opts.scale or 1
  local speed = opts.speed or 200

  local fish = setmetatable(
    {
      __type = 'Fish',
      scale = 1,
      speed = speed,
      spine = Chain:new({
        target = opts.origin,
        joint_count = 12,
        link_size = 64,
        angle_constraint = math.pi / 8,
      }),
      body_width = body_width,
      body_color = opts.body_color or { 58 / 255, 124 / 255, 165 / 255 },
      fin_color = opts.fine_color or { 129 / 255, 195 / 255, 215 / 255 }
    },
    self
  )

  fish:setScale(scale)

  return fish
end

function M:distance(point)
  return self.spine[1]:distance(point)
end

function M:setScale(scale)
  scale = scale or 1
  if self.scale == scale then
    return
  end

  self.spine:setScale(scale / self.scale)
  self.body_width = scaleBodyWidth(scale)
  self.scale = scale
end

function M:setTarget(target)
  self.spine.target = target
end

function M:setTargetAtSpeed(target, dt)
  self.spine.target = self.spine.target:deltaTarget(target, self.speed * dt)
end

function M:update(dt)
  self.spine:update(dt)
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

local function flattenPoints(points)
  local flat_points = {}
  for _, point in ipairs(points) do
    table.insert(flat_points, point.x)
    table.insert(flat_points, point.y)
  end
  return flat_points
end

local function paintPolygon(points, bg_color, color)
  color = color or bg_color

  love.graphics.setColor(bg_color[1], bg_color[2], bg_color[3])
  local positions = flattenPoints(cleanupPoints(points))
  local triangles = love.math.triangulate(positions)
  for _, triangle in ipairs(triangles) do
    love.graphics.polygon('fill', triangle)
  end

  love.graphics.setColor(color[1], color[2], color[3])
  love.graphics.line(positions)
end

local function drawDorsalFin(self)
  local joints = self.spine.joints
  local left = {}
  local right = {}
  local start_idx = 3
  local end_idx = 7

  table.insert(left, joints[start_idx])
  table.insert(right, joints[start_idx])
  local side_r, side_l = joints[start_idx]:orthogonal(
    joints[start_idx + 1],
    0.02 * self.body_width[start_idx]
  )
  table.insert(left, side_l)
  table.insert(right, side_r)

  for i = start_idx + 1, end_idx - 1, 1 do
    side_r, side_l = joints[i]:orthogonal(
      joints[i + 1],
      0.1 * self.body_width[i]
    )
    table.insert(left, side_l)
    table.insert(right, side_r)
  end

  side_r, side_l = joints[end_idx]:orthogonal(
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
  paintPolygon(points, self.fin_color, { 1, 1, 1 })
end

local function drawEyes(self)
  local joints = self.spine.joints

  local eye_size = 24 * self.scale
  local eye_right, eye_left = joints[1]:orthogonal(joints[2], self.body_width[1] - 0.6 * eye_size)
  love.graphics.setColor(0.7, 0.7, 0.7)
  love.graphics.circle("fill", eye_left.x, eye_left.y, eye_size)
  love.graphics.circle("fill", eye_right.x, eye_right.y, eye_size)
  local pupil_size = 18 * self.scale
  local pupil_left, pupil_right = joints[1]:orthogonal(joints[2], self.body_width[1] - 0.4 * eye_size)
  love.graphics.setColor(0.05, 0.05, 0.05)
  love.graphics.circle("fill", pupil_left.x, pupil_left.y, pupil_size)
  love.graphics.circle("fill", pupil_right.x, pupil_right.y, pupil_size)
end

local function drawBody(self)
  local joints = self.spine.joints
  local left = {}
  local right = {}

  local front = (joints[1].pos - joints[2].pos)
  front = front:setMagnitude(self.body_width[1] + self.spine[1].link_size) + joints[2].pos
  table.insert(left, front)
  table.insert(right, front)
  local angle = (joints[1].pos - joints[2]):angle()
  local front_left = Vec2:fromAngle(angle - math.pi / 8)
  front_left = front_left:setMagnitude(self.body_width[1])
  front_left = front_left + joints[1].pos
  table.insert(left, front_left)
  local front_left_2 = Vec2:fromAngle(angle - math.pi / 4)
  front_left_2 = front_left_2:setMagnitude(self.body_width[1])
  front_left_2 = front_left_2 + joints[1].pos
  table.insert(left, front_left_2)
  local front_right = Vec2:fromAngle(angle + math.pi / 8)
  front_right = front_right:setMagnitude(self.body_width[1])
  front_right = front_right + joints[1].pos
  table.insert(right, front_right)
  local front_right_2 = Vec2:fromAngle(angle + math.pi / 4)
  front_right_2 = front_right_2:setMagnitude(self.body_width[1])
  front_right_2 = front_right_2 + joints[1].pos
  table.insert(right, front_right_2)

  for i = 1, #joints - 2, 1 do
    local right_side, left_side = joints[i]:orthogonal(joints[i + 1], self.body_width[i])
    table.insert(left, left_side)
    table.insert(right, right_side)
  end

  local shape = {}
  for _, v in ipairs(left) do
    table.insert(shape, v)
  end
  for i = #right, 1, -1 do
    table.insert(shape, right[i])
  end

  local points = Splines:new(shape):render({ detail = 500, type = 'v2' })
  paintPolygon(points, self.body_color, { 1, 1, 1 })
end

local function drawLateralFin(self, side, sign)
  sign = sign or 1
  local r_x = self.scale * 75
  local r_y = r_x / 2
  local angle = (self.spine[2].pos - self.spine[3].pos):angle()
  love.graphics.translate(side.x, side.y)
  love.graphics.rotate(angle + sign * math.pi / 3)
  love.graphics.setColor(self.fin_color[1], self.fin_color[2], self.fin_color[3])
  love.graphics.ellipse("fill", 0, 0, r_x, r_y)
  love.graphics.setColor(1, 1, 1)
  love.graphics.ellipse("line", 0, 0, r_x, r_y)
  love.graphics.rotate(-angle - sign * math.pi / 3)
  love.graphics.translate(-side.x, -side.y)
end

local function drawLateralFins(self)
  local joints = self.spine.joints
  local right, left = joints[3]:orthogonal(joints[4], self.body_width[3])
  drawLateralFin(self, left)
  drawLateralFin(self, right, -1)
end

local function drawTail(self)
  local joints = self.spine.joints
  local left = {}
  local right = {}

  local right_side, left_side = joints[#joints - 2]:orthogonal(
    joints[#joints - 1],
    0.8 * self.body_width[#joints - 1]
  )
  table.insert(left, left_side)
  table.insert(right, right_side)

  local tail_1, tail_2 = joints[#joints]:orthogonal(
    joints[#joints - 1],
    1.2 * self.body_width[#joints]
  )
  table.insert(left, tail_1)
  table.insert(right, tail_2)

  local tail_end = (joints[#joints].pos - joints[#joints - 1].pos)
  tail_end = tail_end:setMagnitude(self.body_width[#joints] + self.spine[#joints].link_size)
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
  paintPolygon(points, self.fin_color, { 1, 1, 1 })
end

function M:draw()
  drawLateralFins(self)
  drawTail(self)
  drawBody(self)
  drawDorsalFin(self)
  drawEyes(self)
end

return M
