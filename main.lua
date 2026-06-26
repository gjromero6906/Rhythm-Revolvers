-- LÖVE game framework
-- Documentation: https://love2d.org/wiki/Main_Page

local Target = require("src.targets.target")
local Biter = require("src.targets.biter")
local Pacing = require("src.systems.pacing")
local Menu = require("src.menu.menu")
local States = require("src.menu.states")
local Player = require("src.player.player")
local Difficulty = require("src.systems.difficulty")

local WIDTH = 800
local HEIGHT = 600

local score = 0
local elapsed = 0
local roundTime = 60

local isRoundActive = false
local isGameOver = false

local spawnTimer = 0
local nextSpawnDelay = 1

local targets = {}
local activeBiter = nil
local pacer = nil

local currentState = States.game.menu
local currentDifficulty = "easy"

local directions =
    Difficulty.getConfig("easy").directions

local menu = nil
local player = nil

local function resetGame()
    score = 0
    elapsed = 0

    isRoundActive = true
    isGameOver = false

    spawnTimer = 0.5
    nextSpawnDelay = 1

    targets = {}
    activeBiter = nil

    pacer:reset()
end

local function startRound()
    currentDifficulty =
        menu.selectedDifficulty

    directions =
        Difficulty
            .getConfig(currentDifficulty)
            .directions

    resetGame()

    player:setDifficulty(currentDifficulty)

    currentState = States.game.playing
end

local function endRound()
    isRoundActive = false

    targets = {}

    menu:addScore(
        score,
        menu.currentPlayerName
    )
end

function love.load()
    love.window.setMode(WIDTH, HEIGHT)

    love.window.setTitle(
        "Rhythm-Revolvers"
    )

    love.graphics.setFont(
        love.graphics.newFont("assets/consola.ttf", 18)
    )

    love.keyboard.setKeyRepeat(true)

    menu = Menu.new(WIDTH, HEIGHT)

    currentState = States.game.menu

    isRoundActive = false

    player = Player.new()

    pacer = Pacing.new()

    math.randomseed(os.time())
end

