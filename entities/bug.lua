local class = require 'lib.middleclass'

local Entity = require 'entities.entity'
local Explosion = require 'entities.explosion'
local media = require 'media'
local util = require 'util'

local Bug = class('Bug', Entity)

Bug.static.updateOrder = 10

local width = 30
local height = 30
local activeRadius  = 500
local fireCoolDown  = 0.75 -- how much time the guardian takes to "regenerate a grenade"
local targetCoolDown = 2 -- minimum time between "target acquired" chirps
local acceleration = 300 -- pixels per second per second
local proximity = 100 -- how near its center needs to be to the center of the target to explode


function Bug:initialize(world, target, camera, x, y)
  Entity.initialize(self, world, x, y, width, height)
  self.target = target
  self.camera = camera
  self.timeSinceLastTargetAquired = targetCoolDown
  self.vx = 0
  self.vy = 0

  -- remove any blocks it touches on creation
  local others, len = world:queryRect(x,y,width,height)
  local other, kind
  for i=1,len do
    other = others[i]
    kind = other.class.name
    if kind == "Block" or kind == "Lava" then world:remove(other) end
  end
end

function Bug:destroy()
  if self.isDead then return end
  self.isDead = true
  Entity.destroy(self)
  Explosion:new(self.world, self.camera, self:getCenter())
end

function Bug:filter(other)
  local kind = other.class.name
  if kind == 'Block'
  or kind == 'Player'
  or kind == 'Lava'
  or kind == 'Guardian'
  then
    return "slide"
  end
end

function Bug:checkProximityToTarget()
  local cx,cy = self:getCenter()
  local tx,ty = self.target:getCenter()

  local dx,dy = tx-cx, ty-cy
  local distance2 = dx*dx + dy*dy

  if distance2 <= proximity * proximity then
    self:destroy()
  end
end

function Bug:acquireTarget()
  self.isNearTarget  = false
  self.targetAquired = false

  local cx,cy = self:getCenter()
  local tx,ty = self.target:getCenter()

  local dx,dy = tx-cx, ty-cy
  local distance2 = dx*dx + dy*dy

  if distance2 <= activeRadius * activeRadius then
    self.isNearTarget = true

    local itemInfo, len = self.world:querySegmentWithCoords(cx,cy,tx,ty)
    -- ignore itemsInfo[1] because that's always self
    local info = itemInfo[2]
    if info then
      self.laserX = info.x1
      self.laserY = info.y1
      if info.item == self.target then
        self.targetAquired = true
        if self.timeSinceLastTargetAquired >= targetCoolDown then
          media.sfx.guardian_target_acquired:play()
          self.timeSinceLastTargetAquired = 0
        end
      end
    end
  end
end

function Bug:changeVelocityByTarget(dt)
  if self.targetAquired then
    local cx,cy = self:getCenter()
    local tx,ty = self.target:getCenter()

    local dx,dy = tx-cx, ty-cy
    local mx, my = 0,0
    local d = math.sqrt(dx*dx + dy*dy)
    if d > 0 then
      mx, my = dx/d, dy/d
    end

    self.vx = self.vx + mx * acceleration * dt
    self.vy = self.vy + my * acceleration * dt
  else
    local mx, my = 0,0
    local v = math.sqrt(self.vx * self.vx + self.vy * self.vy)
    if v > 0 then
      mx, my = -self.vx/v, -self.vy/v
    end


    self.vx = self.vx + mx * acceleration/2 * dt
    self.vy = self.vy + my * acceleration/2 * dt
  end
end

function Bug:moveColliding(dt)
  local world = self.world

  local future_l = self.l + self.vx * dt
  local future_t = self.t + self.vy * dt

  local next_l, next_t, cols, len = world:move(self, future_l, future_t, self.filter)

  for i=1, len do
    local col   = cols[i]
    local other = col.other
    local kind  = other.class.name
    if kind == "Guardian" or kind == "Block" then
      self:changeVelocityByCollisionNormal(col)
    elseif kind == "Lava" then
      self:destroy()
    end
  end

  self.l, self.t = next_l, next_t
end

function Bug:changeVelocityByCollisionNormal(col)
  local other, normal = col.other, col.normal
  local nx, ny        = normal.x, normal.y
  local vx, vy        = self.vx, self.vy

  if (nx < 0 and vx > 0) or (nx > 0 and vx < 0) then
    self.vx = other.vx
  end

  if (ny < 0 and vy > 0) or (ny > 0 and vy < 0) then
    self.vy = math.max(0, other.vy)
  end
end

function Bug:update(dt)
  if self.isDead then return end
  self:checkProximityToTarget()
  if self.isDead then return end
  self:acquireTarget()
  self:changeVelocityByTarget(dt)
  self:moveColliding(dt)
end

function Bug:draw()
  local cx,cy = self:getCenter()
  local tcx, tcy = self.target:getCenter()

  love.graphics.line(cx, cy, tcx, tcy)

  if self.targetAquired then
    util.drawFilledCircle(cx, cy, width/2, 255,0,0, 7)
  else
    util.drawFilledCircle(cx, cy, width/2, 0,100,200, 7)
  end

  if self.isNearTarget then
    if self.targetAquired then
      love.graphics.setColor(255,100,100,200)
    else
      love.graphics.setColor(0,100,200,100)
    end

    love.graphics.setLineWidth(2)
    love.graphics.line(cx, cy, self.laserX, self.laserY)
    love.graphics.setLineWidth(1)
  end
end

return Bug

