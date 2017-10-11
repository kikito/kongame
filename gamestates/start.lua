local media = require "media"

local Start = {}

function Start:draw()
  love.graphics.draw(media.img.title)
end

function Start:keypressed(k)
  if k=="escape" then love.event.quit() end
  self:gotoState('Play')
end

function Start:update(dt)

end

return Start
