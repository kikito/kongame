local gamera     = require 'lib.gamera'
local shakycam   = require 'lib.shakycam'
local media      = require 'media'
local Map        = require 'map'

local updateRadius = 100 -- how "far away from the camera" things stop being updated
local drawDebug   = false  -- draw bump's debug info, fps and memory

local Play = {}

function Play:enteredState()
  local width, height = 4000, 2000
  local gamera_cam = gamera.new(0,0, width, height)
  self.camera = shakycam.new(gamera_cam)
  self.map    = Map:new(self, width, height, self.camera)
end

function Play:update(dt)
  self.map:update(dt)
  self.camera:setPosition(self.map.player:getCenter())
  self.camera:update(dt)
end

function Play:draw()
  self.camera:draw(function(l,t,w,h)
    self.map:draw(drawDebug, l,t,w,h)
  end)

  love.graphics.setColor(255, 255, 255)

  local w,h = love.graphics.getDimensions()

  if drawDebug then
    local statistics = ("fps: %d, mem: %dKB\n sfx: %d, items: %d"):format(love.timer.getFPS(), collectgarbage("count"), media.countInstances(), self.map:countItems())
    love.graphics.printf(statistics, w - 200, h - 40, 200, 'right')
  end
end

function Play:keypressed(k)
  if k=="escape" then self:gotoState('Start') end
  if k=="tab"    then drawDebug = not drawDebug end
  if k=="7"      then self:gotoState('Victory') end
  if k=="return" then
    self.map:reset()
  end
end

return Play


