local media      = require 'media'
local Game       = require 'Game'

require 'gamestates.play'

local game

function love.load()
  media.load()
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
