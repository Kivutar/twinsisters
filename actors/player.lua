Player = class('Player')
Player:include(Gravity)
Player:include(Blinking)

Player.anim = {}
for _,skin in pairs({'lolo', 'oce'}) do
  Player.anim[skin] = {}
  for stance, speed in pairs({stand=1, sword=(0.5/8), run=0.2, jump=0.1, fall=0.1, swim=0.2, hit=1, surf=1}) do
    Player.anim[skin][stance] = {}
    for _,direction in pairs({'left', 'right'}) do
      img = love.graphics.newImage('sprites/'..skin..'_'..stance..'_'..direction..'.png')
      Player.anim[skin][stance][direction] = newAnimation(img , 256, 256, speed, 0)
    end
  end
end

function Player:initialize(x, y, z, properties)
  self.name = properties.name or 'lolo'
  self.skin = properties.skin or 'lolo'
  self.x = x + 32
  self.y = y + 16
  self.z = 30

  self.persistant = true

  self.type = "Player"

  self.body = Collider:addPolygon(-16,-48, -16,48, 16,48, 16,-48)
  self.body.parent = self
  self.feet = Collider:addPolygon(-15,0, 15,0, 15,1, -15,1)
  self.feet.parent = self
  self.left = Collider:addPolygon(0,-20, 0,20, 1,20, 1,-20)
  self.left.parent = self
  self.right = Collider:addPolygon(0,-20, 0,20, 1,20, 1,-20)
  self.right.parent = self
  self.underfeet = Collider:addPolygon(-15,0, 15,0, 15,8, -15,8)
  self.underfeet.parent = self

  self.xspeed = 0
  self.max_xspeed = 100*4
  self.yspeed = 0
  self.jumpspeed = 200*4
  self.friction = 750*4
  self.airfriction = 75*4*0
  self.acceleration = 200
  self.groundspeed = 0
  self.iwf = 1

  self.stance = 'stand'
  self.direction = 'left'
  self.animation = Player.anim[self.skin][self.stance][self.direction]

  self.ondoor = false
  self.onground = false
  self.onbridge = false
  self.onice = false
  self.inwater = false
  self.daft = false
  self.invincible = false
  self.swimming = false
  self.attacking = false

  self.jump_pressed = true
  self.switch_pressed = true
  self.open_pressed = true
  self.sword_pressed = true
  self.fire_pressed = true

  self.maxHP = 6*4
  self.HP = self.maxHP

  self.portrait = love.graphics.newImage('sprites/'..self.skin..'_portrait.png')

  if self.name == 'lolo' then self.controls = controls.p1 else self.controls = controls.p2 end
end

function Player:applyFriction(dt)
  local f = 0
  if self.onground then f = self.friction else f = self.airfriction end
  if self.xspeed > 0 then
    self.xspeed = self.xspeed - f * dt
    if self.xspeed < 0 then self.xspeed = 0 end
  elseif
    self.xspeed < 0 then self.xspeed = self.xspeed + f * dt
    if self.xspeed > 0 then self.xspeed = 0 end
  end
end

