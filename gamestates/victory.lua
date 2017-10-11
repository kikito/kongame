local media = require "media"

local Victory = {}

function Victory:draw()
  love.graphics.draw(media.img.victory)
end

function Victory:keypressed(k)
  self:gotoState('Start')
end

function Victory:update(dt)

end

return Victory
