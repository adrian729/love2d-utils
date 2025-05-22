local M = {}

local Lizard = require 'lizard'
local Vec2 = require 'vec2'

local lizard
local scale

local food
local food_color = { 219 / 255, 182 / 255, 0 / 255 }

function M:load()
  scale = 0.5
  lizard = Lizard:new(Vec2:new(200, 200), scale)
  food = Vec2:new(love.math.random(10, 1000), love.math.random(10, 700))
end

function M:update(dt)
  local speed = 1.4
  local mouse = Vec2:new(love.mouse.getPosition())
  if lizard:distance(food) < 20 then
    scale = scale + 0.002
    lizard:setScale(scale)
    local old_food = food
    while food:distance(old_food) < 200 do
      food = Vec2:new(love.math.random(10, 1000), love.math.random(10, 700))
    end
  end
  lizard:resolve(mouse, speed * dt)
  --lizard:resolve(food, speed * dt)
end

function M:draw()
  love.graphics.setColor(food_color[1], food_color[2], food_color[3])
  love.graphics.circle('fill', food.x, food.y, math.min(scale * 20, 10))
  love.graphics.setColor(1, 1, 1)
  love.graphics.circle('line', food.x, food.y, math.min(scale * 20, 10))
  lizard:draw()
end

return M
