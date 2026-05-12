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

-- Generate a color based on a hash of the direction name
function Target.getColor(direction)
    if Target.colors[direction] then
        return Target.colors[direction]
    end
    -- Generate a consistent color for this direction based on hash
    local hash = 0
    for i = 1, #direction do
        hash = (hash * 31 + string.byte(direction, i)) % 256
    end
    local r = (hash % 256) / 256
    local g = ((hash * 7) % 256) / 256
    local b = ((hash * 13) % 256) / 256
    return {r, g, b}
end

function Target.new(x, y, radius, directionType)
    local self = setmetatable({}, Target)
    self.x = x or 0
    self.y = y or 0
    self.radius = radius or 28
    self.directionType = directionType or "up"
    self.color = Target.getColor(self.directionType)
    self.isAlive = true
    self.lifeTime = 10
    self.elapsedTime = 0
    return self
end

function Target:draw()
    love.graphics.setColor(self.color)
    love.graphics.circle("fill", self.x, self.y, self.radius)
    love.graphics.setColor(1, 1, 1)
    
    -- For standard directions, draw arrows; otherwise draw text
    if self.directionType == "up" or self.directionType == "down" or self.directionType == "left" or self.directionType == "right" then
        self:drawArrow(self.x, self.y, self.radius * 0.6, self.directionType)
    else
        self:drawKeyLabel(self.x, self.y, self.directionType)
    end
end

function Target:drawArrow(x, y, size, direction)
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

    love.graphics.polygon("fill", points)
    love.graphics.setColor(0, 0, 0)
    love.graphics.setLineWidth(2)
    love.graphics.polygon("line", points)
    love.graphics.setColor(1, 1, 1)
end

function Target:drawKeyLabel(x, y, keyLabel)
    local font = love.graphics.newFont(16)
    love.graphics.setFont(font)
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(keyLabel:upper(), x - 15, y - 8, 30, "center")
    love.graphics.setColor(1, 1, 1)
end

function Target:containsPoint(px, py)
    local dx = px - self.x
    local dy = py - self.y
    return dx * dx + dy * dy <= self.radius * self.radius
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

function Target.spawnRandom(screenW, screenH, directionType)
    local padding = 50
    local x = math.random(padding, screenW - padding)
    local y = math.random(padding + 40, screenH - padding)
    return Target.new(x, y, 28, directionType)
end

return Target
