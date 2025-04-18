_G.love = love
_G.debug = false

_G.TestSplines = false
_G.TestChain = false
_G.TestFish = false

function love.load(arg)
  for _, v in pairs(arg) do
    if v == '--debug' or v == '--d' then
      _G.debug = true
    end
    if v == '--test-splines' then
      TestSplines = require 'test-splines'
      TestSplines:load()
    end
    if v == '--test-chain' then
      TestChain = require 'test-chain'
      TestChain:load()
    end
    if v == '--test-fish' then
      TestFish = require 'test-fish'
      TestFish:load()
    end
  end
end

function love.update(dt)
  if TestChain then
    TestChain:update(dt)
  end
  if TestFish then
    TestFish:update(dt)
  end
end

function love.draw()
  if TestSplines then
    TestSplines:draw()
  end
  if TestChain then
    TestChain:draw()
  end
  if TestFish then
    TestFish:draw()
  end
end
