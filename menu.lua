-- menu.lua
-- Main menu and leaderboard class for the game

local States = require("states")

local Menu = {}
Menu.__index = Menu

function Menu.new(width, height)
    local self = setmetatable({}, Menu)
    self.width = width or 800
    self.height = height or 600
    self.state = States.menu.main
    self.options = {"Play", "Switch Player", "Leaderboard", "Quit"}
    self.selectedIndex = 1
    self.difficultyOptions = {"Easy", "Medium", "Hard", "Extreme"}
    self.difficultyIndex = 1
    self.selectedDifficulty = "easy"
    self.title = "Rhythm-Revolvers"
    self.subtitle = "Tap the directional target before it disappears"
    self.font = love.graphics.newFont(32)
    self.optionFont = love.graphics.newFont(22)
    self.infoFont = love.graphics.newFont(16)
    self.leaderboard = self:loadLeaderboard()
    self.buttonWidth = 260
    self.buttonHeight = 44
    self.currentPlayerName = ""
    self.inputText = ""
    return self
end

function Menu:loadLeaderboard()
    if not love.filesystem.getInfo("leaderboard.txt") then
        return {}
    end

    local fileText = love.filesystem.read("leaderboard.txt") or ""
    local entries = {}
    for line in fileText:gmatch("[^\r\n]+") do
        local name, scoreText = line:match("^(.-)|(%d+)$")
        if name and scoreText then
            table.insert(entries, {name = name, score = tonumber(scoreText)})
        else
            local value = tonumber(line)
            if value then
                table.insert(entries, {name = "Player", score = value})
            end
        end
    end

    local bestByName = {}
    for _, entry in ipairs(entries) do
        local existing = bestByName[entry.name]
        if not existing or entry.score > existing.score then
            bestByName[entry.name] = entry
        end
    end

    local uniqueEntries = {}
    for _, entry in pairs(bestByName) do
        table.insert(uniqueEntries, entry)
    end

    table.sort(uniqueEntries, function(a, b) return a.score > b.score end)
    return uniqueEntries
end

function Menu:saveLeaderboard()
    local lines = {}
    for i, entry in ipairs(self.leaderboard) do
        lines[#lines + 1] = string.format("%s|%d", entry.name, entry.score)
    end
    love.filesystem.write("leaderboard.txt", table.concat(lines, "\n"))
end

function Menu:addScore(score, name)
    if not score or score <= 0 then
        return
    end
    name = tostring(name or "Player")
    name = name:gsub("|", "")
    if name == "" then
        name = "Player"
    end

    local bestIndex = nil
    for i, entry in ipairs(self.leaderboard) do
        if entry.name == name then
            bestIndex = i
            break
        end
    end

    if bestIndex then
        if score > self.leaderboard[bestIndex].score then
            self.leaderboard[bestIndex].score = score
        else
            return
        end
    else
        table.insert(self.leaderboard, {name = name, score = score})
    end

    table.sort(self.leaderboard, function(a, b) return a.score > b.score end)
    while #self.leaderboard > 10 do
        table.remove(self.leaderboard)
    end
    self:saveLeaderboard()
end

function Menu:clearLeaderboard()
    self.leaderboard = {}
    if love.filesystem.getInfo("leaderboard.txt") then
        love.filesystem.remove("leaderboard.txt")
    end
end

function Menu:update(dt)
    -- Menu has no animated logic yet.
end

function Menu:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.font)
    love.graphics.printf(self.title, 0, 80, self.width, "center")

    if self.state == States.menu.main then
        love.graphics.setFont(self.infoFont)
        love.graphics.printf(self.subtitle, 0, 140, self.width, "center")
        local startY = 220

        for index, option in ipairs(self.options) do
            local y = startY + (index - 1) * 70
            local x = self.width / 2 - self.buttonWidth / 2
            love.graphics.setColor(0.13, 0.13, 0.13, 0.85)
            love.graphics.rectangle("fill", x, y, self.buttonWidth, self.buttonHeight, 8, 8)

            if index == self.selectedIndex then
                love.graphics.setColor(0.95, 0.75, 0.2)
            else
                love.graphics.setColor(1, 1, 1)
            end

            love.graphics.setFont(self.optionFont)
            love.graphics.printf(option, x, y + 10, self.buttonWidth, "center")
        end

        if self.currentPlayerName ~= "" then
            love.graphics.setFont(self.infoFont)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf("Current player: " .. self.currentPlayerName, 0, self.height - 90, self.width, "center")
        end

        love.graphics.setFont(self.infoFont)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Use arrow keys / mouse to select, Enter to activate.", 0, self.height - 60, self.width, "center")
    elseif self.state == States.menu.nameInput then
        love.graphics.setFont(self.optionFont)
        love.graphics.printf("Enter your name:", 0, 180, self.width, "center")

        local inputY = 250
        local inputWidth = self.buttonWidth
        local inputX = self.width / 2 - inputWidth / 2
        love.graphics.setColor(0.13, 0.13, 0.13, 0.85)
        love.graphics.rectangle("fill", inputX, inputY, inputWidth, self.buttonHeight, 8, 8)

        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(self.optionFont)
        love.graphics.printf(self.inputText .. "_", inputX + 8, inputY + 10, inputWidth - 16, "left")

        love.graphics.setFont(self.infoFont)
        love.graphics.printf("Press Enter to start, Escape to cancel.", 0, self.height - 60, self.width, "center")
    elseif self.state == States.menu.difficultySelect then
        love.graphics.setFont(self.optionFont)
        love.graphics.printf("Select Difficulty:", 0, 150, self.width, "center")

        local startY = 240
        for index, difficulty in ipairs(self.difficultyOptions) do
            local y = startY + (index - 1) * 60
            local x = self.width / 2 - self.buttonWidth / 2
            love.graphics.setColor(0.13, 0.13, 0.13, 0.85)
            love.graphics.rectangle("fill", x, y, self.buttonWidth, self.buttonHeight, 8, 8)

            if index == self.difficultyIndex then
                love.graphics.setColor(0.95, 0.75, 0.2)
            else
                love.graphics.setColor(1, 1, 1)
            end

            love.graphics.setFont(self.optionFont)
            love.graphics.printf(difficulty, x, y + 10, self.buttonWidth, "center")
        end

        love.graphics.setFont(self.infoFont)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Use arrow keys / mouse to select, Enter to confirm.", 0, self.height - 60, self.width, "center")
    elseif self.state == States.menu.leaderboard then
        love.graphics.setFont(self.optionFont)
        love.graphics.printf("Top 10 Leaderboard", 0, 180, self.width, "center")

        if #self.leaderboard == 0 then
            love.graphics.setFont(self.infoFont)
            love.graphics.printf("No scores yet. Play a round to add your score!", 0, 240, self.width, "center")
        else
            for index, entry in ipairs(self.leaderboard) do
                local y = 240 + (index - 1) * 32
                local entryText = string.format("%d. %s - %d", index, entry.name, entry.score)
                love.graphics.printf(entryText, 0, y, self.width, "center")
            end
        end

        love.graphics.setFont(self.infoFont)
        love.graphics.printf("Press Escape to return to the menu.", 0, self.height - 90, self.width, "center")
        love.graphics.printf("Press C to clear leaderboard.", 0, self.height - 60, self.width, "center")
    end
