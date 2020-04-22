--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.level = params.level

    self.powerup = Powerup()

    self.recoverPoints = 5000

    -- power up related
    self.counter = 0 -- time counter for power up
    self.expire = math.random(POWERUP_TIMER_MIN, POWERUP_TIMER_MAX)
    self.godballexpire = 0

    -- add extra balls
    self.balls = {}
    table.insert(self.balls, params.ball)
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    self.counter = self.counter + dt
    if self.counter >= self.expire then
        self.powerup:reset()
        self.counter = 0
        self.expire = math.random(POWERUP_TIMER_MIN, POWERUP_TIMER_MAX)
    end

    if self.godballexpire > 0 then
        self.godballexpire = self.godballexpire - dt

        if self.godballexpire <= 0 then
            for k, ball in pairs(self.balls) do
                if ball.active and ball.godmode then
                    ball:setGodMode()
                end
            end
        end
    end

    -- update positions based on velocity
    self.paddle:update(dt)

    for k, ball in pairs(self.balls) do
        ball:update(dt)
    end

    self.powerup:update(dt)

    self:powerupCollides()

    self:ballsCollides()

    self:noMoreBalls()

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()

    for k, ball in pairs(self.balls) do
        ball:render()
    end

    self.powerup:render()

    renderScore(self.score)
    renderHealth(self.health)
    self:renderMode()

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end

-- manage powerups
function PlayState:powerupCollides()
    if self.powerup:collides(self.paddle) then

        if self.powerup.skin == 1 then -- power up that reduces pad size
            self.paddle:increase()
        elseif self.powerup.skin == 2 then -- power up that increases pad size
            self.paddle:reduce()
        elseif self.powerup.skin == 3 then -- power up that adds one health point
            self:increaseHealth()
        elseif self.powerup.skin == 4 then -- power up that subtracts one health point
            self:decreaseHealth()
        elseif self.powerup.skin == 5 then -- power up that increases speed of all balls
            for k, ball in pairs(self.balls) do
                ball.dx = ball.dx * 1.2
                ball.dy = ball.dy * 1.2
            end
        elseif self.powerup.skin == 6 then -- power up that reduces the speed of all balls
            for k, ball in pairs(self.balls) do
                ball.dx = ball.dx * .8
                ball.dy = ball.dy * .8
            end
        elseif self.powerup.skin == 7 then -- power up that removes two balls
            local found = 0
            local removed = 0
            for k, ball in pairs(self.balls) do
                if ball.active then
                    foundOne = foundOne + 1
                end

                if foundOne > 1 and ball.active then
                    ball.active = false
                    removed = removed + 1

                    if removed == 2 then
                        break
                    end
                end
            end
        elseif self.powerup.skin == 8 then -- power up that adds two balls
            for i = 0, 1 do
                local newball

                -- reuse the balls already created
                for k, ball in pairs(self.balls) do
                    if ball.active == false then
                        newball = ball
                        break
                    end
                end

                if newball == nill then
                    newball = Ball()
                    table.insert(self.balls, newball)
                end

                newball:reset(self.paddle, i == 0 and 'left' or 'right')
            end
        elseif self.powerup.skin == 9 then -- power up that accelerates one ball and makes it bounce below the paddle for 5 seconds
            for k, ball in pairs(self.balls) do
                if ball.active then
                    ball:setGodMode()
                    if ball.godmode then
                        self.godballexpire = GODBALLTIMER
                    end
                end
            end
        elseif self.powerup.skin == 10 then -- power up that unlocks the key brick

        end

        gSounds['paddle-hit']:play()
    end
end

function PlayState:ballsCollides()
    for k, ball in pairs(self.balls) do

        if ball.active then

            -- IF BALL COLLIDES WITH PADDLE
            if ball:collides(self.paddle) then
                -- raise ball above paddle in case it goes below it, then reverse dy
                ball.y = self.paddle.y - 8
                ball.dy = -ball.dy

                -- tweak angle of bounce based on where it hits the paddle

                -- if we hit the paddle on its left side while moving left...
                if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                    ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))
                
                -- else if we hit the paddle on its right side while moving right...
                elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                    ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
                end

                gSounds['paddle-hit']:play()
            end

            -- IF BALL COLLIDES WITH BALL
            for j, cBall in pairs(self.balls) do
                if ball ~= cBall and cBall.active and ball:collides(cBall) then
                    ball:flip(cBall)
                end
            end

            -- IF BALL COLLIDES WITH POWERUP
            if self.powerup.active and ball:collides(self.powerup) then
                ball:flip(self.powerup)
                self.powerup:hit()
            end

            -- IF BALL COLLIDES WITH BRICKS
            for k, brick in pairs(self.bricks) do

                -- only check collision if we're in play
                if brick.inPlay and ball:collides(brick) then

                    -- add to score
                    self.score = self.score + (brick.tier * 200 + brick.color * 25)

                    -- trigger the brick's hit function, which removes it from play
                    brick:hit()

                    -- if we have enough points, recover a point of health
                    if self.score > self.recoverPoints then
                        self.paddle:increase() -- increase paddle size as a bonus

                        self:increaseHealth()
                        
                        self.recoverPoints = math.min(100000, self.recoverPoints * 2) -- multiply recover points by 2

                        gSounds['recover']:play() -- play recover sound effect
                    end

                    -- go to our victory screen if there are no more bricks left
                    if self:checkVictory() then
                        gSounds['victory']:play()

                        gStateMachine:change('victory', {
                            level = self.level,
                            paddle = self.paddle,
                            health = self.health,
                            score = self.score,
                            highScores = self.highScores,
                            balls = self.balls,
                            recoverPoints = self.recoverPoints
                        })
                    end

                    -- correct ball course if it hits a brick
                    ball:flip(brick)

                    -- slightly scale the y velocity to speed up the game, capping at +- 150
                    if math.abs(ball.dy) < 150 then
                        ball.dy = ball.dy * 1.02
                    end

                    -- only allow colliding with one brick, for corners
                    break
                end
            end
        end
    end
end

-- if no more balls are available then another serve or game-over
function PlayState:noMoreBalls()
    local nomoreballs = true
    for k, ball in pairs(self.balls) do
        if ball.active == true then
            nomoreballs = false
            break
        end
    end

    -- if ball goes below bounds, revert to serve state and decrease health
    if nomoreballs then
        self:decreaseHealth()

        gSounds['hurt']:play()

        self.paddle:setSize(self.paddle.size - 1) -- shrink the paddle

        if self.health == 0 then
            gStateMachine:change('game-over', {score = self.score, highScores = self.highScores })
        else
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                recoverPoints = self.recoverPoints
            })
        end
    end
end

function PlayState:increaseHealth()
    self.health = math.min(3, self.health + 1) -- can't go above 3 health
end

function PlayState:decreaseHealth()
    self.health = self.health - 1
end

--[[
    Simply renders the player's score at the top right, with left-side padding
    for the score number.
]]
function PlayState:renderMode()
    if self.godballexpire > 0 then
        love.graphics.setFont(gFonts['small'])
        love.graphics.print('God Mode: ' .. tostring(math.floor(self.godballexpire)), VIRTUAL_WIDTH - 200, 5)

        for k, ball in pairs(self.balls) do
            if ball.active and ball.godmode then
                ball:draw() -- draw particles behind the ball in god mode
            end
        end
    end
end