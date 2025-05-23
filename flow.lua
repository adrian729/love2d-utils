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

function M:initFlowField()
  self.flow_field = {}

  local base_x = 0
  local base_y = 0
  if self.variable_noise then
    base_x = 10000 * love.math.random()
    base_y = 10000 * love.math.random()
  end

  for r = 0, self.rows - 1 do
    local row = {}
    for c = 0, self.cols - 1 do
      table.insert(row, Utils.mapValue(
        love.math.noise((r + base_x) * self.noise_scale, (c + base_y) * self.noise_scale),
        0, 1,
        0, 2 * math.pi
      ))
    end
    table.insert(self.flow_field, row)
  end
end

function M:initIllustrateData()
  local vw = love.graphics.getWidth()
  local vh = love.graphics.getHeight()

  while #self.draw_opts.data < self.draw_opts.max_data_size do
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
        if r <= 0 then
          r = 1
        end
        if r > #self.flow_field then
          r = #self.flow_field
        end
        local c = math.floor(prev.x / self.scale)
        if c <= 0 then
          c = 1
        end
        if c > #self.flow_field[r] then
          c = #self.flow_field[r]
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
  end
end

function M:initDrawData()
  self.draw_opts.data = {}
  if self.draw_opts.mode == 'illustrate' then
    self:initIllustrateData()
  end
end

function M:new(opts)
  opts = opts or {}

  local scale = opts.scale or 2

  local vw = love.graphics.getWidth()
  local vh = love.graphics.getHeight()

  local draw_opts = opts.draw_opts or {}

  local flow = setmetatable(
    {
      __type = 'Flow',
      flow_field = nil,
      scale = scale,
      noise_scale = opts.noise_scale or 0.02,
      rows = math.floor(vh / scale),
      cols = math.floor(vw / scale),
      variable_noise = opts.variable_noise or false,
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
    },
    self
  )

  flow:initFlowField()
  flow:initDrawData()

  return flow
end

function M:setOpts(opts)
  opts = opts or {}

  local vw = love.graphics.getWidth()
  local vh = love.graphics.getHeight()

  self.scale = opts.scale or self.scale
  self.noise_scale = opts.noise_scale or self.noise_scale
  self.rows = math.floor(vh / self.scale)
  self.cols = math.floor(vw / self.scale)
  self.variable_noise = opts.variable_noise or false

  local draw_opts = opts.draw_opts or {}
  self:setDrawOpts(draw_opts)

  self:initFlowField()
  self:initDrawData()
end

function M:setDrawOpts(draw_opts)
  draw_opts = draw_opts or {}
  self.draw_opts = Utils.withDefaults(
    draw_opts,
    self.draw_opts
  )

  self:initDrawData()
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

function M:draw_lines()
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

function M:draw_illustrate()
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
    self:draw_lines()
  elseif self.draw_opts.mode == 'illustrate' then
    self:draw_illustrate()
  end
end

return M
