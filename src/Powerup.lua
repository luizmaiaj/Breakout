--[[

    -- Powerup Class --

    Author: Luiz Maia

    To manage the powerups that will be generated during the course of the game
]]

Powerup = Class{}

function Powerup:init()
    -- static size
    self.width = 16
    self.height = 16

    self.active = false

    self.skin = 1

    self.x = math.random(1, VIRTUAL_WIDTH - self.width)
    self.y = VIRTUAL_HEIGHT / 2 -- simplify so always at the center
end

function Powerup:collides(target)

    if self.active == false then
        return false
    end

    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end 

    self.active = false

    -- if the above aren't true, they're overlapping
    return true
end

function Powerup:hit()
    self.skin = self.skin + 1

    if self.skin > 10 then
        self.skin = 1
    end
end

--[[
    Places the ball in the middle of the screen, with no movement.
]]
function Powerup:reset()
    self.x = math.random(1, VIRTUAL_WIDTH - self.width)
    self.y = VIRTUAL_HEIGHT / 2 -- simplify so always at the center

    -- random speed but always going down
    self.dy = math.random(10, 50)
    self.dx = math.random(-50, 50)

    self.skin = math.random(1, 10)

    self.active = true
end

function Powerup:update(dt)
    if self.active == false then
        return
    end

    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt

    -- allow to bounce off walls
    if self.x <= 0 then
        self.x = 0
        self.dx = -self.dx
        gSounds['wall-hit']:play()
    end
   
    if self.x >= VIRTUAL_WIDTH - self.width then
        self.x = VIRTUAL_WIDTH - self.width
        self.dx = -self.dx
        gSounds['wall-hit']:play()
    end
   
    if self.y > (VIRTUAL_HEIGHT + (self.height / 2)) then
        self.active = false
        self.dy = -self.dy
        gSounds['wall-hit']:play()
    end
end

function Powerup:render()
    if self.active then
        love.graphics.draw(gTextures['main'], gFrames['powerups'][self.skin], self.x, self.y)
        self:renderDescription()
    end
end

function Powerup:renderDescription()
    local description = 'Power-up: '

    if self.skin == 1 then -- power up that reduces pad size
        description = description .. 'reduce paddle'
    elseif self.skin == 2 then -- power up that increases pad size
        description = description .. 'increase paddle'
    elseif self.skin == 3 then -- power up that adds one health point
        description = description .. 'gain one health'
    elseif self.skin == 4 then -- power up that subtracts one health point
        description = description .. 'lose one health'
    elseif self.skin == 5 then -- power up that increases speed of all balls
        description = description .. 'accelerate balls'
    elseif self.skin == 6 then -- power up that reduces the speed of all balls
        description = description .. 'decelerate balls'
    elseif self.skin == 7 then -- power up that removes two balls
        description = description .. 'removes two balls'
    elseif self.skin == 8 then -- power up that adds two balls
        description = description .. 'adds two balls'
    elseif self.skin == 9 then -- power up that accelerates one ball and makes it bounce below the paddle for 5 seconds
        description = description .. 'god mode'
    elseif self.skin == 10 then -- power up that unlocks the key brick
        description = description .. 'unlocks key brick'
    end

    love.graphics.setFont(gFonts['small'])
    love.graphics.print(description, 100, 5)
end