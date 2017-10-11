local Victory = {}

function Victory:draw()
  love.graphics.printf("You won! You are kongtastic!", 0, 300, 800, 'center')
end

function Victory:keypressed(k)
  self:gotoState('Start')
end

function Victory:update(dt)

end

return Victory
