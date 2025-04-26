local Flock = {}

local Vec2 = require 'vec2'

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

function Flock:new(
    size,
    max_speed,
    max_force,
    separate_dist, neighbour_dist,
    separate_k, align_k, coherence_k,
    vw_min, vw_max, vh_min, vh_max
)
  size = size or 300
  max_speed = max_speed or 400

  return setmetatable(
    {
      size = size,
      max_speed = max_speed,
      max_force = max_force or 0.3,
      separate_dist = separate_dist or 50,
      neighbour_dist = neighbour_dist or 100,
      separate_k = separate_k or 1.8,
      align_k = align_k or 1.0,
      coherence_k = coherence_k or 1.0,
      positions = initPositions(size, vw_min, vw_max, vh_min, vh_max),
      velocities = initVelocities(size, max_speed),
      accelerations = initAccelerations(size),
      guides = {}
    },
    self
  )
end

function Flock:__index(key)
  if key == nil then
    return Flock
  end

  if type(key) ~= 'string' then
    return
  end

  return Flock[key]
end

function Flock:__tostring()
  return 'flock'
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

local function steer_to_target(self, i, target)
  local diff = target - self.positions[i]
  local dist = self.positions[i]:distance(target)
  local k = 4.0
  if dist < 100 then
    k = -6.0
  end

  local force = target_force(
    self, k,
    diff, self.velocities[i]
  )
  self.accelerations[i] = self.accelerations[i] + force
end

local function guide(self)
  local screen_size = Vec2:new(
    love.graphics.getWidth(),
    love.graphics.getHeight()
  )
  local mouse = Vec2:new(love.mouse.getPosition())

  for i = 1, self.size, 1 do
    steer(self, i)
    if mouse > Vec2:new() and mouse < screen_size then
      steer_to_target(self, i, mouse)
    end
  end
end

function Flock:update(dt)
  local screen_size = Vec2:new(
    love.graphics.getWidth(),
    love.graphics.getHeight()
  )

  guide(self)
  for i = 1, self.size, 1 do
    local v = self.velocities[i] + self.accelerations[i]
    self.velocities[i] = v:limit(self.max_speed * dt)
    self.positions[i] = self.positions[i] + self.velocities[i]
    self.positions[i] = (self.positions[i] + screen_size) % screen_size
  end
end

function Flock:draw()
  for i = 1, self.size, 1 do
    local p = self.positions[i]
    local v = self.positions[i] + self.velocities[i]:setMag(14)
    local a = self.positions[i] + self.accelerations[i] * 100
    local l, r = p:perpendicular(v, 5)
    love.graphics.setColor(1, 0, 0)
    love.graphics.circle('fill', p.x, p.y, 3)
    love.graphics.setColor(1, 1, 1)
    love.graphics.polygon('fill', l.x, l.y, v.x, v.y, r.x, r.y)

    -- debug
    local debug = false
    if debug then
      print('v')
      print(self.velocities[i])
      print(self.velocities[i]:mag())
      print('a')
      print(self.accelerations[i])
      print(self.accelerations[i]:mag())
      love.graphics.setColor(1, 0, 0)
      love.graphics.circle('line', p.x, p.y, self.separate_dist)
      love.graphics.setColor(0, 1, 0)
      love.graphics.circle('line', p.x, p.y, self.neighbour_dist)

      love.graphics.setColor(0, 0, 1)
      love.graphics.line(p.x, p.y, a.x, a.y)
      local v_2 = self.positions[i] + self.velocities[i] * 10
      love.graphics.setColor(0, 1, 1)
      love.graphics.line(p.x, p.y, v_2.x, v_2.y)
    end
  end
end

return Flock
