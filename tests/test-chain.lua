local M = {}

local Chain = require 'chain'
local Joint = require 'joint'
local Vec2 = require 'vec2'

local chain_anchored, chain, default_chain

function M:load()
  local vw = love.graphics.getWidth()
  local vh = love.graphics.getHeight()

  local anchor = Vec2:new(vw / 2, vh - 10)
  local joints = {}
  for i = 10, 100, 10 do
    for _ = 1, 100 / i, 1 do
      table.insert(
        joints,
        Joint:new({
          link_size = i / 2,
          angle_constraint = math.pi / 8
        })
      )
    end
  end
  local target = nil
  chain_anchored = Chain:new({
    joints = joints,
    anchor = anchor,
    target = target
  })

  joints = {}
  for _ = 1, 15, 1 do
    table.insert(
      joints,
      Joint:new({
        link_size = 25,
        angle_constraint = math.pi / 3
      })
    )
  end
  chain = Chain:new({ joints = joints, target = target })

  default_chain = Chain:new()
  default_chain:setScale(10)
end

function M:update(dt)
  local mouse = Vec2:new(love.mouse.getPosition())

  chain_anchored.target = mouse
  chain_anchored:update(dt)

  chain.target = mouse
  chain:update(dt)

  default_chain.target = mouse
  default_chain:update(dt)
end

function M:draw()
  chain_anchored:draw()
  chain:draw()
  default_chain:draw()
end

return M
