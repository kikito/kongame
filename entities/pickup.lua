local class = require 'lib.middleclass'

local media = require 'media'
local Entity = require 'entities.entity'
local Debris = require 'entities.debris'

local Pickup = class('Pickup', Entity)

Pickup.static.updateOrder = 2

local size = 23

function Pickup:initialize(map,world, l, t, img)
  Entity.initialize(self, world, l, t, size, size)

  self.map = map
  self.initial_t = t
  self.img = img
  self.accumulator = 0

  -- remove any blocks it touches on creation
  local others, len = world:queryRect(l-50,t-50,size + 100, size+100)
  local other
  for i=1,len do
    other = others[i]
    if other ~= self then
      world:remove(other)
    end
  end
end

function Pickup:update(dt)
  if self.world:hasItem(self) then
    self.accumulator = self.accumulator + dt
    self.t = self.initial_t + math.sin(self.accumulator) * size / 3
    self.world:update(self, self.l, self.t)
  end
end

function Pickup:draw()
  love.graphics.setColor(255, 255, 0)
  love.graphics.draw(self.img, self.l, self.t)
end

function Pickup:pickup()
  self.world:remove(self)
  for i=1,3 do
    Debris:new(self.world,
               math.random(self.l, self.l + self.w),
               math.random(self.t, self.t + self.h),
               255,255,0)
  end
  media.sfx.pickup:play()
  self.map:pickup()
end



return Pickup
