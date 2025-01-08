-- Catmull-Rom splines
-- lua v5.1^
local Splines = {}

function Splines:new(points)
  return setmetatable(
    {
      points = points,
    },
    self
  )
end

function Splines:__index(key)
  if key == nil then
    return Splines
  end

  if type(key) ~= 'string' then
    return
  end

  return Splines[key]
end

function Splines:__tostring()
  -- TODO
  return 'Splines'
end

local function getColinearity(x1, y1, x2, y2, x3, y3)
  local ux = x2 - x1
  local uy = y2 - y1
  local vx = x3 - x2
  local vy = y3 - y2
  local udv = (ux * vx + uy * vy)
  local udu = (ux * ux + uy * uy)
  local vdv = (vx * vx + vy * vy)
  local scalar = 1
  if udv < 0 then --the angle is greater than 90 degrees.
    scalar = 0
  end
  return scalar * ((udv * udv) / (udu * vdv))
end

function Splines:render(detail)
  local points = self.points
  if #points < 4 then
    return points
  end

  detail = detail or 5
  local rpoints = {}
  for i = 1, #points - 2, 2 do
    local p0x = points[i - 2]
    local p0y = points[i - 1]
    local p1x = points[i]
    local p1y = points[i + 1]
    local p2x = points[i + 2]
    local p2y = points[i + 3]
    local p3x = points[i + 4]
    local p3y = points[i + 5]

    -- Calculate the colinearity and the control points for the section:
    local colinearity = 0
    local t1x = 0
    local t1y = 0
    local colin1 = nil
    if p0x and p0y then
      t1x = 0.5 * (p2x - p0x)
      t1y = 0.5 * (p2y - p0y)
      colin1 = getColinearity(p0x, p0y, p1x, p1y, p2x, p2y)
    end

    local t2x = 0
    local t2y = 0
    local colin2 = nil
    if (p3x and p3y) then
      t2x = 0.5 * (p3x - p1x)
      t2y = 0.5 * (p3y - p1y)
      colin2 = getColinearity(p1x, p1y, p2x, p2y, p3x, p3y)
    end

    if colin1 and colin2 then
      colinearity = (colin1 + colin2) / 2
    elseif (colin1) then
      colinearity = colin1
    elseif (colin2) then
      colinearity = colin2
    end

    -- Get the proper detail using the computed colinearity, then calculate the spline points:
    local rdetail = (detail * (1 - colinearity))
    for j = 0, rdetail do
      local s = j / rdetail
      local s2 = s * s
      local s3 = s * s * s
      local h1 = 2 * s3 - 3 * s2 + 1
      local h2 = -2 * s3 + 3 * s2
      local h3 = s3 - 2 * s2 + s
      local h4 = s3 - s2
      local px = (h1 * p1x) + (h2 * p2x) + (h3 * t1x) + (h4 * t2x)
      local py = (h1 * p1y) + (h2 * p2y) + (h3 * t1y) + (h4 * t2y)
      table.insert(rpoints, px)
      table.insert(rpoints, py)
    end
    if (math.ceil(rdetail) > rdetail) then
      table.insert(rpoints, p2x)
      table.insert(rpoints, p2y)
    end
  end

  return rpoints
end

return Splines
