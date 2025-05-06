local M = {}

local Tree = require 'tree'

local tree_1, tree_2

function M:load()
  local vw = love.graphics.getWidth()

  tree_1 = Tree:new(12, vw / 2.1)
  print(tree_1)
end

function M:update(_dt)
end

function M:draw()
  tree_1:draw()
end

return M
