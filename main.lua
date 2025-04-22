_G.love = love
_G.debug = false

_G.TestSplines = false
_G.TestChain = false
_G.TestFish = true
_G.TestLizard = false

function love.load(arg)
  for _, v in pairs(arg) do
    if v == '--debug' or v == '--d' then
      _G.debug = true
      TestFish = false
    end
    if v == '--test-splines' then
      TestSplines = require 'test-splines'
      TestSplines:load()
      TestFish = false
    end
    if v == '--test-chain' then
      TestChain = require 'test-chain'
      TestChain:load()
      TestFish = false
    end
    if TestFish or v == '--test-fish' then
      TestFish = require 'test-fish'
      TestFish:load()
    end
    if v == '--test-lizard' then
      TestLizard = require 'test-lizard'
      TestLizard:load()
      TestFish = false
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
  if TestLizard then
    TestLizard:update(dt)
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
  if TestLizard then
    TestLizard:draw()
  end
end
