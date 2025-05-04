local M = {}

local Chain = require 'chain_2'
local Joint = require 'joint'
local Vec2 = require 'vec2'

local chain

function M:load()
  local vw = love.graphics.getWidth()
  local vh = love.graphics.getHeight()

  local anchor = nil -- Vec2:new(vw / 2, vh - 10)
  local joints = {}
  for i = 10, 100, 10 do
    for _ = 1, 100 / i, 1 do
      table.insert(
        joints,
        Joint:new(nil, i, math.pi / 8)
      )
    end
  end
  local target = nil
  chain = Chain:new(joints, anchor, target)
end

function M:update(dt)
  local mouse = Vec2:new(love.mouse.getPosition())

  chain.target = mouse
  chain:update(dt)
end

function M:draw()
  --print(tostring(chain))
  chain:draw()
end

return M
