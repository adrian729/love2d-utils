local M = {}

local Tree = require 'tree'
local Vec2 = require 'vec2'

local trees

function M:load()
  local vw = love.graphics.getWidth()
  local vh = love.graphics.getHeight()

  trees = {}
  for i = 1, love.math.random(10, 20) do
    local t = Tree:new({
      attrs = {
        pos = Vec2:new(love.math.random(10, vw - 10), vh)
      }
    })
    t:expand(love.math.random(12, 14))
    table.insert(trees, t)
    print('T_' .. i .. ': ' .. t.str)
    print()
  end
end

function M:update(_dt)
end

function M:draw()
  for _, t in ipairs(trees) do
    t:draw()
  end
end

return M
