local M = {}

local Fish = require 'fish'
local Vec2 = require 'vec2'

local fish

function M:load()
  fish = Fish:new(Vec2:new(200, 200), 0.4)
end

function M:update(dt)
  local speed = 1.4
  local mouse = Vec2:new(love.mouse.getPosition())
  fish:resolve(mouse, speed * dt)
end

function M:draw()
  fish:draw()
end

return M
