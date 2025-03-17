local M = {}

local Splines = require 'splines'
local Vec2 = require 'vec2'

local points, spline_1, spline_2, spline_v2, spline_uniform, spline_chordal

local function flattenPoints(points_v2)
  local res = {}
  for _, v2 in ipairs(points_v2) do
    table.insert(res, v2.x)
    table.insert(res, v2.y)
  end
  return res
end

M.load = function()
  local x0 = 100
  local y0 = 200
  points = {
    x0, y0,
    x0 + 50, y0 + 10,
    x0 + 100, y0 - 100,
    x0 + 150, y0 - 120,
    x0 + 200, y0,
    x0 + 350, y0 + 50,
  }

  local spline_points_1 = {}
  local spline_points_2 = {}
  local spline_points_3 = {}
  local spline_points_4 = {}
  local spline_points_5 = {}
  for i = 2, #points, 2 do
    table.insert(spline_points_1, Vec2:new(points[i - 1], points[i] + 150))
    table.insert(spline_points_2, Vec2:new(points[i - 1], points[i] + 300))
    table.insert(spline_points_3, Vec2:new(points[i - 1], points[i] + 450))
    table.insert(spline_points_4, Vec2:new(points[i - 1], points[i] + 600))
    table.insert(spline_points_5, Vec2:new(points[i - 1], points[i] + 750))
  end

  spline_1 = Splines:new(spline_points_1)
  spline_2 = Splines:new(spline_points_2)
  spline_v2 = Splines:new(spline_points_3)
  spline_uniform = Splines:new(spline_points_4)
  spline_chordal = Splines:new(spline_points_5)
end

M.draw = function()
  love.graphics.setColor(1, 1, 1)
  love.graphics.line(points)

  love.graphics.setColor(1, 0, 0)
  love.graphics.line(flattenPoints(spline_1:render({})))

  love.graphics.setColor(0, 1, 0)
  love.graphics.line(flattenPoints(spline_2:render({ detail = 1000, alpha = 0.3 })))


  love.graphics.setColor(0, 1, 1)
  love.graphics.line(flattenPoints(spline_v2:render({ detail = 1000, type = 'v2' })))

  love.graphics.setColor(0, 0, 1)
  love.graphics.line(flattenPoints(spline_uniform:render({ detail = 1000, alpha = 0 })))

  love.graphics.setColor(1, 1, 0)
  love.graphics.line(flattenPoints(spline_chordal:render({ detail = 1000, alpha = 1 })))
end

return M
