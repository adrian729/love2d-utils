local Utils = require 'utils'
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

local function _setProbs(probs)
  probs = probs or {}
  local branch_left = probs.branch_left or 0.5
  local branch_right = probs.branch_right or (2 * branch_left)
  return Utils.withDefaults(
    probs,
    {
      no_expand = 0.1,
      forward = 0.4,
      branch_left = branch_left,
      branch_right = branch_right,
      branch_center = (1.0 - branch_left - branch_right)
    }
  )
end

local function _setColor(color)
  color = color or {}
  return {
    hue =
        Utils.withDefaults(
          color.hue or {},
          {
            hue = 0,
            k = 0,
            iters_k = 10
          }
        ),
    brightness =
        Utils.withDefaults(
          color.brightness or {},
          {
            brightness = 10,
            k = 1.2,
            iters_k = 0
          }
        )

  }
end
local function _setAttrs(attrs)
  local vw = love.graphics.getWidth()
  local vh = love.graphics.getHeight()

  attrs = attrs or {}
  return {
    pos = attrs.pos or Vec2:new(vw / 2, vh),
    angle = (attrs.angle or 0) - math.pi,
    branch = Utils.withDefaults(
      attrs.branch or {},
      {
        length = 2,
        width = 15,
        width_k = 0.8,
        angle = 0.1 * math.pi,
        angle_k = 0.95,
      }
    )
  }
end

function M:new(opts)
  opts = opts or {}

  return setmetatable(
    {
      __type = 'Tree',
      str = opts.str or 'S',
      iterations = 0,
      probs = _setProbs(opts.probs),
      color = _setColor(opts.color),
      attrs = _setAttrs(opts.attrs)
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

function M:setProbs(probs)
  self.probs = _setProbs(probs)
end

function M:setColor(color)
  self.color = _setColor(color)
end

function M:setAttrs(attrs)
  self.attrs = _setAttrs(attrs)
end

function M:expand(iters)
  local probs = self.probs

  for _ = 1, iters do
    local new_str = ''
    for i = 1, #self.str do
      local rand = love.math.random()
      local char = self.str:sub(i, i)
      if char == 'S' then
        char = 'FB'
      elseif rand < probs.no_expand then -- don't expand
      elseif char == 'F' then
        if rand < probs.forward then
          char = 'FF'
        end
      elseif char == 'B' then
        if rand < probs.branch_left then
          char = '[llFB][rFB]'
        elseif rand < probs.branch_right then
          char = '[lFB][rrFB]'
        elseif rand < probs.branch_center then
          char = '[llFB][cFB][rrFB]'
        end
      end
      new_str = new_str .. char
    end

    self.str = new_str
  end

  self.iterations = self.iterations + iters
end

function M:draw()
  local branch = self.attrs.branch
  local branch_width = branch.width
  local branch_angle = branch.angle

  local hue_opts = self.color.hue
  local hue = hue_opts.hue
  local hue_k = hue_opts.iters_k / self.iterations + hue_opts.k

  local brightness_opts = self.color.brightness
  local brightness = brightness_opts.brightness
  local brightness_k = brightness_opts.iters_k / self.iterations + brightness_opts.k

  love.graphics.push()
  love.graphics.setColor(1, 0, 0)
  love.graphics.translate(self.attrs.pos:spread())
  love.graphics.rotate(self.attrs.angle)
  for i = 1, #self.str do
    local char = self.str:sub(i, i)
    if char == 'F' then
      love.graphics.setColor(Color.hsl2rgb(hue, 100, brightness))
      love.graphics.setLineWidth(branch_width)
      love.graphics.line(0, 0, 0, branch.length)
      love.graphics.translate(0, branch.length)
    elseif char == 'l' then
      love.graphics.rotate(-branch_angle)
    elseif char == 'c' then
      love.graphics.rotate(0)
    elseif char == 'r' then
      love.graphics.rotate(branch_angle)
    elseif char == '[' then -- enter branch
      love.graphics.push()
      branch_angle = branch_angle * branch.angle_k
      branch_width = branch_width * branch.width_k
      hue = (hue + hue_k) % 360
      brightness = brightness * brightness_k
    elseif char == ']' then -- exit branch
      branch_angle = branch_angle / branch.angle_k
      branch_width = branch_width / branch.width_k
      hue = (hue - hue_k + 360) % 360
      brightness = brightness / brightness_k
      love.graphics.pop()
    end
  end
  love.graphics.pop()
end

return M
