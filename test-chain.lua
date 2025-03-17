local M = {}

local Chain = require 'chain'
local Vec2 = require 'vec2'

local chain

function M:load()
  chain = Chain:new(Vec2:new(300, 300))
  print(tostring(chain))
  print('Simplify angle between 0 and 2pi (' .. math.pi .. '): ' .. tostring(Chain.simplifyAngle(math.pi)))
  print('Simplify angle bigger than 2pi (5pi): ' .. tostring(Chain.simplifyAngle(5 * math.pi)))
  print('Simplify angle bigger than 2pi (4pi): ' .. tostring(Chain.simplifyAngle(4 * math.pi)))
  print('Simplify angle bigger than 2pi (4pi + 4): ' .. tostring(Chain.simplifyAngle(4 * math.pi + 4)))
  print('Simplify angle smaller than 0 (-5pi): ' .. tostring(Chain.simplifyAngle(-5 * math.pi)))
  print('Simplify angle smaller than 0 (4 -4pi): ' .. tostring(Chain.simplifyAngle(4 - 4 * math.pi)))
end

function M:draw()
  chain:draw()
end

return M
