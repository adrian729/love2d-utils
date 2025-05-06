local Vec2 = require 'vec2'
local Color = require 'color'

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

local function expand(str)
  local forward_prob = 0.4
  local new_str = ''
  for i = 1, #str do
    local char = str:sub(i, i)
    if char == 'S' then
      char = 'FB'
    elseif char == 'F' then
      if love.math.random() < forward_prob then
        char = 'FF'
      end
    elseif char == 'B' then
      local branching = love.math.random()
      local bi_branch_prob = 0.45
      if branching < bi_branch_prob then
        char = '[llFB][rFB]'
      elseif branching < 2 * bi_branch_prob then
        char = '[lFB][rrFB]'
      else
        char = '[llFB][cFB][rrFB]'
      end
    end
    new_str = new_str .. char
  end

  return new_str
end

function M:new(expand_k, start)
  local vw = love.graphics.getWidth()

  expand_k = expand_k or 8
  start = start or vw / 2

  local str = 'S'
  for _ = 1, expand_k, 1 do
    str = expand(str)
  end

  return setmetatable(
    {
      __type = 'Tree',
      str = str,
      start = start
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
  return self.str
end

function M:draw()
  local vw = love.graphics.getWidth()
  local vh = love.graphics.getHeight()

  local l = 2
  local angle = 0.1 * math.pi

  local lineWidth = 15
  local lineWidth_k = 0.8
  local hue = 0
  local hue_k = 11
  local brightness = 10
  local brightness_k = 1.2

  love.graphics.push()
  love.graphics.setColor(1, 0, 0)
  love.graphics.translate(self.start, vh - 1)
  love.graphics.rotate(-math.pi)
  for i = 1, #self.str do
    local char = self.str:sub(i, i)
    if char == 'F' then
      love.graphics.setLineWidth(lineWidth)
      love.graphics.setColor(Color.hsl2rgb(hue, 100, brightness))
      love.graphics.line(0, 0, 0, l)
      love.graphics.translate(0, l)
    elseif char == 'l' then
      love.graphics.rotate(-angle)
    elseif char == 'c' then
      love.graphics.rotate(0)
    elseif char == 'r' then
      love.graphics.rotate(angle)
    elseif char == '[' then -- enter branch
      love.graphics.push()
      lineWidth = lineWidth_k * lineWidth
      hue = (hue + hue_k) % 360
      brightness = brightness_k * brightness
    elseif char == ']' then -- exit branch
      lineWidth = (1.0 / lineWidth_k) * lineWidth
      hue = (hue - hue_k + 360) % 360
      brightness = (1.0 / brightness_k) * brightness
      love.graphics.pop()
    end
  end
  love.graphics.pop()
end

return M
