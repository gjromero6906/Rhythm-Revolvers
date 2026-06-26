-- target.lua
-- Target class for directional placeholder targets in Love2D

local Target = {}
Target.__index = Target

Target.colors = {
    up = {0.2, 0.6, 1},
    down = {1, 0.3, 0.3},
    left = {0.3, 1, 0.4},
    right = {1, 0.8, 0.2}
}

function Target.getColor(direction)
    if Target.colors[direction] then
        return Target.colors[direction]
    end

    local hash = 0

    for i = 1, #direction do
        hash = (hash * 31 + string.byte(direction, i)) % 256
    end

    local r = (hash % 256) / 256
    local g = ((hash * 7) % 256) / 256
    local b = ((hash * 13) % 256) / 256

    return {r, g, b}
end

function Target.new(x, y, radius, directionType, targetType)
    local self = setmetatable({}, Target)

    self.x = x or 0
    self.y = y or 0

    self.startX = self.x
    self.startY = self.y

    self.radius = radius or 28

    self.directionType = directionType or "up"
    self.color = Target.getColor(self.directionType)

    self.isAlive = true
    self.lifeTime = 10
    self.elapsedTime = 0

    -- normal / quicktime / moving
    self.targetType = targetType or "normal"

    -- quick time settings
    self.requiredHits = 1
    self.currentHits = 0

    if self.targetType == "quicktime" then
        self.requiredHits = math.random(3, 6)
    end

    -- movement settings
    self.movePattern = nil
    self.speed = 0
    self.waveAmplitude = 0

    if self.targetType == "moving" then
        local patterns = {
            "horizontal",
            "vertical",
            "wave"
        }

        self.movePattern = patterns[math.random(#patterns)]
        self.speed = math.random(80, 180)

        if self.movePattern == "wave" then
            self.waveAmplitude = math.random(30, 80)
        end
    end

    return self
end

function Target:update(dt)
    self.elapsedTime = self.elapsedTime + dt
    self.lifeTime = self.lifeTime - dt

    if self.lifeTime <= 0 then
        self.isAlive = false
        return
    end

    if self.targetType == "moving" then

        if self.movePattern == "horizontal" then

            self.x = self.x + self.speed * dt

            if self.x > 760 or self.x < 40 then
                self.speed = -self.speed
            end

        elseif self.movePattern == "vertical" then

            self.y = self.y + self.speed * dt

            if self.y > 560 or self.y < 40 then
                self.speed = -self.speed
            end

        elseif self.movePattern == "wave" then

            self.x = self.x + self.speed * dt

            self.y =
                self.startY +
                math.sin(self.elapsedTime * 4) *
                self.waveAmplitude

            if self.x > 760 or self.x < 40 then
                self.speed = -self.speed
            end
        end
    end
end

function Target:draw()
    if not self.isAlive then
        return
    end

    love.graphics.setColor(self.color)
    love.graphics.circle("fill", self.x, self.y, self.radius)

    -- border based on target type
    if self.targetType == "quicktime" then
        love.graphics.setColor(1, 0, 1)
        love.graphics.setLineWidth(4)
        love.graphics.circle("line", self.x, self.y, self.radius + 4)

    elseif self.targetType == "moving" then
        love.graphics.setColor(0, 1, 1)
        love.graphics.setLineWidth(4)
        love.graphics.circle("line", self.x, self.y, self.radius + 4)
    end

    love.graphics.setColor(1, 1, 1)

    if self.directionType == "up"
        or self.directionType == "down"
        or self.directionType == "left"
        or self.directionType == "right" then

        self:drawArrow(
            self.x,
            self.y,
            self.radius * 0.6,
            self.directionType
        )
    else
        self:drawKeyLabel(
            self.x,
            self.y,
            self.directionType
        )
    end

    -- quicktime counter
    if self.targetType == "quicktime" then

        love.graphics.setColor(1, 1, 1)

        local text =
            tostring(self.currentHits)
            .. "/"
            .. tostring(self.requiredHits)

        love.graphics.print(
            text,
            self.x - 16,
            self.y + self.radius + 6
        )
    end

    love.graphics.setColor(1, 1, 1)
end

function Target:drawArrow(x, y, size, direction)
    local half = size * 0.5
    local points = {}

    if direction == "up" then
        points = {
            x, y - size,
            x - half, y + half,
            x + half, y + half
        }

    elseif direction == "down" then
        points = {
            x, y + size,
            x - half, y - half,
            x + half, y - half
        }

    elseif direction == "left" then
        points = {
            x - size, y,
            x + half, y - half,
            x + half, y + half
        }

    elseif direction == "right" then
        points = {
            x + size, y,
            x - half, y - half,
            x - half, y + half
        }
    end

    love.graphics.setColor(0, 0, 0)
    love.graphics.polygon("fill", points)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.polygon("line", points)
end

function Target:drawKeyLabel(x, y, keyLabel)
    local font = love.graphics.newFont(16)

    love.graphics.setFont(font)

    love.graphics.setColor(0, 0, 0)

    love.graphics.printf(
        keyLabel:upper(),
        x - 20,
        y - 8,
        40,
        "center"
    )

    love.graphics.setColor(1, 1, 1)
end

function Target:getPointValue()
    if self.elapsedTime < 2 then
        return 200
    elseif self.elapsedTime < 4 then
        return 100
    else
        return 50
    end
end

function Target.spawnRandom(
    screenW,
    screenH,
    directionType,
    targetType
)
    local padding = 60

    local x = math.random(
        padding,
        screenW - padding
    )

    local y = math.random(
        padding + 40,
        screenH - padding
    )

    return Target.new(
        x,
        y,
        28,
        directionType,
        targetType
    )
end

return Target