function Player:update(dt)
  if self.name == 'lolo' then self.controls = controls.p1 else self.controls = controls.p2 end

  self.ondoor = false
  self.onground = false
  self.onbridge = false
  self.inwater  = false
  self.onice = false
  for _,n in pairs(self.body:neighbors()) do
    collides, dx, dy = self.body:collidesWith(n)
    if n.parent.class.name == 'Water' then
      self.inwater = true
    end
    if n.parent.class.name == 'Door' then
      self.ondoor = n.parent
    end
  end

  for _,n in pairs(Collider:shapesInRange(self.x-38,self.y-50, self.x+38,self.y+50)) do

    if n:collidesWith(self.underfeet) then
      if n.parent.class.name == 'Wall'
        or n.parent.class.name == 'Bridge'
        or n.parent.class.name == 'Slant'
        or n.parent.class.name == 'Ice'
        or n.parent.class.name == 'FlyingWall' then

          x, y = self.body:center()
          self.body:moveTo(x, y + 8)
          self.y = self.y + 8

          collides, dx, dy = n:collidesWith(self.body)

          if n:collidesWith(self.body) then
            if n.parent.class.name == 'Wall'
            or n.parent.class.name == 'Bridge'
            or n.parent.class.name == 'Slant'
            or n.parent.class.name == 'Ice'
            or n.parent.class.name == 'FlyingWall' then
              self.onground = true
              self.swimming = false
              self.yspeed = 0
              
              self.body:moveTo(x, y + 8 - dy)
              self.y = self.y - dy
            end
          end
      end
    end

    collides, dx, dy = n:collidesWith(self.body)

    if n:collidesWith(self.feet) then
      if n.parent.class.name == 'Wall'
      or n.parent.class.name == 'Bridge'
      or n.parent.class.name == 'Slant'
      or n.parent.class.name == 'Ice'
      or n.parent.class.name == 'FlyingWall' then
        self.onground = true
        self.swimming = false
        self.yspeed = 0
        self.y = self.y - dy
      end
      if n.parent.class.name == 'Bridge' then
        self.onbridge = true
      end
      if n.parent.class.name == 'Ice' then
        self.onice = true
      end
    end

    if n:collidesWith(self.left) or n:collidesWith(self.right) then
      if n.parent.class.name == 'Wall' then
        self.xspeed = 0
        self.x = self.x - dx
      end
    end

  end

  self.iwf = self.inwater and 0.5 or 1

  if self.onice then
    self.friction = 0
    self.max_xspeed = 200*4
  else
    self.friction = 750*4
    self.max_xspeed = 100*4
  end

  -- Moving on x axis
  -- Moving right
  if self.controls.right and not self.daft then
    if not (self.direction == 'left' and self.attacking) then
      self.direction = 'right'
      self.stance = 'run'
      if self.xspeed < 0 and not self.onice then self.xspeed = 0 end
      self.xspeed = self.xspeed + self.acceleration * dt * self.iwf
    end
  -- Moving left
  elseif self.controls.left and not self.daft then
    if not (self.direction == 'right' and self.attacking) then
      self.direction = 'left'
      self.stance = 'run'
      if self.xspeed > 0 and not self.onice then self.xspeed = 0 end
      self.xspeed = self.xspeed - self.acceleration * dt * self.iwf
    end
  -- Stop moving
  else
    self:applyFriction(dt)
    self.stance = 'stand'
  end
  -- Apply friction if the character is attacking and on ground
  if self.attacking and self.onground then self:applyFriction(dt) end
  -- Apply maximum xspeed
  if math.abs(self.xspeed) > self.max_xspeed * self.iwf then self.xspeed = sign(self.xspeed) * self.max_xspeed * self.iwf end
  self.x = self.x + (self.xspeed + self.groundspeed) * dt * self.iwf

  -- Jumping and swimming
  if self.controls.cross and not self.daft then
    if not self.jump_pressed then
      -- Jump from bridge
      if self.onbridge and self.controls.down then
        self.y = self.y + 20*4
        TEsound.play(sfx.jump)
      -- Regular jump
      elseif self.onground and not self.controls.down and not self.attacking then
        self.yspeed = - self.jumpspeed -- - math.abs(self.xspeed*30*self.iwf)
        TEsound.play(sfx.jump)
      -- Swimming
      elseif self.inwater then
        self.swimming = true
        self.yspeed = - self.jumpspeed * self.iwf
      end
    end
    self.jump_pressed = true
  else
    self.jump_pressed = false
  end

  -- Attacking
  if self.controls.circle and not self.daft then
    if not self.sword_pressed then
      if not self.attacking then
        self.attacking = true
        TEsound.play(sfx.sword2)
        local name = 'sword_'..self.name
        actors.list[name] = Sword:new(self)
        actors.list[name].type = 'Sword'
        actors.list[name].name = name
        CRON.after(0.25, function()
          self.attacking = false
          actors.list[name]:destroy()
        end)
      end
    end
    self.sword_pressed = true
  else
    self.sword_pressed = false
  end

  -- Fire
  --if self.fire_btn() and not self.daft then
  --  if not self.fire_pressed then
  --    if not self.attacking then
  --      self.attacking = true
  --      TEsound.play('sounds/shoot.wav')
  --      local name = 'Bullet_'..self.name..'_'..love.timer.getTime()
  --      actors.list[name] = Bullet:new(self)
  --      actors.list[name].type = 'Bullet'
  --      actors.list[name].name = name
  --      CRON.after(0.25, function() self.attacking = false end)
  --    end
  --  end
  --  self.fire_pressed = true
  --else
  --  self.fire_pressed = false
  --end

  -- Openning doors
  if self.controls.up and self.ondoor and self.onground and not self.daft then
    if not self.open_pressed then
      if self.ondoor.locked then
        actors.list.dialog = DialogBox:new("This door is locked!\nLet's see if we can find a key...", 30, function ()
          actors.list.dialog = DialogBox:new("Or maybe I should wait for something else to happen.", 30, DialogBox.destroy)
        end)
      else
        TEsound.play(sfx.door)
        map = ATL.load(self.ondoor.map..'.tmx')
        map.drawObjects = false
        love.graphics.setBackgroundColor(map.properties.r or 0, map.properties.g or 0, map.properties.b or 0)
        for k,o in pairs(actors.list) do
          if not o.persistant then
            if o.body then Collider:remove(o.body) end
            actors.list[k] = nil
          end
        end
        self.x = self.ondoor.tx*16*4
        self.y = self.ondoor.ty*16*4+8*4
        actors.addFromTiled(map.ol)
        camera:setScale(1)
        camera:follow({self}, 1)
      end
    end
      self.open_pressed = true
    else
      self.open_pressed = false
  end

  if not self.onground then self:applyGravity(dt) end

  local iwf = self.iwf or 1 -- In water factor
  local max_yspeed = self.max_yspeed or 200*4
  if self.yspeed > max_yspeed * iwf then self.yspeed = max_yspeed * iwf end
  self.y = self.y + self.yspeed * dt * iwf

  self:applyBlinking()

  self.body:moveTo(self.x, self.y)
  self.feet:moveTo(self.x, self.y+48)
  self.left:moveTo(self.x-16, self.y)
  self.right:moveTo(self.x+16, self.y)
  self.underfeet:moveTo(self.x, self.y+48+4)
  self.animation:update(dt)
