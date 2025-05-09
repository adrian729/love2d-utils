-- Lua v5.1^
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

function M:new(x, y)
  x = x or 0
  y = y or x
  return setmetatable(
    {
      __type = 'Vec2',
      x = x,
      y = y,
    },
    self
  )
end

function M:fromAngle(angle, m)
  return M:new(math.cos(angle), math.sin(angle)):setMagnitude(m or 1)
end

function M:random(m, min, max)
  return M:fromAngle(math.random(min or 0, max or (2 * math.pi)), m)
end

function M:__index(key)
  if key == nil then
    return M
  end

  if type(key) == 'number' then
    if key == 1 then
      return self.x
    elseif key == 2 then
      return self.y
    end
  end

  if type(key) ~= 'string' then
    return
  end

  if key == 'a' then
    return self.x
  elseif key == 'b' then
    return self.y
  elseif key == 'X' then
    return self.x
  elseif key == 'Y' then
    return self.y
  end

  return M[key]
end

function M:__tostring()
  return '(' .. self.x .. ', ' .. self.y .. ')'
end

-------------
-- arithmetic

-- non-trivial operations Hadamard style

function M.__add(a, b)
  if type(a) == "number" then
    return M:new(a + b.x, a + b.y)
  elseif type(b) == "number" then
    return M:new(a.x + b, a.y + b)
  end
  return M:new(a.x + b.x, a.y + b.y)
end

function M.__sub(a, b)
  if type(a) == "number" then
    return M:new(a - b.x, a - b.y)
  elseif type(b) == "number" then
    return M:new(a.x - b, a.y - b)
  end
  return M:new(a.x - b.x, a.y - b.y)
end

function M.__mul(a, b)
  if type(a) == "number" then
    return M:new(a * b.x, a * b.y)
  elseif type(b) == "number" then
    return M:new(a.x * b, a.y * b)
  end
  -- Hadamard product
  return M:new(a.x * b.x, a.y * b.y)
end

function M.__div(a, b)
  if type(a) == "number" then
    return M:new(a / b.x, a / b.y)
  elseif type(b) == "number" then
    return M:new(a.x / b, a.y / b)
  end
  -- Hadamard product
  return M:new(a.x / b.x, a.y / b.y)
end

function M.__mod(a, b)
  if type(a) == "number" then
    return M:new(a % b.x, a % b.y)
  elseif type(b) == "number" then
    return M:new(a.x % b, a.y % b)
  end
  -- Hadamard product style mod
  return M:new(a.x % b.x, a.y % b.y)
end

function M.__pow(a, b)
  if type(a) == "number" then
    return M:new(a ^ b.x, a ^ b.y)
  elseif type(b) == "number" then
    return M:new(a.x ^ b, a.y ^ b)
  end
  -- Hadamard product style pow
  return M:new(a.x ^ b.x, a.y ^ b.y)
end

function M.__unm(a)
  return M:new(-a.x, -a.y)
end

function M.__idiv(a, b)
  -- floor division
  if type(a) == "number" then
    return M:new(math.floor(a / b.x), math.floor(a / b.y))
  elseif type(b) == "number" then
    return M:new(math.floor(a.x / b), math.floor(a.y / b))
  end
  -- Hadamard product style idiv
  return M:new(math.floor(a.x / b.x), math.floor(a.y / b.y))
end

-------------
-- relational

-- relational operations by comparing each component.

function M.__eq(a, b)
  return a.x == b.x and a.y == b.y
end

function M.__lt(a, b)
  return a.x < b.x and a.y < b.y
end

function M.__le(a, b)
  return a.x <= b.x and a.y <= b.y
end

-----------------
-- functions

function M:magnitude()
  return math.sqrt(self.x ^ 2 + self.y ^ 2)
end

M.mag = M.magnitude

function M:setMagnitude(m)
  -- modifies self, returns self
  local frac = m / self:magnitude()
  self.x = frac * self.x
  self.y = frac * self.y

  return self
end

M.setMag = M.setMagnitude

function M:angle(v)
  -- angle value in rads.
  -- domain [-pi, pi]
  if v then
    return math.atan2(self:det(v), self:dot(v))
  end
  return math.atan2(self.y, self.x)
end

M.rotation = M.angle
M.heading = M.angle

function M.distance(a, b)
  return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2)
end

M.dist = M.distance

function M.dot(a, b) -- cos
  return a.x * b.x + a.y * b.y
end

M.scalar = M.dot

function M.det(a, b) -- sin
  return a.x * b.y - a.y * b.x
end

M.determinant = M.det

function M.toDegs(a)
  return a * math.pi / 180
end

M.toDegrees = M.toDegs

function M.toRad(a)
  return a * 180 / math.pi
end

M.toRadians = M.toRad

function M:normalize()
  return self:setMagnitude(1)
end

function M:limit(k)
  if self:magnitude() > k then
    self:setMagnitude(k)
  end
  return self
end

M.lim = M.limit

function M.direction(val)
  -- if val is a num, we take it as the angle in rads
  if type(val) == 'number' then
    return M:fromAngle(val)
  end
  -- else, we expect it to be a Vec2
  return val:normalize()
end

M.dir = M.direction

function M:perpendicular(dir, m)
  m = m or 1
  local dx = dir.x - self.x
  local dy = dir.y - self.y
  return M:new(dy, -dx):setMagnitude(m) + self,
      M:new(-dy, dx):setMagnitude(m) + self
end

function M.lerp(a, b, t)
  return a * (1 - t) + b * t
end

function M:deltaTarget(target, m)
  return (target - self):setMagnitude(m) + self
end

M.dTarget = M.deltaTarget

function M:constrainDistance(anchor, distance)
  return self - (self - anchor):setMagnitude(distance)
end

function M:spread()
  return self.x, self.y
end

-- ANGLES - TODO: if enought methods, move to its own module

local function simplifyAngle(angle)
  return angle % (2 * math.pi)
end

M.simplifyAngle = simplifyAngle

local function relativeAngleDiff(angle, target)
  -- i.e. How many radians do you need to turn the angle to match the target angle?

  -- Since angles are represented by values in [0, 2pi), it's helpful to rotate
  -- the coordinate space such that PI is at the target. That way we don't have
  -- to worry about the "seam" between 0 and 2pi.
  return math.pi - simplifyAngle(angle + math.pi - target)
end

M.relativeAngleDiff = relativeAngleDiff

local function constrainAngle(angle, target, constraint)
  -- Constrain the angle to be within a certain range of the target angle
  local relative_diff = relativeAngleDiff(angle, target)
  if math.abs(relative_diff) <= constraint then
    return simplifyAngle(angle)
  end
  if relative_diff > constraint then
    return simplifyAngle(target - constraint)
  end
  return simplifyAngle(target + constraint)
end

M.constrainAngle = constrainAngle


return M
