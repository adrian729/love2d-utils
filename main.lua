_G.love = love
_G.debug = false
_G.Test = nil

local module_name = nil

function love.load(arg)
  for _, v in pairs(arg) do
    if v == '--debug' or v == '--d' then
      _G.debug = true
    end
    if string.find(v, '--test') then
      module_name = v:gsub('--test', 'test')
    end
  end

  if not module_name then
    print('Loading default')
    module_name = 'test-fish'
  end

  print('Loading module ' .. module_name)
  Test = require(module_name)
  Test:load()
end

function love.update(dt)
  if Test then
    Test:update(dt)
  end
end

function love.draw()
  if Test then
    Test:draw()
  end
end
