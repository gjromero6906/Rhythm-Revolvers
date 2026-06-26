-- biter.lua
-- Biter class: a threat target that, if not killed in time, expands into
-- a full-screen sequence challenge. Fail the sequence and it's game over.

local Biter = {}
Biter.__index = Biter

local _fonts = {}
local function font(size)
    if not _fonts[size] then
        _fonts[size] = love.graphics.newFont(
            "consola.ttf", size)
    end
    return _fonts[size]
end

function Biter.new(x, y, directionType, sequencePool, screenW, screenH)
    local self = setmetatable({}, Biter)
    self.x = x
    self.y = y
    self.radius = 36
    self.directionType = directionType or "up"
    self.color = {0.55, 0, 0.85}
    self.isAlive = true
    self.lifeTime = 6
    self.elapsedTime = 0
    self.state = "warning"
    self.needsExpansion = false
    self.sequencePool = sequencePool or {"up", "down", "left", "right"}
    self.sequence = {}
    self.sequenceIndex = 1
    self.maxAttempts = 3
    self.attemptsLeft = 3
    self.screenW = screenW or 800
    self.screenH = screenH or 600
    return self
end

function Biter:expand()
    self.state = "expanded"
    local len = math.random(4, 6)
    for i = 1, len do
        self.sequence[i] =
            self.sequencePool[math.random(#self.sequencePool)]
    end
    self.sequenceIndex = 1
end

function Biter:update(dt)
    self.elapsedTime = self.elapsedTime + dt
    self.lifeTime = self.lifeTime - dt

    if self.lifeTime <= 0 and self.state == "warning" then
        self.needsExpansion = true
    end
end

-- Returns "continue", "success", "miss" (wrong key, attempt lost), or "fail" (no attempts left)
function Biter:handleSequenceInput(direction)
    if self.state ~= "expanded" then return nil end

    if direction == self.sequence[self.sequenceIndex] then
        self.sequenceIndex = self.sequenceIndex + 1
        if self.sequenceIndex > #self.sequence then
            self.isAlive = false
            return "success"
        end
        return "continue"
    end

    self.attemptsLeft = self.attemptsLeft - 1
    self.sequenceIndex = 1

    if self.attemptsLeft <= 0 then
        return "fail"
    end

    return "miss"
end

function Biter:draw()
    if not self.isAlive then return end
    if self.state == "expanded" then return end

    -- Body
    love.graphics.setColor(self.color)
    love.graphics.circle("fill", self.x, self.y, self.radius)

    -- Pulsing gold border that speeds up as time runs low
    local t = love.timer.getTime()
    local urgency = 1 - math.max(0, self.lifeTime / 12)
    local pulseSpeed = 2 + urgency * 8
    local pulse = 0.6 + math.sin(t * pulseSpeed) * 0.4
    love.graphics.setColor(1, pulse * 0.8, 0)
    love.graphics.setLineWidth(5)
    love.graphics.circle("line", self.x, self.y, self.radius + 5)
    love.graphics.setColor(1, pulse * 0.4, 0, pulse * 0.7)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", self.x, self.y, self.radius + 13)

    -- Direction indicator (arrow or key label)
    love.graphics.setColor(1, 1, 1)
    if self.directionType == "up"
        or self.directionType == "down"
        or self.directionType == "left"
        or self.directionType == "right" then
        self:drawArrow(
            self.x, self.y,
            self.radius * 0.6,
            self.directionType)
    else
        self:drawKeyLabel(self.x, self.y, self.directionType)
    end

    -- "!" warning label above the circle
    love.graphics.setColor(1, 0.9, 0)
    love.graphics.setFont(font(14))
    love.graphics.printf(
        "!", self.x - 20, self.y - self.radius - 22, 40, "center")

    love.graphics.setColor(1, 1, 1)
end

function Biter:drawArrow(x, y, size, direction)
    local half = size * 0.5
    local points = {}
    if direction == "up" then
        points = {x, y - size, x - half, y + half, x + half, y + half}
    elseif direction == "down" then
        points = {x, y + size, x - half, y - half, x + half, y - half}
    elseif direction == "left" then
        points = {x - size, y, x + half, y - half, x + half, y + half}
    elseif direction == "right" then
        points = {x + size, y, x - half, y - half, x - half, y + half}
    end
    love.graphics.setColor(0, 0, 0)
    love.graphics.polygon("fill", points)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.polygon("line", points)
end

function Biter:drawKeyLabel(x, y, keyLabel)
    love.graphics.setFont(font(16))
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(keyLabel:upper(), x - 20, y - 8, 40, "center")
    love.graphics.setColor(1, 1, 1)
end

function Biter:drawExpanded()
    local W = self.screenW
    local H = self.screenH
    local pW = W * 0.8
    local pH = H * 0.8
    local pX = (W - pW) / 2
    local pY = (H - pH) / 2
    local t = love.timer.getTime()

    -- Dim the rest of the screen
    love.graphics.setColor(0, 0, 0, 0.78)
    love.graphics.rectangle("fill", 0, 0, W, H)

    -- Panel background
    love.graphics.setColor(0.06, 0.01, 0.12)
    love.graphics.rectangle("fill", pX, pY, pW, pH, 14, 14)

    -- Pulsing border
    local pulse = 0.65 + math.sin(t * 5) * 0.35
    love.graphics.setColor(1, 0.55 * pulse, 0)
    love.graphics.setLineWidth(5)
    love.graphics.rectangle("line", pX, pY, pW, pH, 14, 14)

    -- Title
    love.graphics.setFont(font(34))
    love.graphics.setColor(1, 0.22, 0.22)
    love.graphics.printf(
        "!! BITER SEQUENCE !!", pX, pY + 26, pW, "center")

    -- Instruction
    love.graphics.setFont(font(16))
    love.graphics.setColor(0.88, 0.88, 0.88)
    love.graphics.printf(
        "Press each highlighted key in order — lose all attempts and it's GAME OVER",
        pX, pY + 80, pW, "center")

    -- Attempt dots (filled = remaining, hollow = lost)
    local dotR = 10
    local dotGap = 10
    local totalDotsW = self.maxAttempts * (dotR * 2) + (self.maxAttempts - 1) * dotGap
    local dotStartX = pX + (pW - totalDotsW) / 2
    local dotY = pY + 116
    for i = 1, self.maxAttempts do
        local dx = dotStartX + (i - 1) * (dotR * 2 + dotGap) + dotR
        if i <= self.attemptsLeft then
            love.graphics.setColor(0.2, 1, 0.3)
            love.graphics.circle("fill", dx, dotY, dotR)
        else
            love.graphics.setColor(0.35, 0.1, 0.1)
            love.graphics.circle("fill", dx, dotY, dotR)
            love.graphics.setColor(0.6, 0.2, 0.2)
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", dx, dotY, dotR)
        end
    end

    -- Sequence boxes
    local seqLen = #self.sequence
    local boxSize = 58
    local gap = 12
    local totalW = seqLen * boxSize + (seqLen - 1) * gap
    local bStartX = pX + (pW - totalW) / 2
    local bY = pY + pH / 2 - boxSize / 2

    for i, dir in ipairs(self.sequence) do
        local bx = bStartX + (i - 1) * (boxSize + gap)

        if i < self.sequenceIndex then
            love.graphics.setColor(0.15, 0.72, 0.15)
        elseif i == self.sequenceIndex then
            local glow = 0.85 + math.sin(t * 7) * 0.15
            love.graphics.setColor(1, glow * 0.7, 0)
        else
            love.graphics.setColor(0.2, 0.2, 0.3)
        end

        love.graphics.rectangle("fill", bx, bY, boxSize, boxSize, 8, 8)

        if i == self.sequenceIndex then
            love.graphics.setColor(1, 1, 1)
            love.graphics.setLineWidth(3)
            love.graphics.rectangle(
                "line", bx, bY, boxSize, boxSize, 8, 8)
        end

        local label = dir
        if     dir == "up"    then label = "^"
        elseif dir == "down"  then label = "v"
        elseif dir == "left"  then label = "<"
        elseif dir == "right" then label = ">"
        else                       label = dir:upper()
        end

        if i >= self.sequenceIndex then
            love.graphics.setColor(
                i == self.sequenceIndex and 1 or 0.42,
                i == self.sequenceIndex and 1 or 0.42,
                i == self.sequenceIndex and 1 or 0.52)
        else
            love.graphics.setColor(1, 1, 1)
        end

        love.graphics.setFont(font(24))
        love.graphics.printf(
            label, bx, bY + (boxSize - 28) / 2, boxSize, "center")
    end

    -- Step counter below the boxes
    love.graphics.setFont(font(15))
    love.graphics.setColor(0.58, 0.58, 0.65)
    love.graphics.printf(
        string.format(
            "Step %d of %d",
            math.min(self.sequenceIndex, seqLen),
            seqLen),
        pX, bY + boxSize + 18, pW, "center")
end

function Biter.spawnRandom(screenW, screenH, directionType, sequencePool)
    local padding = 60
    local x = math.random(padding, screenW - padding)
    local y = math.random(padding + 40, screenH - padding)
    return Biter.new(x, y, directionType, sequencePool, screenW, screenH)
end

return Biter
