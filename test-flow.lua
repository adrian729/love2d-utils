local M = {}

local Flow = require 'flow'

local flow

function M:load()
  flow = Flow:new({
    draw_opts = {
      mode = 'illustrate'
    }
  })
end

function M:update(_dt)
end

function M:draw()
  flow:draw()
end

return M
