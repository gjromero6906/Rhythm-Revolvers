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
    self.options = {"Play", "Leaderboard", "Quit"}
    self.selectedIndex = 1
    self.title = "Rhythm-Revolvers"
    self.subtitle = "Tap the directional target before it disappears"
    self.font = love.graphics.newFont(32)
    self.optionFont = love.graphics.newFont(22)
    self.infoFont = love.graphics.newFont(16)
    self.leaderboard = self:loadLeaderboard()
    self.buttonWidth = 260
    self.buttonHeight = 44
    return self
end

function Menu:loadLeaderboard()
    if not love.filesystem.getInfo("leaderboard.txt") then
        return {}
    end

    local fileText = love.filesystem.read("leaderboard.txt") or ""
    local scores = {}
    for line in fileText:gmatch("[^\r\n]+") do
        local value = tonumber(line)
        if value then
            table.insert(scores, value)
        end
    end

    table.sort(scores, function(a, b) return a > b end)
    return scores
end

function Menu:saveLeaderboard()
    local lines = {}
    for i, score in ipairs(self.leaderboard) do
        lines[#lines + 1] = tostring(score)
    end
    love.filesystem.write("leaderboard.txt", table.concat(lines, "\n"))
end

function Menu:addScore(score)
    if not score or score <= 0 then
        return
    end
    table.insert(self.leaderboard, score)
    table.sort(self.leaderboard, function(a, b) return a > b end)
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

        love.graphics.setFont(self.infoFont)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Use arrow keys / mouse to select, Enter to activate.", 0, self.height - 60, self.width, "center")
    elseif self.state == States.menu.leaderboard then
        love.graphics.setFont(self.optionFont)
        love.graphics.printf("Leaderboard", 0, 180, self.width, "center")

        if #self.leaderboard == 0 then
            love.graphics.setFont(self.infoFont)
            love.graphics.printf("No scores yet. Play a round to add your score!", 0, 240, self.width, "center")
        else
            for index, score in ipairs(self.leaderboard) do
                local y = 240 + (index - 1) * 32
                local entryText = string.format("%d. %d", index, score)
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
            return self.options[self.selectedIndex]
        elseif key == "escape" then
            return "Quit"
        end
    elseif self.state == States.menu.leaderboard then
        if key == "escape" then
            self.state = States.menu.main
        elseif key == "c" then
            self:clearLeaderboard()
        end
    end
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
    end
end

return Menu
