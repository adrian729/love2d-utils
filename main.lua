_G.love = love
_G.debug = false
_G.Test = require 'tests'

_G.Lick = require 'lick'
Lick.reset = true

_G.Suit = require 'suit'


local test = Test:new()

function love.load(arg)
  arg = arg or {}

  local module_name = nil
  for _, v in pairs(arg) do
    if v == '--debug' or v == '--d' then
      _G.debug = true
    end
    if string.find(v, '--test') then
      module_name = v:gsub('--test', 'test')
    end
  end

  test = Test:new(module_name)

  local font = love.graphics.newFont("NotoSansHans-Regular.otf", 20)
  love.graphics.setFont(font)
end

function love.update(dt)
  local vw = love.graphics.getWidth()
  Suit.layout:reset(vw - 210, 5)
  if Suit.Button("Close", Suit.layout:row(200, 32)).hit then
    love.event.quit()
  end

  if test then
    test:update(dt)
  end
end

function love.draw()
  if test then
    test:draw()
  end
  Suit.draw()
end

function love.textedited(text, start, length)
  Suit.textedited(text, start, length)
end

function love.textinput(t)
  Suit.textinput(t)
end

function love.keypressed(key)
  Suit.keypressed(key)
end
