keyboard = nil
scene = nil

function newKeyboard()
  local keyboard = {}
  keyboard.a = function()
    return love.keyboard.isDown("z")
  end
  keyboard.up = function()
    return love.keyboard.isDown("up")
  end
  keyboard.down = function()
    return love.keyboard.isDown("down")
  end
  keyboard.left = function()
    return love.keyboard.isDown("left")
  end
  keyboard.right = function()
    return love.keyboard.isDown("right")
  end
  return keyboard
end

function newBall(owner)
  local ball = {}
  ball.ADD_SPEED = 0.02
  ball.owner = owner
  ball.position = {}
  ball.position.x = owner.position.x
  ball.position.y = owner.position.y
  ball.speed = owner.speed + ball.ADD_SPEED
  ball.update = function(self, dt)
    self.position.y = self.position.y + self.speed
    return self
  end
  ball.draw = function(self, mainGame)
    love.graphics.setColor(255, 255, 255)
    love.graphics.circle(
      "fill",
      math.floor(self.position.x*mainGame.WIDTH),
      math.floor((self.position.y - mainGame.camera + mainGame.BACK_SPACE)*mainGame.WIDTH),
      math.floor(0.02*mainGame.WIDTH)
    )
  end
  return ball
end

function newPlayer()
  local player = {}
  player.position = {}
  player.position.x = 0.3
  player.position.y = 0.5
  player.speed = 0
  player.reload = 0
  player.accel = function(self, high, mainGame)
    local max = mainGame.STANDARD_SPEED
    if high then
      max = mainGame.MAX_SPEED
    end
    if self.speed < max then
      local t = -math.log(1 - self.speed/max)/mainGame.TIME_RATE
      self.speed = max*(-math.exp(-mainGame.TIME_RATE*(t+1)) + 1)
    else
      self.speed = self.speed - mainGame.DECELERATION
      if self.speed < mainGame.STANDARD_SPEED then
        self.speed = mainGame.STANDARD_SPEED
      end
    end
  end
  player.brake = function(self, mainGame)
    self.speed = self.speed - mainGame.BRAKE
    if self.speed < 0 then
      self.speed = 0
    end
  end
  player.update = function(self, dt, mainGame)
    if keyboard.up() then
      self:brake(mainGame)
    else
      local curve = false
      if keyboard.left() then
        self.position.x = self.position.x - self.speed * mainGame.CURVE_RATE
        curve = true
      end
      if keyboard.right() then
        self.position.x = self.position.x + self.speed * mainGame.CURVE_RATE
        curve = true
      end
      self:accel(not curve and keyboard.down(), mainGame)
    end
    self.position.y = self.position.y + self.speed
    if self.reload == 0 and keyboard.a() then
      table.insert(mainGame.balls, newBall(self))
      self.reload = 15
    end
    if self.reload > 0 then
      self.reload = self.reload - 1
    end
    return self
  end
  player.draw = function(self, mainGame)
    love.graphics.setColor(128, 255, 128)
    love.graphics.circle(
      "fill", 
      math.floor(self.position.x*mainGame.WIDTH), 
      math.floor((self.position.y - mainGame.camera + mainGame.BACK_SPACE)*mainGame.WIDTH), 
      math.floor(0.05*mainGame.WIDTH)
    )
  end
  return player
end

function newNpc()
  local npc = newPlayer()
  npc.position.x = 0.7
  npc.update = function(self, dt, mainGame)
    if false then
      self:brake(mainGame)
    else
      self:accel(false, mainGame)
    end
    self.position.y = self.position.y + self.speed
    return self
  end
  npc.draw = function(self, mainGame)
    love.graphics.setColor(255, 128, 128)
    love.graphics.circle(
      "fill",
      math.floor(self.position.x*mainGame.WIDTH),
      math.floor((self.position.y - mainGame.camera + mainGame.BACK_SPACE)*mainGame.WIDTH),
      math.floor(0.05*mainGame.WIDTH)
    )
  end
  return npc
end

function newMainGame()
  local mainGame = {}
  mainGame.WIDTH = 640
  mainGame.STANDARD_SPEED = 0.03
  mainGame.MAX_SPEED = 0.05
  mainGame.TIME_RATE = 0.01
  mainGame.BRAKE = 0.0004
  mainGame.DECELERATION = 0.0002
  mainGame.BACK_SPACE = 0.1
  mainGame.CURVE_RATE = 0.4
  mainGame.players = {}
  table.insert(mainGame.players, newPlayer())
  table.insert(mainGame.players, newNpc())
  mainGame.balls = {}
  mainGame.camera = 0
  mainGame.update = function(self, dt)
    local min
    for i = 1, #self.players do
      self.players[i] = self.players[i]:update(dt, self)
      if not min or self.players[i].position.y < min then
        min = self.players[i].position.y
      end
    end
    self.camera = min
    for i = #self.balls, 1, -1 do
      self.balls[i] = self.balls[i]:update(dt)
    end
    return self
  end
  mainGame.draw = function(self)
    for i = 1, #self.players do
      self.players[i]:draw(self)
    end
    for i = 1, #self.balls do
      self.balls[i]:draw(self)
    end
    for i = 0, 2 do
      love.graphics.setColor(0, 192, 0)
      love.graphics.circle(
        "fill",
        math.floor(0),
        math.floor((i*0.4 - self.camera%0.4)*self.WIDTH),
        math.floor(0.1*self.WIDTH)
      )
      love.graphics.circle(
        "fill",
        math.floor(self.WIDTH),
        math.floor(((i + 0.5)*0.4 - self.camera%0.4)*self.WIDTH),
        math.floor(0.1*self.WIDTH)
      )
    end
  end
  return mainGame
end

function love.load(arg)
  S = 4
  love.window.setMode(640, 480)
  love.window.setTitle("スキーシューティング")
  scene = newMainGame()
  keyboard = newKeyboard()
end

function love.update(dt)
  scene = scene:update(dt)
end

function love.draw()
  scene:draw()
end

