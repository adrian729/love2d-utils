_G.debug = false

local points, spline_1, spline_2, spline_uniform, spline_chordal, spline_v2

function love.load(arg, _unfilteredArg)
  for _, v in pairs(arg) do
    if v == '--debug' or v == '--d' then
      _G.debug = true
    end
  end

  local Splines = require 'splines'
  local SplinesV2 = require 'splines2'
  local Vec2 = require 'vec2'

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
  local spline_points_uni = {}
  local spline_points_chordal = {}
  local spline_points_v2 = {}
  for i = 2, #points, 2 do
    table.insert(spline_points_1, Vec2:new(points[i - 1], points[i] + 150))
    table.insert(spline_points_2, Vec2:new(points[i - 1], points[i] + 300))
    table.insert(spline_points_uni, Vec2:new(points[i - 1], points[i] + 450))
    table.insert(spline_points_chordal, Vec2:new(points[i - 1], points[i] + 600))
    table.insert(spline_points_v2, Vec2:new(points[i - 1], points[i] + 750))
  end

  spline_1 = Splines:new(spline_points_1)
  spline_2 = Splines:new(spline_points_2)
  spline_uniform = Splines:new(spline_points_uni)
  spline_chordal = Splines:new(spline_points_chordal)
  spline_v2 = Splines:new(spline_points_v2)
end

function love.update(dt)
end

local function flattenPoints(v2points)
  local res = {}
  for _, v2 in ipairs(v2points) do
    table.insert(res, v2.x)
    table.insert(res, v2.y)
  end
  return res
end

function love.draw()
  love.graphics.setColor(1, 1, 1)
  love.graphics.line(points)

  love.graphics.setColor(1, 0, 0)
  love.graphics.line(flattenPoints(spline_1:render()))

  love.graphics.setColor(0, 1, 0)
  love.graphics.line(flattenPoints(spline_2:render(1000)))

  love.graphics.setColor(0, 0, 1)
  love.graphics.line(flattenPoints(spline_uniform:render(1000, 0)))

  love.graphics.setColor(1, 1, 0)
  love.graphics.line(flattenPoints(spline_chordal:render(1000, 1)))

  love.graphics.setColor(0, 1, 1)
  love.graphics.line(flattenPoints(spline_v2:renderV2(1000)))
end
