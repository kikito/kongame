--[[
-- Player Class
-- This entity collides "sliding" over walls and floors.
--
-- It also models flying (when at full health) and jumping (when not at full health).
--
-- Health continuously regenerates. The player can survive 1 hit from a grenade, but the second one needs to happen
-- at least 4 secons later. Otherwise they player will die.
--
-- The most interesting method is :update() - it's a high level description of how the player behaves
--
-- Players need to have a Map on their constructor because they will call map:reset() before dissapearing.
--
--]]
local class  = require 'lib.middleclass'
local util   = require 'util'
local media  = require 'media'

local Entity = require 'entities.entity'
local Debris = require 'entities.debris'
local Puff   = require 'entities.puff'

local Player = class('Player', Entity)
Player.static.updateOrder = 1


local deadDuration  = 3   -- seconds until res-pawn
local runAccel      = 500 -- the player acceleration while going left/right
local brakeAccel    = 2000
local jumpVelocity  = 400 -- the initial upwards velocity when jumping
local width         = 48
local height        = 42

local abs = math.abs

function Player:initialize(map, world, x,y)
  Entity.initialize(self, world, x, y, width, height)
  self.health = 1
  self.deadCounter = 0
  self.map = map
  self.facing = "left"
end

function Player:filter(other)
  local kind = other.class.name
  if kind == 'Guardian'
  or kind == 'Block' then
    return 'slide'
  end

  if kind == 'Lava'
  or kind == 'Pickup' then
    return 'cross'
  end
end

function Player:changeVelocityByKeys(dt)
  self.isJumpingOrFlying = false

  if self.isDead then return end

  local vx, vy = self.vx, self.vy

  if love.keyboard.isDown("left") then
    vx = vx - dt * (vx > 0 and brakeAccel or runAccel)
    self.facing = "left"
  elseif love.keyboard.isDown("right") then
    vx = vx + dt * (vx < 0 and brakeAccel or runAccel)
    self.facing = "right"
  else
    local brake = dt * (vx < 0 and brakeAccel or -brakeAccel)
    if math.abs(brake) > math.abs(vx) then
      vx = 0
    else
      vx = vx + brake
    end
  end

  if love.keyboard.isDown("up") and (self:canFly() or self.onGround) then -- jump/fly
    vy = -jumpVelocity
    self.isJumpingOrFlying = true
  end

  self.vx, self.vy = vx, vy
end

function Player:playEffects()
  if self.isJumpingOrFlying then
    if self.onGround then
      media.sfx.player_jump:play()
    else
      Puff:new(self.world,
               self.l,
               self.t + self.h / 2,
               20 * (1 - math.random()),
               50,
               2, 3)
      Puff:new(self.world,
               self.l + self.w,
               self.t + self.h / 2,
               20 * (1 - math.random()),
               50,
               2, 3)
      if media.sfx.player_propulsion:countPlayingInstances() == 0 then
        media.sfx.player_propulsion:play()
      end
    end
  else
    media.sfx.player_propulsion:stop()
  end

  if self.achievedFullHealth then
    media.sfx.player_full_health:play()
  end
end

function Player:checkIfOnGround(ny)
  if ny < 0 then self.onGround = true end
end

function Player:moveColliding(dt)
  self.onGround = false
  local world = self.world

  local future_l = self.l + self.vx * dt
  local future_t = self.t + self.vy * dt

  local next_l, next_t, cols, len = world:move(self, future_l, future_t, self.filter)

  for i=1, len do
    local col   = cols[i]
    local other = col.other
    local kind  = other.class.name
    if kind == "Guardian" or kind == "Block" then
      self:changeVelocityByCollisionNormal(col.normal.x, col.normal.y, bounciness)
      self:checkIfOnGround(col.normal.y)
    elseif kind == "Lava" and not self.isDead then
      self:die()
    elseif kind == "Pickup" then
      other:pickup()
    end
  end

  self.l, self.t = next_l, next_t
end

function Player:updateHealth(dt)
  self.achievedFullHealth = false
  if self.isDead then
    self.deadCounter = self.deadCounter + dt
    if self.deadCounter >= deadDuration then
      self.map:reset()
    end
  elseif self.health < 1 then
    self.health = math.min(1, self.health + dt / 6)
    self.achievedFullHealth = self.health == 1
  end
end

function Player:update(dt)
  self:updateHealth(dt)
  self:changeVelocityByKeys(dt)
  self:changeVelocityByGravity(dt)
  self:playEffects()

  self:moveColliding(dt)
end

function Player:takeHit()
  if self.isDead then return end
  self.health = self.health - 0.7
  if self.health <= 0 then
    self:die()
  end
end

function Player:die()
  media.music:stop()

  self.isDead = true
  self.health = 0
  for i=1,20 do
    Debris:new(self.world,
               math.random(self.l, self.l + self.w),
               math.random(self.t, self.t + self.h),
               255,0,0)
  end
  local cx,cy = self:getCenter()
  self.vx = math.random(-100, 100)
  self.vy = math.random(-100, 100)
end

function Player:getColor()
  local g = math.floor(255 * self.health)
  local r = 255 - g
  local b = 0
  return r,g,b
end

function Player:canFly()
  return self.health == 1
end

function Player:draw(drawDebug)
  love.graphics.setColor(self:getColor())

  if self.isDead then
    if self.facing == "left" then
      love.graphics.draw(media.img.kong, self.l+width, self.t+height, 0, -1, -1)
    else
      love.graphics.draw(media.img.kong, self.l, self.t+height, 0, 1, -1)
    end
  else
    if self.facing == "left" then
      love.graphics.draw(media.img.kong, self.l+width, self.t, 0, -1, 1)
    else
      love.graphics.draw(media.img.kong, self.l, self.t)
    end
  end

  if drawDebug then
    if self.onGround then
      util.drawFilledRectangle(self.l, self.t + self.h - 4, self.w, 4, 255,255,255)
    end
  end
end

return Player
