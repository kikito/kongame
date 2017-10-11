local class  = require 'lib.middleclass'
local util   = require 'util'

local Entity = require 'entities.entity'

local Platform = class('Platform', Entity)
Platform.static.updateOrder = 0

local width = 64
local height = 16
local speed = 40

local function checkWaypoints(waypoints)
  assert(type(waypoints) == 'table', 'waypoints must be a table')
  assert(#waypoints > 1, "must have at least 2 waypoints")
  for i=1, #waypoints do
    local p = waypoints[i]
    assert(type(p) == 'table' and type(p.x) == 'number' and type(p.y) == 'number',
      "waypoints must be a table in the form {{x=0,y=0},{x=100,y=200}, ... }")
  end
end

local function getDiffVectorToNextWaypoint(self)
  local nextWaypoint = self.waypoints[self.nextWaypointIndex]
  local x,y          = self:getCenter()
  local nx, ny       = nextWaypoint.x, nextWaypoint.y
  return nx-x, ny-y
end

local function getDistanceToNextWaypoint(self)
  local dx,dy = getDiffVectorToNextWaypoint(self)
  return math.sqrt(dx*dx + dy*dy)
end

local function gotoNextWaypoint(self)
  local p = self.waypoints[self.nextWaypointIndex]
  self.l, self.t = p.x - self.w / 2, p.y - self.h / 2

  if self.nextWaypointIndex == #self.waypoints then
    self.direction = -1
  elseif self.nextWaypointIndex == 1 then
    self.direction = 1
  end

  self.nextWaypointIndex = self.nextWaypointIndex + self.direction
end

local function advanceTowardsNextWaypoint(self, advance)
  local distanceToNext = getDistanceToNextWaypoint(self)
  local dx,dy = getDiffVectorToNextWaypoint(self)
  local mx,my = (dx / distanceToNext) * advance, (dy / distanceToNext) * advance

  self.l, self.t = self.l + mx, self.t + my
end




function Platform:initialize(world, waypoints)
  checkWaypoints(waypoints)

  Entity.initialize(self, world, 0, 0, width, height)

  self.waypoints = waypoints
  self.nextWaypointIndex = 1
  self.prevX, self.prevY = 0,0
  self.direction         = 1 -- 1 = forwards, -1 = backwards

  gotoNextWaypoint(self)
  self.world:update(self, self.l, self.t)
end

function Platform:filter(other)
  if other.class.name == 'Player' and self.prevY >= other.l + other.h then
    return 'cross'
  end
end

function Platform:update(dt)
  self.prevX, self.prevY = self.l, self.t

  local advance = speed * dt

  local distanceToNext = getDistanceToNextWaypoint(self)

  while distanceToNext > 0 and advance > distanceToNext do
    advance = advance - distanceToNext
    gotoNextWaypoint(self)
    distanceToNext = getDistanceToNextWaypoint(self)
  end

  advanceTowardsNextWaypoint(self, advance)

  local _,_, cols, len = self.world:move(self, self.l, self.t, self.filter)

  local dx, dy     = self.l - self.prevX, self.t - self.prevY
  self.vx, self.vy = dx/dt, dy/dt

  for i=1,len do
    local col = cols[i]
    if col.normal.y > 0 then
      col.other:setGround(self)
    end
  end
end

function Platform:draw(drawDebug)
  love.graphics.setColor(0,200,200)

  local start = self.waypoints[1]
  local finish = self.waypoints[#self.waypoints]
  love.graphics.circle('line', start.x, start.y, 5)
  love.graphics.circle('fill', finish.x, finish.y, 5)

  love.graphics.line(self:getPointCoords())

  if drawDebug then
    love.graphics.setColor(200,200,200)
    local p = self.waypoints[self.nextWaypointIndex]
    love.graphics.rectangle('line', p.x - 8, p.y - 8, 16, 16)

    local cx, cy = self:getCenter()
    love.graphics.circle('line', cx, cy, 3)
  end

  util.drawFilledRectangle(self.l, self.t, self.w, self.h, 220, 220, 0)
end

function Platform:getPointCoords()
  local coords = {}
  for i=1, #self.waypoints do
    local p = self.waypoints[i]
    coords[i*2 - 1] = p.x
    coords[i*2]     = p.y
  end
  return coords
end

return Platform