end

function Player:draw()
  self:blinkingPreDraw()
  -- Choose the character stance to display
  if self.yspeed > 0 then self.stance = 'fall' end
  if self.yspeed < 0 then self.stance = 'jump' end
  if not self.controls.right and not self.controls.left and self.xspeed ~= 0 and self.onice then self.stance = 'surf' end
  if self.inwater and not self.onground and self.swimming then self.stance = 'swim' end
  if self.attacking then self.stance = 'sword' end
  if self.daft then self.stance = 'hit' end
  -- Set the new animation do display, but prevent animation self overriding
  self.nextanim = Player.anim[self.skin][self.stance][self.direction]
  if self.animation ~= self.nextanim then
    self.animation = self.nextanim
    self.animation:seek(1)
  end
  -- Draw the animation
  self.animation:draw(self.x-32*4, self.y-20*4-32*4)
  self:blinkingPostDraw()

  love.graphics.setColor(255,   0, 255, 128)
  self.body:draw('fill')
  love.graphics.setColor(  0, 255, 255, 128)
  self.feet:draw('fill')
  self.left:draw('fill')
  self.right:draw('fill')
  love.graphics.setColor(  0, 0, 255, 128)
  self.underfeet:draw('fill')
  love.graphics.setColor(255, 255, 255, 255)
