DialogBox = class('DialogBox')

DialogBox.press_button = love.graphics.newImage('sprites/press_button.png')

function DialogBox:initialize(message, speed, callback)
  self.message = message
  self.speed = speed or 30
  self.callback = callback
  self.display_len = 0
  self.old_display_len = 0
  self.z = 31
  self.finished = false
  self.btn_pressed = false
  gamestate = 'dialog'
end

function DialogBox:update(dt)
  if self.display_len <= self.message:len() then

    self.display_len = self.display_len + self.speed * dt

    if math.floor(self.display_len) > math.floor(self.old_display_len) then
      TEsound.play({sfx.type1, sfx.type2, sfx.type3})
      self.old_display_len = math.floor(self.display_len)
    end

    if controls.p1.cross or controls.p2.cross then
      if not self.btn_pressed then
        self.speed = 100
      end
      self.btn_pressed = true
    else
      self.speed = 30
      self.btn_pressed = false
    end

  else
    self.finished = true

    if controls.p1.cross or controls.p2.cross then
      if not self.btn_pressed then
        --self:destroy()
        self.callback()
      end
      self.btn_pressed = true
      if actors.list.oce  then actors.list.oce.jump_pressed = true end
      if actors.list.lolo then actors.list.lolo.jump_pressed = true end
    else
      self.btn_pressed = false
    end
  end
end

function DialogBox:draw()

  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.rectangle('fill', camera:ox() + 64*7, camera:oy() + 64*12 + 32, 64*14, 64*4)
  love.graphics.setLine(8, "smooth")
  love.graphics.setColor(0, 0, 255, 255)
  love.graphics.rectangle('line', camera:ox() + 64*7, camera:oy() + 64*12 + 32, 64*14, 64*4)

  love.graphics.setColor(37, 82, 113, 255)
  love.graphics.printf("LAURIANE:", camera:ox() + 64*8, camera:oy() + 64*13, 180*4, 'left')

  love.graphics.setColor(0, 0, 0, 255)
  local message = string.sub(self.message, 1, math.floor(self.display_len))
  love.graphics.printf(message, camera:ox() + 64*8, camera:oy() + 64*14, 180*4, 'left')
  
  love.graphics.setColor(255, 255, 255, 255)

  if self.finished then
    love.graphics.draw(DialogBox.press_button, camera:ox() + 64*19.5, camera:oy() + 64*15, 0, 1, 1, 0, 0)
  end
end

function DialogBox:destroy()
  actors.list.dialog = nil
  gamestate = 'play'
end