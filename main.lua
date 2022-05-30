local media      = require 'media'
local Game       = require 'game'

require 'gamestates.play'

local game

function love.load()
  media.load()
  love.graphics.setBackgroundColor(9/255, 46/255, 78/255)
  game = Game:new()
end

-- Updating
function love.update(dt)
  media.cleanup()
  game:update(dt)
end

-- Drawing
function love.draw()
  game:draw()
end

function love.keypressed(k)
  game:keypressed(k)
end
