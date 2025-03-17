_G.debug = false
_G.love = love

_G.TestSplines = false

function love.load(arg, _unfilteredArg)
  for _, v in pairs(arg) do
    if v == '--debug' or v == '--d' then
      _G.debug = true
    end

    if v == '--test-splines' then
      TestSplines = require 'test-splines'
      TestSplines.load()
    end
  end
end

function love.update(_dt)
end

function love.draw()
  if TestSplines then
    TestSplines.draw()
  end
end
