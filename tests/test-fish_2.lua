local M = {}

local Fish = require 'fish'
local Vec2 = require 'vec2'

local fish
local scale

local food
local food_color = { 219 / 255, 182 / 255, 0 / 255 }

function M:load()
  scale = 0.1
  fish = Fish:new(Vec2:new(200, 200), scale)
  food = Vec2:new(love.math.random(10, 1000), love.math.random(10, 700))
end

function M:update(dt)
  local speed = 1.4
  local mouse = Vec2:new(love.mouse.getPosition())
  if fish:distance(food) < 20 then
    scale = scale + 0.002
    fish:setScale(scale)
    local old_food = food
    while food:distance(old_food) < 200 do
      food = Vec2:new(love.math.random(10, 1000), love.math.random(10, 700))
    end
  end
  fish:resolve(mouse, dt)
end

function M:draw()
  love.graphics.setColor(food_color[1], food_color[2], food_color[3])
  love.graphics.circle('fill', food.x, food.y, math.min(scale * 20, 10))
  love.graphics.setColor(1, 1, 1)
  love.graphics.circle('line', food.x, food.y, math.min(scale * 20, 10))
  fish:draw()
end

return M
