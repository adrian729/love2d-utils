local Utils = require 'utils'
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

local function _setFlowField(self)
  self.flow_field = {}
  for r = 0, self.rows - 1 do
    local row = {}
    for c = 0, self.cols - 1 do
      table.insert(row, Utils.mapValue(
        love.math.noise(r * self.noise_scale, c * self.noise_scale),
        0, 1,
        0, 2 * math.pi
      ))
    end
    table.insert(self.flow_field, row)
  end
end

M.setFlowField = _setFlowField

function M:new(opts)
  opts = opts or {}

  local scale = opts.scale or 2

  local vw = love.graphics.getWidth()
  local vh = love.graphics.getHeight()

  local draw_opts = opts.draw_opts or {}

  local flow = {
    __type = 'Flow',
    flow_field = nil,
    scale = scale,
    noise_scale = opts.noise_scale or 0.02,
    rows = math.floor(vh / scale),
    cols = math.floor(vw / scale),
    draw_opts = Utils.withDefaults(
      draw_opts,
      {
        mode = draw_opts.mode or 'line',
        data = {},
        max_data_size = draw_opts.max_data_size or 1000,
        loop = 10,
        max_iters = 50
      }
    )
  }
  _setFlowField(flow)

  return setmetatable(
    flow,
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
  return 'Flow module'
end

function M:update(_dt)
end

local function draw_lines(self)
  for i, row in ipairs(self.flow_field) do
    for j, v in ipairs(row) do
      love.graphics.push()
      love.graphics.translate(j * self.scale, i * self.scale)
      love.graphics.rotate(v)
      local hue = Utils.mapValue(
        v,
        0, 2 * math.pi,
        0, 360
      )
      love.graphics.setColor(Color.hsv2rgb(hue, 100, 100))
      love.graphics.line(0, 0, 3.0 * self.scale, 0)
      love.graphics.pop()
    end
  end
end

local function illustrate_flow_field(self)
  local vw = love.graphics.getWidth()
  local vh = love.graphics.getHeight()

  for _ = 1, self.draw_opts.loop do
    local prev = {
      x = love.math.random(vw * 1000) / 1000,
      y = love.math.random(vh * 1000) / 1000
    }
    local it_data = { prev }
    while
      #it_data <= self.draw_opts.max_iters
      and prev.x > 0 and prev.x < vw
      and prev.y > 0 and prev.y < vh
      and #self.draw_opts.data < self.draw_opts.max_data_size
    do
      local r = math.floor(prev.y / self.scale)
      if r == 0 then
        r = 1
      end
      local c = math.floor(prev.x / self.scale)
      if c == 0 then
        c = 1
      end
      local angle = self.flow_field[r][c]

      local section = {}
      section.x = prev.x + self.scale * math.cos(angle)
      section.y = prev.y + self.scale * math.sin(angle)
      section.r, section.g, section.b = Color.hsv2rgb(
        Utils.mapValue(angle, 0, 2 * math.pi, 0, 360),
        Utils.mapValue(angle, 0, 2 * math.pi, 0, 100),
        Utils.mapValue(angle, 0, 2 * math.pi, 0, 100)
      )
      table.insert(it_data, section)

      prev = section
    end
    table.insert(self.draw_opts.data, it_data)
  end

  for _, it in ipairs(self.draw_opts.data) do
    for i, curr in ipairs(it) do
      if i > 1 then
        local prev = it[i - 1]
        love.graphics.setColor(curr.r, curr.g, curr.b)
        love.graphics.line(prev.x, prev.y, curr.x, curr.y)
      end
    end
  end
end

function M:draw()
  if self.draw_opts.mode == 'line' or not self.draw_opts.mode then
    draw_lines(self)
  elseif self.draw_opts.mode == 'illustrate' then
    illustrate_flow_field(self)
  end
end

return M
