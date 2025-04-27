local M = {}

local Vec2 = require 'vec2'
local Fish = require 'fish'

local function initPositions(size, vw_min, vw_max, vh_min, vh_max)
  vw_min = vw_min or 0
  vw_max = vw_max or love.graphics.getWidth()
  vh_min = vh_min or 0
  vh_max = vh_max or love.graphics.getHeight()
  local positions = {}
  for _ = 1, size, 1 do
    table.insert(
      positions,
      Vec2:new(
        love.math.random(vw_min, vw_max),
        love.math.random(vh_min, vh_max)
      )
    )
  end
  return positions
end

local function initVelocities(size, max_speed)
  local velocities = {}
  for _ = 1, size, 1 do
    table.insert(velocities, Vec2:random(love.math.random(max_speed)))
  end
  return velocities
end

local function initAccelerations(size)
  local accelerations = {}
  for _ = 1, size, 1 do
    table.insert(accelerations, Vec2:new())
  end
  return accelerations
end

local function initFish(positions, scale)
  local fish = {}
  for _, p in ipairs(positions) do
    table.insert(fish, Fish:new(p, scale))
  end
  return fish
end

-- TODO: instead of adding each thing and have all flock logic here, create a flock and work with it as a composite
function M:new(
    size,
    scale,
    max_speed,
    max_force,
    separate_dist, neighbour_dist,
    separate_k, align_k, coherence_k,
    fish_speed_k,
    vw_min, vw_max, vh_min, vh_max
)
  size = size or 50
  scale = scale or 0.08
  max_speed = max_speed or 350

  local positions = initPositions(size, vw_min, vw_max, vh_min, vh_max)

  fish_speed_k = fish_speed_k or 1.8

  return setmetatable(
    {
      size = size,
      scale = scale,
      max_speed = max_speed,
      max_force = max_force or 0.6,
      separate_dist = separate_dist or 75,
      neighbour_dist = neighbour_dist or 150,
      separate_k = separate_k or 2.8,
      align_k = align_k or 1.0,
      coherence_k = coherence_k or 1.0,
      positions = positions,
      velocities = initVelocities(size, max_speed),
      accelerations = initAccelerations(size),
      fish = initFish(positions, scale),
      fish_speed_k = fish_speed_k,
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
  return 'school'
end

local function target_force(self, k, target_dir, velocity)
  return k * (
    target_dir:normalize() * self.max_speed - velocity
  ):limit(self.max_force)
end

local function steer(self, curr_i)
  local sum_align = Vec2:new()
  local sum_coherence = Vec2:new()
  local sum_separate = Vec2:new()
  local neighbours_align = 0
  local neighbours_avoid = 0

  local curr_p = self.positions[curr_i]

  for i = 1, self.size, 1 do
    local p = self.positions[i]
    local d = curr_p:distance(p)
    if d > 0 and d < self.neighbour_dist then
      sum_align = sum_align + self.velocities[i]
      sum_coherence = sum_coherence + p
      neighbours_align = neighbours_align + 1
    end
    if d > 0 and d < self.separate_dist then
      sum_separate = sum_separate + (curr_p - p):normalize() / d
      neighbours_avoid = neighbours_avoid + 1
    end
  end


  self.accelerations[curr_i] = Vec2:new()
  if neighbours_avoid > 0 then
    local force = target_force(
      self, self.separate_k,
      sum_separate, self.velocities[curr_i]
    )
    self.accelerations[curr_i] = self.accelerations[curr_i] + force
  end
  if neighbours_align > 0 then
    local force_align = target_force(
      self, self.align_k,
      sum_align, self.velocities[curr_i]
    )
    self.accelerations[curr_i] = self.accelerations[curr_i] + force_align
    sum_coherence = sum_coherence / neighbours_align - curr_p
    local force_coherence = target_force(
      self, self.coherence_k,
      sum_coherence, self.velocities[curr_i]
    )
    self.accelerations[curr_i] = self.accelerations[curr_i] + force_coherence
  end
end

local function steer_to_target(self, i, target, k_far, k_close, range_close)
  range_close = range_close or 100

  local diff = target - self.positions[i]
  local dist = self.positions[i]:distance(target)

  if k_far and dist >= range_close then
    self.accelerations[i] = self.accelerations[i] + target_force(
      self, k_far,
      diff, self.velocities[i]
    )
  end
  if k_close and dist < range_close then
    self.accelerations[i] = self.accelerations[i] + target_force(
      self, k_close,
      diff, self.velocities[i]
    )
  end
end

local function guide(self, target, k_far, k_close, range_close)
  local vw = love.graphics.getWidth()
  local vh = love.graphics.getHeight()
  local screen_size = Vec2:new(vw, vh)
  local v_offset = Vec2:new(5)
  local mouse = Vec2:new(love.mouse.getPosition())

  for i = 1, self.size, 1 do
    steer(self, i)

    if target then
      steer_to_target(
        self, i, target,
        k_far, k_close, range_close
      )
    end

    if mouse > v_offset and mouse < screen_size - v_offset then
      steer_to_target(
        self, i, mouse,
        4.0, -6.0, 50
      )
    end
  end
end

function M:update(dt, target, k_far, k_close, range_close)
  guide(self, target, k_far, k_close, range_close)
  for i = 1, self.size, 1 do
    local v = self.velocities[i] + self.accelerations[i]
    self.velocities[i] = v:limit(self.max_speed * dt)
    self.positions[i] = self.positions[i] + self.velocities[i]
  end

  for i, fish_entity in ipairs(self.fish) do
    fish_entity:resolve(self.positions[i], self.fish_speed_k * dt)
    self.positions[i] = fish_entity.spine.joints[1]
  end
end

function M:draw(debug)
  for _, fish_entity in ipairs(self.fish) do
    fish_entity:draw()
  end
  if debug then
    for i = 1, self.size, 1 do
      local p = self.positions[i]
      local v = self.velocities[i]
      local a = self.accelerations[i] * 10

      love.graphics.setColor(1, 0, 0)
      love.graphics.line(p.x, p.y, p.x + a.x, p.y + a.y)
    end
  end
end

return M
