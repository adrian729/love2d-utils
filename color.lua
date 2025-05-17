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

function M:new()
  return setmetatable(
    {
      __type = 'Color',
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
  return 'Color module'
end

function M.hue2rgb(p, q, t)
  if t < 0 then
    t = t + 1
  end
  if t > 1 then
    t = t - 1
  end

  if t < 1 / 6 then
    return p + (q - p) * 6 * t
  end
  if t < 1 / 2 then
    return q
  end
  if t < 2 / 3 then
    return p + (q - p) * (2 / 3 - t) * 6
  end

  return p
end

M.hueToRgb = M.hue2rgb

function M.hsl2rgb(h, s, l)
  h = h / 360
  s = s / 100
  l = l / 100

  if s == 0 then
    return l, l, l -- achromatic
  end

  local q
  if l < 0.5 then
    q = l * (1 + s)
  else
    q = l + s - l * s
  end
  local p = 2 * l - q

  local r = M.hue2rgb(p, q, h + 1 / 3);
  local g = M.hue2rgb(p, q, h);
  local b = M.hue2rgb(p, q, h - 1 / 3);
  local a = 1

  return r, g, b, a
end

M.hslToRgb = M.hsl2rgb

function M.hsv2rgb(h, s, v)
  h = h / 360
  s = s / 100
  v = v / 100

  local i = math.floor(h * 6)
  local f = h * 6 - i
  local p = v * (1 - s)
  local q = v * (1 - f * s)
  local t = v * (1 - (1 - f) * s)

  local m = i % 6
  if m == 0 then
    return v, t, p, 1
  elseif m == 1 then
    return q, v, p, 1
  elseif m == 2 then
    return p, v, t
  elseif m == 3 then
    return p, q, v
  elseif m == 4 then
    return t, p, v
  elseif m == 5 then
    return v, p, q
  end

  return 1, 1, 1, 1
end

M.hsvToRgb = M.hsv2rgb

return M