end

function Player:drawhallo()
  r = math.random(0, 3)
  --love.graphics.setColor(128, 128, 128, 128)
  --love.graphics.circle("fill", self.x, self.y, 200 + r)
  --love.graphics.setColor(255, 255, 255)
  --love.graphics.circle("fill", self.x, self.y, 150 + r)
  love.graphics.draw(hallo, self.x, self.y, 0, 1+r/100, 1+r/100, 256, 256)
end

function Player:onCollision(dt, shape, dx, dy)
  -- Get the other shape parent (its game object)
  local o = shape.parent

  ---- Collision with Wall or FlyingWall or Ice
  if o.class.name == 'Wall' or o.class.name == 'FlyingWall' or o.class.name == 'Ice' then
  --  if dx ~= 0 and sign(self.xspeed) == sign(dx) then self.xspeed = 0 end
  --  if dy ~= 0 and sign(self.yspeed) == sign(dy) then self.yspeed = 0 end
  --  self.x, self.y = self.x - dx, self.y - dy
--
  ---- Collision with Slant
  --elseif o.class.name == 'Slant' then
  -- --if self.yspeed > 0 then self.yspeed = 0 end
  -- --self.y = self.y - dy
  -- --if dx ~= 0 then
  -- --  self.x = self.x - dx
  -- --  --if (dx < 1 or dx > 1) and sign(self.xspeed) == sign(dx) then self.xspeed = 0 end
  -- --end
  --  if dx ~= 0 and sign(self.xspeed) == sign(dx) then self.xspeed = 0 end
  --  if dy ~= 0 and sign(self.yspeed) == sign(dy) then self.yspeed = 0 end
  --  self.x, self.y = self.x - dx, self.y - dy

  -- Collision with Bridge
  elseif o.class.name == 'Bridge' then
    if dy > 0 and self.yspeed > 0 then
      self.yspeed = 0
      self.y = self.y - dy - math.abs(dx)
      self.x = self.x - dx
    end

  -- Collision with Gap
  elseif o.class.name == 'Gap' then
    if o.newx  ~= nil then self.x = o.newx*64 end
    if o.newy  ~= nil then self.y = o.newy*64 end
    if o.plusx ~= nil then self.x = self.x + o.plusx*64 end
    if o.plusy ~= nil then self.y = self.y + o.plusy*64 end
    actors.switchMap(o.target)

  -- Collision with Arrow
  elseif o.class.name == 'Arrow' then
    self.x, self.y = self.x - dx, self.y - dy
    if dy > 0 and self.yspeed > 0 then
      TEsound.play(sfx.arrow)
      self.yspeed = - 1.75 * self.jumpspeed
    end
    if dx ~= 0 and sign(self.xspeed) == sign(dx) then self.xspeed = 0 end
    if dy ~= 0 and sign(self.yspeed) == sign(dy) then self.yspeed = 0 end

  -- Collision with an enemy
  elseif (o.class.name == 'Crab'
       or o.class.name == 'UpDownSpike'
       or o.class.name == 'Spike'
       or o.class.name == 'AcidDrop')
  and not self.invincible then
    if not o.HP or o.HP > 0 then
      self.HP = self.HP - 1
      if self.HP <= 0 then
        TEsound.play(sfx.die)
        self.daft = true
        self.invincible = true
        self.stance = 'hit'
        CRON.after(1, function()
          --actors.list[self.name] = nil
          --Collider:remove(self.body)
          --Player.instances = Player.instances - 1
        end)
      else
        TEsound.play(sfx.hit)
        if dx < -0.1 then self.xspeed = 3 elseif dx > 0.1 then self.xspeed = -3 end
        self.yspeed = -50
        self.invincible = true
        self.daft = true
        CRON.after(0.5, function() self.daft = false end)
        CRON.after(2  , function() self.invincible = false end)
      end
    end

  end
end
