local M = {}

local Chain = require 'chain'
local Vec2 = require 'vec2'

local chain

function M:load()
  chain = Chain:new(Vec2:new(300, 300))
  print(tostring(chain))
end

function M:draw()
  chain:draw()
end

return M
