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

function Target.new(x, y, radius, directionType)
    local self = setmetatable({}, Target)
    self.x = x or 0
    self.y = y or 0
    self.radius = radius or 28
    self.directionType = directionType or "up"
    self.color = Target.colors[self.directionType] or {1, 1, 1}
    self.isAlive = true
    return self
end

function Target:draw()
    love.graphics.setColor(self.color)
    love.graphics.circle("fill", self.x, self.y, self.radius)
    love.graphics.setColor(1, 1, 1)
    self:drawArrow(self.x, self.y, self.radius * 0.6, self.directionType)
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

function Target:containsPoint(px, py)
    local dx = px - self.x
    local dy = py - self.y
    return dx * dx + dy * dy <= self.radius * self.radius
end

function Target:getPointValue(elapsed)
    if elapsed < 20 then
        return 200
    elseif elapsed < 40 then
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
