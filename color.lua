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

local function hue2rgb(p, q, t)
  if t < 0 then t = t + 1 end
  if t > 1 then t = t - 1 end
  if t < 1 / 6 then return p + (q - p) * 6 * t end
  if t < 1 / 2 then return q end
  if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
  return p;
end

M.hue2rgb = hue2rgb
M.hueToRgb = hue2rgb

local function hsl2rgb(h, s, l)
  h = h / 360
  s = s / 100
  l = l / 100

  if s == 0 then
    return l, l, l -- achromatic
  end

  local r, g, b;
  local q = l < 0.5 and l * (1 + s) or l + s - l * s;
  local p = 2 * l - q;
  r = hue2rgb(p, q, h + 1 / 3);
  g = hue2rgb(p, q, h);
  b = hue2rgb(p, q, h - 1 / 3);

  local a = 1
  return r, g, b, a
end

M.hsl2rgb = hsl2rgb
M.hslToRgb = hsl2rgb

return M