function love.update(dt)

    if currentState == States.game.menu then
        menu:update(dt)
        return
    end

    if currentState == States.game.paused then
        return
    end

    if not isRoundActive then
        return
    end

    -- Biter expanded: freeze the round until the sequence is resolved
    if activeBiter and activeBiter.state == "expanded" then
        return
    end

    elapsed =
        math.min(roundTime, elapsed + dt)

    if elapsed >= roundTime then
        endRound()
        return
    end

    spawnTimer = spawnTimer - dt

    if spawnTimer <= 0 then

        local direction =
            directions[math.random(#directions)]

        local roll = math.random()

        -- 8% chance to spawn a biter, but only one at a time
        if not activeBiter and roll < 0.08 then
            activeBiter =
                Biter.spawnRandom(
                    WIDTH,
                    HEIGHT,
                    direction,
                    directions
                )
        else
            local targetType = "normal"

            if roll < 0.2 then
                targetType = "quicktime"

            elseif roll < 0.4 then
                targetType = "moving"
            end

            local newTarget =
                Target.spawnRandom(
                    WIDTH,
                    HEIGHT,
                    direction,
                    targetType
                )

            newTarget.lifeTime = 10

            table.insert(targets, newTarget)
        end

        spawnTimer = nextSpawnDelay
        nextSpawnDelay = pacer:getDelay()
    end

    for i = #targets, 1, -1 do

        local target = targets[i]

        target:update(dt)

        if not target.isAlive then
            table.remove(targets, i)
            pacer:recordMiss()
        end
    end

    -- Tick the active biter and trigger expansion when its timer runs out
    if activeBiter then
        activeBiter:update(dt)

        if activeBiter.needsExpansion then
            activeBiter.needsExpansion = false
            activeBiter:expand()
        end

        if not activeBiter.isAlive then
            activeBiter = nil
        end
    end
end

function love.draw()

    if currentState == States.game.menu then
        menu:draw()
        return
    end

    for _, target in ipairs(targets) do
        target:draw()
    end

    if activeBiter and activeBiter.state == "warning" then
        activeBiter:draw()
    end

    love.graphics.setColor(1, 1, 1)

    love.graphics.print(
        "Score: " .. score,
        10,
        10
    )

    love.graphics.print(
        string.format(
            "Time: %.1f",
            math.max(0, roundTime - elapsed)
        ),
        10,
        34
    )

    love.graphics.print(
        "Pink = QuickTime | Cyan = Moving | Gold = Biter",
        10,
        58
    )

    if currentState == States.game.paused then

        love.graphics.printf(
            "Paused. Press R to resume or Escape to return to menu.",
            0,
            HEIGHT / 2 - 20,
            WIDTH,
            "center"
        )

    elseif not isRoundActive then

        if isGameOver then
            love.graphics.setColor(1, 0.2, 0.2)
            love.graphics.printf(
                "GAME OVER — Biter sequence failed!\nPress R to retry or Escape for menu.",
                0,
                HEIGHT / 2 - 30,
                WIDTH,
                "center"
            )
        else
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(
                "Round ended. Press R to restart or Escape to return to menu.",
                0,
                HEIGHT / 2 - 20,
                WIDTH,
                "center"
            )
        end
    end

    -- Draw expanded biter overlay on top of everything
    if activeBiter and activeBiter.state == "expanded" then
        activeBiter:drawExpanded()
    end
end

function love.mousepressed(x, y, button)

    if currentState == States.game.menu then

        local selection =
            menu:mousepressed(x, y, button)

        if selection == "Play" then

            if menu.currentPlayerName == "" then
                menu:resetNameEntry()
                menu.state =
                    States.menu.nameInput
            else
                menu.state =
                    States.menu.difficultySelect
            end

        elseif selection == "Switch Player" then

            menu.currentPlayerName = ""

            menu:resetNameEntry()

            menu.state =
                States.menu.nameInput

        elseif selection == "StartGame" then
            startRound()

        elseif selection == "Leaderboard" then
            menu.state =
                States.menu.leaderboard

        elseif selection == "Quit" then
            love.event.quit()
        end

        return
    end
end

function love.keypressed(key)

    if currentState == States.game.menu then

        local selection =
            menu:keypressed(key)

        if selection == "Play" then

            if menu.currentPlayerName == "" then

                menu:resetNameEntry()

                menu.state =
                    States.menu.nameInput
            else
                menu.state =
                    States.menu.difficultySelect
            end

        elseif selection == "Switch Player" then

            menu.currentPlayerName = ""

            menu:resetNameEntry()

            menu.state =
                States.menu.nameInput

        elseif selection == "StartGame" then
            startRound()

        elseif selection == "RequestName" then

            menu:resetNameEntry()

            menu.state =
                States.menu.nameInput

        elseif selection == "Leaderboard" then
            menu.state =
                States.menu.leaderboard

        elseif selection == "Quit" then
            love.event.quit()
        end

        return
    end

    -- Biter sequence is active: route all input to it, block everything else
    if activeBiter and activeBiter.state == "expanded" then

        local direction = player:handleKeyPress(key)

        if direction then
            local result =
                activeBiter:handleSequenceInput(direction)

            if result == "success" then
                activeBiter = nil

            elseif result == "fail" then
                isGameOver = true
                isRoundActive = false
                activeBiter = nil
                targets = {}

            -- "miss": attempt lost, sequence reset — overlay stays open
            end
        end

        return
    end

    if currentState == States.game.paused then

        if key == "r" then
            currentState = States.game.playing
            return

        elseif key == "escape" then

            currentState = States.game.menu

            isRoundActive = false

            targets = {}

            return
        end

        return
    end

    if isRoundActive then

        local direction =
            player:handleKeyPress(key)

        if direction then

            -- Killing a biter early awards a bonus and skips the sequence
            if activeBiter
                and activeBiter.state == "warning"
                and activeBiter.directionType == direction then

                score = score + 300
                activeBiter = nil
                pacer:recordHit()

            else

                for i = #targets, 1, -1 do

                    local target = targets[i]

                    if target.isAlive
                        and target.directionType == direction then

                        if target.targetType == "quicktime" then

                            target.currentHits =
                                target.currentHits + 1

                            if target.currentHits
                                >= target.requiredHits then

                                score =
                                    score +
                                    target:getPointValue() * 2

                                target.isAlive = false

                                table.remove(targets, i)
                                pacer:recordHit()
                            end

                        else

                            score =
                                score +
                                target:getPointValue()

                            target.isAlive = false

                            table.remove(targets, i)
                            pacer:recordHit()
                        end

                        break
                    end
                end
            end

            player:clearInput()
        end
    end

    if key == "escape" then

        if isRoundActive then
            currentState = States.game.paused
            return
        end

        currentState = States.game.menu

        isRoundActive = false
        isGameOver = false

        targets = {}
        activeBiter = nil

        return

    elseif key == "r"
        and not isRoundActive then

        startRound()
    end
end

function love.textinput(text)

    if currentState == States.game.menu
        and menu.state == States.menu.nameInput then

        menu:textinput(text)
    end
end