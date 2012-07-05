class "Crab" {}

Crab.img = {}
Crab.img.stand = {}
Crab.img.stand.left = love.graphics.newImage('sprites/crab_stand_left.png')
Crab.img.stand.left:setFilter("nearest", "nearest")
Crab.img.stand.right = love.graphics.newImage('sprites/crab_stand_right.png')
Crab.img.stand.right:setFilter("nearest", "nearest")

function Crab:__init(w, x, y, z)
  self.w = w
  self.x = x
  self.y = y
  self.z = z

  self.body = Collider:addPolygon(0,16, 32,16, 32,32, 0,32)
  self.body.parent = self

  self.gravity = 500

  self.xspeed = 0.5
  self.yspeed = 0.0

  self.stance = 'stand'
  self.direction = 'left'
  self.animation = Crab.img[self.stance][self.direction]

  self.onground = false

  self.cron = require 'libs/cron'
end

function Crab:update(dt)
  self.cron.update(dt)

  if self.direction == 'left'  then self.x = self.x - self.xspeed end
  if self.direction == 'right' then self.x = self.x + self.xspeed end

  self.body:moveTo(self.x, self.y)
end

function Crab:draw()
  love.graphics.draw(Crab.img[self.stance][self.direction], self.x, self.y, 0, 1, 1, 16, 24)
end

function Crab:onCollision(dt, other, dx, dy)
  if other.parent.w ~= nil and other.parent.w ~= self.w and self.w ~= nil then return end
  if other.type == 'Wall' then
    if dx < -1 then
      self.x = self.x - dx
      self.direction = 'right'
    elseif dx >  1 then
      self.x = self.x - dx
      self.direction = 'left'
    end
    if dy < -1 then
      self.y = self.y - dy
      self.yspeed = 0
    elseif dy > 1 then
      self.y = self.y - dy
      self.onground = true
      self.yspeed = 0
    end
  elseif other.type == 'Player' then
    self.xspeed = 0
    print(self.xspeed)
    self.cron.after(1, function() self.xspeed = 0.5 end) 
  end
end

function Crab:onCollisionStop(dt, other, dx, dy)
  if other.parent.w ~= nil and other.parent.w ~= self.w then return end
  if other.type == 'Wall' then
    if dy >  0.01 then self.onground = false end
  end
end