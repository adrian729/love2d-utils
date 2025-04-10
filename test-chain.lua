local M = {}

local Chain = require 'chain'
local Vec2 = require 'vec2'

local chain_1, chain_2

function M:load()
  chain_1 = Chain:new(Vec2:new(300, 300))
  chain_2 = Chain:new(Vec2:new(500, 900), 128, 10, math.pi / 6)
  print(tostring(chain_1))
  print(tostring(chain_2))
  print('Simplify angle between 0 and 2pi (' .. math.pi .. '): ' .. tostring(Chain.simplifyAngle(math.pi)))
  print('Simplify angle bigger than 2pi (5pi): ' .. tostring(Chain.simplifyAngle(5 * math.pi)))
  print('Simplify angle bigger than 2pi (4pi): ' .. tostring(Chain.simplifyAngle(4 * math.pi)))
  print('Simplify angle bigger than 2pi (4pi + 4): ' .. tostring(Chain.simplifyAngle(4 * math.pi + 4)))
  print('Simplify angle smaller than 0 (-5pi): ' .. tostring(Chain.simplifyAngle(-5 * math.pi)))
  print('Simplify angle smaller than 0 (4 -4pi): ' .. tostring(Chain.simplifyAngle(4 - 4 * math.pi)))
end

function M:update(dt)
  local speed = 1.4
  local mouse = Vec2:new(love.mouse.getPosition())
  chain_2:resolve(mouse, speed * dt)
end

function M:draw()
  chain_1:draw()
  chain_2:draw()
end

return M
