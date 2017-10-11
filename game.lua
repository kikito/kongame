local class    = require 'lib.middleclass'
local Stateful = require 'lib.stateful'

local Start    = require 'gamestates.start'
local Play     = require 'gamestates.play'
local Victory  = require 'gamestates.victory'

local Game = class('Game'):include(Stateful)

function Game:initialize()
  self:gotoState("Start")
end

function Game:update(dt)
  error("override this")
end

function Game:draw()
  error("override this")
end

function Game:keypressed(k)
end

Game:addState('Start', Start)
Game:addState('Play',  Play)
Game:addState('Victory', Victory)

return Game
