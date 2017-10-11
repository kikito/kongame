local Start = {}

function Start:draw()
  love.graphics.printf("Press any key to begin", 0, 300, 800, 'center')
end

function Start:keypressed(k)
  if k=="escape" then love.event.quit() end
  self:gotoState('Play')
end

function Start:update(dt)

end

return Start
