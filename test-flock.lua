local M = {}

local Flock = require 'flock'

local flock

function M:load()
  flock = Flock:new()
end

function M:update(dt)
  flock:update(dt)
end

function M:draw()
  flock:draw()
end

return M
