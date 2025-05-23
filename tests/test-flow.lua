local M = {}

local Flow = require 'flow'

local flow

local sliders = {
  scale = {
    key = 'scale',
    slider = { value = 10, min = 1, max = 50 },
    last_value = nil
  },
  noise = {
    key = 'noise',
    slider = { value = 2, min = 1, max = 10 },
    last_value = nil
  },
  noise_factor = {
    key = 'noise_factor',
    slider = { value = 100, min = 1, max = 1000, step = 10 },
    last_value = nil
  },
}

local slider_w = 200
local slider_h = 20
local label_w = 75

local variable_noise_checkbox = {
  checkbox = { text = 'variable noise' },
  last_value = nil
}

function M:load()
  flow = Flow:new({
    draw_opts = {
      mode = 'illustrate'
    }
  })
end

function M:update(dt)
  local vw = love.graphics.getWidth()

  local slider_x = vw - slider_w - label_w - 10
  Suit.layout:reset(slider_x, 64)

  local opts = nil
  Suit.Checkbox(
    variable_noise_checkbox.checkbox,
    { align = 'left' },
    Suit.layout:row(slider_w, slider_h)
  )
  for k, slider in pairs(sliders) do
    Suit.Label(
      k,
      { align = 'left' },
      Suit.layout:row(slider_w, slider_h)
    )
    local val = slider.slider.value
    local x, y, w, h = Suit.layout:row(slider_w, slider_h)
    Suit.Slider(slider.slider, x, y, w, h)
    Suit.Label(
      tostring(val),
      { align = 'left' },
      x + w + 5, y,
      label_w, h
    )

    if val ~= slider.last_value then
      opts = opts or {}
      if k == 'noise_factor' or k == 'noise' then
        opts['noise_scale'] = sliders.noise.slider.value / sliders.noise_factor.slider.value
      else
        opts[k] = val
      end
      slider.last_value = val
    end
  end

  if opts ~= nil then
    opts.variable_noise = variable_noise_checkbox.checkbox.checked
    flow:setOpts(opts)
  end

  flow:update(dt)
end

function M:draw()
  flow:draw()
end

return M
