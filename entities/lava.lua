local class = require 'lib.middleclass'

local Entity = require 'entities.entity'

local Lava = class('Lava', Entity)

local util = require 'util'

function Lava:initialize(world, l, t, w, h)
  Entity.initialize(self, world, l, t, w, h)
end

function Lava:update(dt)

end

function Lava:draw()
  util.drawFilledRectangle(self.l, self.t, self.w, self.h, 255,0,0)
end

return Lava