end

function Menu:keypressed(key)
    if self.state == States.menu.main then
        if key == "up" then
            self.selectedIndex = math.max(1, self.selectedIndex - 1)
        elseif key == "down" then
            self.selectedIndex = math.min(#self.options, self.selectedIndex + 1)
        elseif key == "return" or key == "space" then
            if self.options[self.selectedIndex] == "Play" then
                if self.currentPlayerName == "" then
                    return "RequestName"
                end
                return "Play"
            elseif self.options[self.selectedIndex] == "Switch Player" then
                return "Switch Player"
            end
            return self.options[self.selectedIndex]
        elseif key == "escape" then
            return "Quit"
        end
    elseif self.state == States.menu.nameInput then
        if key == "return" or key == "space" then
            if #self.inputText > 0 then
                self.currentPlayerName = self.inputText
                self.inputText = ""
                return "Play"
            end
        elseif key == "backspace" then
            if #self.inputText > 0 then
                self.inputText = self.inputText:sub(1, -2)
            end
        elseif key == "escape" then
            self.inputText = ""
            self.state = States.menu.main
        end
    elseif self.state == States.menu.difficultySelect then
        if key == "up" then
            self.difficultyIndex = math.max(1, self.difficultyIndex - 1)
        elseif key == "down" then
            self.difficultyIndex = math.min(#self.difficultyOptions, self.difficultyIndex + 1)
        elseif key == "return" or key == "space" then
            local difficultyMap = {easy = "easy", medium = "medium", hard = "hard", extreme = "extreme"}
            self.selectedDifficulty = self.difficultyOptions[self.difficultyIndex]:lower()
            self.state = States.menu.main
            return "StartGame"
        elseif key == "escape" then
            self.state = States.menu.main
        end
    elseif self.state == States.menu.leaderboard then
        if key == "escape" then
            self.state = States.menu.main
        elseif key == "c" then
            self:clearLeaderboard()
        end
    end
end

function Menu:textinput(text)
    if self.state ~= States.menu.nameInput then
        return
    end

    if text:match("[%w %-%_]") and #self.inputText < 20 then
        self.inputText = self.inputText .. text
    end
end

function Menu:resetNameEntry()
    self.inputText = ""
    self.state = States.menu.nameInput
end

function Menu:mousepressed(x, y, button)
    if button ~= 1 then
        return
    end

    if self.state == States.menu.main then
        local startY = 220
        local x0 = self.width / 2 - self.buttonWidth / 2
        local x1 = x0 + self.buttonWidth

        for index, option in ipairs(self.options) do
            local y0 = startY + (index - 1) * 70
            local y1 = y0 + self.buttonHeight
            if x >= x0 and x <= x1 and y >= y0 and y <= y1 then
                self.selectedIndex = index
                return option
            end
        end
    elseif self.state == States.menu.difficultySelect then
        local startY = 240
        local x0 = self.width / 2 - self.buttonWidth / 2
        local x1 = x0 + self.buttonWidth

        for index, difficulty in ipairs(self.difficultyOptions) do
            local y0 = startY + (index - 1) * 60
            local y1 = y0 + self.buttonHeight
            if x >= x0 and x <= x1 and y >= y0 and y <= y1 then
                self.difficultyIndex = index
                self.selectedDifficulty = difficulty:lower()
                self.state = States.menu.main
                return "StartGame"
            end
        end
    end
end

return Menu
