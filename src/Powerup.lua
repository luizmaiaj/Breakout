--[[

    -- Powerup Class --

    Author: Luiz Maia

    To manage the powerups that will be generated during the course of the game
]]

Powerup = Class{__includes = Particles}

function Powerup:init()
    -- static size
    self.width = 16
    self.height = 16

    self.active = false

    self.skin = 1

    -- self:initParticles()
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

--[[
    Places the ball in the middle of the screen, with no movement.
]]
function Powerup:reset()
    self.x = math.random(1, VIRTUAL_WIDTH - self.width)
    self.y = VIRTUAL_HEIGHT / 2 -- simplify so always at the center

    -- random speed but always going down
    self.dy = math.random(10, 50)
    self.dx = math.random(-50, 50)

    -- self:hitParticles(math.random(0, 5), math.random(0, 255), self.x + (self.width/2), self.y + (self.height/2))

    self.skin = 1 -- later to be randomized or managed in antoher way

    self.active = true
end

function Powerup:update(dt)
    if self.active == false then
        return
    end

    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt

    -- allow ball to bounce off walls
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
   
    if self.y <= 0 then
        self.y = 0
        self.dy = -self.dy
        gSounds['wall-hit']:play()
    end

    -- self:updateParticle()
end

function Powerup:render()
    if self.active then
        love.graphics.draw(gTextures['main'], gFrames['powerups'][self.skin], self.x, self.y)
    end
end

function Powerup:renderParticles()
    -- self:draw()
end