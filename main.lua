-- LÖVE game framework
-- Documentation: https://love2d.org/wiki/Main_Page

local Target = require("target")
local Menu = require("menu")
local States = require("states")

-- Window constants
local WIDTH = 800
local HEIGHT = 600

local score = 0
local elapsed = 0
local roundTime = 60
local isRoundActive = false
local spawnTimer = 0
local nextSpawnDelay = 1
local currentTarget = nil
local currentState = States.game.menu
local directions = {"up", "down", "left", "right"}
local menu = nil

local function resetGame()
    score = 0
    elapsed = 0
    isRoundActive = true
    spawnTimer = 0.5
    nextSpawnDelay = 1
    currentTarget = nil
end

local function startRound()
    resetGame()
    currentState = States.game.playing
end

local function endRound()
    isRoundActive = false
    currentTarget = nil
    menu:addScore(score)
end

function love.load()
    love.window.setMode(WIDTH, HEIGHT)
    love.window.setTitle("Rhythm-Revolvers")
    love.graphics.setFont(love.graphics.newFont(18))

    menu = Menu.new(WIDTH, HEIGHT)
    currentState = States.game.menu
    isRoundActive = false
    math.randomseed(os.time())
end

function love.update(dt)
    if currentState == States.game.menu then
        menu:update(dt)
        return
    end

    if not isRoundActive then
        return
    end

    elapsed = math.min(roundTime, elapsed + dt)
    if elapsed >= roundTime then
        endRound()
        return
    end

    spawnTimer = spawnTimer - dt

    if not currentTarget and spawnTimer <= 0 then
        local direction = directions[math.random(#directions)]
        currentTarget = Target.spawnRandom(WIDTH, HEIGHT, direction)
        currentTarget.lifeTime = 2.5
        spawnTimer = nextSpawnDelay
        nextSpawnDelay = math.random() * 1.2 + 0.5
    end

    if currentTarget and currentTarget.lifeTime then
        currentTarget.lifeTime = currentTarget.lifeTime - dt
        if currentTarget.lifeTime <= 0 then
            currentTarget.isAlive = false
            currentTarget = nil
        end
    end
end

function love.draw()
    if currentState == States.game.menu then
        menu:draw()
        return
    end

    if currentTarget and currentTarget.isAlive then
        currentTarget:draw()
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. score, 10, 10)
    love.graphics.print(string.format("Time: %.1f", math.max(0, roundTime - elapsed)), 10, 34)

    if not isRoundActive then
        love.graphics.printf("Round ended. Press R to restart or Escape to return to menu.", 0, HEIGHT / 2 - 20, WIDTH, "center")
    end
end

function love.mousepressed(x, y, button)
    if currentState == States.game.menu then
        local selection = menu:mousepressed(x, y, button)
        if selection == "Play" then
            startRound()
        elseif selection == "Leaderboard" then
            menu.state = States.menu.leaderboard
        elseif selection == "Quit" then
            love.event.quit()
        end
        return
    end

    if button == 1 and currentTarget and currentTarget.isAlive then
        if currentTarget:containsPoint(x, y) then
            score = score + currentTarget:getPointValue(elapsed)
            currentTarget.isAlive = false
            currentTarget = nil
        end
    end
end

function love.keypressed(key)
    if currentState == States.game.menu then
        local selection = menu:keypressed(key)
        if selection == "Play" then
            startRound()
        elseif selection == "Leaderboard" then
            menu.state = States.menu.leaderboard
        elseif selection == "Quit" then
            love.event.quit()
        end
        return
    end

    if key == "escape" then
        if isRoundActive then
            currentState = States.game.menu
            isRoundActive = false
            currentTarget = nil
            return
        end
        currentState = States.game.menu
        isRoundActive = false
        return
    elseif key == "r" and not isRoundActive then
        startRound()
    end
end

