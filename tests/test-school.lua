local M = {}

local School = require 'school'
local Vec2 = require 'vec2'

local school

local min_food_qty = 5
local max_food_qty = 20
local food = {
  pos = Vec2:new(),
  qty = 0,
  crumbs = {},
  range = 15
}
local food_color = { 219 / 255, 182 / 255, 0 / 255 }

local function newFood()
  local vw = love.graphics.getWidth()
  local vh = love.graphics.getHeight()

  local old_pos = food.pos
  while food.pos:distance(old_pos) < 500 do
    food.pos = Vec2:new(
      love.math.random(20, vw - 20),
      love.math.random(20, vh - 20)
    )
  end

  food.qty = love.math.random(min_food_qty, max_food_qty)
  food.crumbs = {}
  for _ = 1, food.qty, 1 do
    local dist = love.math.random(0, 2 * food.range * 100) / 100
    local angle = love.math.random(0, math.floor(2 * math.pi * 1000)) / 10000
    table.insert(food.crumbs, Vec2:fromAngle(angle, dist) + food.pos)
  end
end

function M:load()
  school = School:new()
  newFood()
end

function M:update(dt)
  for _, fish in ipairs(school.fish) do
    if fish:distance(food.pos) < food.range then
      newFood()
      break
    end
  end

  school:update(dt, food.pos, 2, 10.0, food.range * 4)
end

function M:draw()
  love.graphics.setColor(food_color[1], food_color[2], food_color[3])
  for _, crumb in ipairs(food.crumbs) do
    love.graphics.circle('fill',
      crumb.x, crumb.y,
      1.5
    )
  end
  school:draw()
end

return M
