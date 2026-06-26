-- pacing.lua
-- Adjusts the target spawn interval based on player hit/miss performance.
-- A sliding window of the last N events drives the adjustment:
--   hit rate high  → decrease delay (targets spawn faster)
--   hit rate low   → increase delay (targets spawn slower)

local Pacing = {}
Pacing.__index = Pacing

function Pacing.new()
    local self = setmetatable({}, Pacing)

    self.baseDelay    = 1.2   -- starting spawn interval in seconds
    self.minDelay     = 0.3   -- fastest possible interval
    self.maxDelay     = 2.5   -- slowest possible interval
    self.currentDelay = 1.2

    self.windowSize = 10      -- how many recent events to consider
    self.events     = {}      -- ring buffer: 1 = hit, 0 = miss
    self.hitCount   = 0       -- hits currently in the window

    self.stepFast = 0.1       -- seconds removed per good adjustment
    self.stepSlow = 0.15      -- seconds added per bad adjustment

    self.highThreshold = 0.65 -- hit rate at or above this → speed up
    self.lowThreshold  = 0.35 -- hit rate at or below this → slow down

    return self
end

function Pacing:recordHit()
    self:_push(1)
    self:_adjust()
end

function Pacing:recordMiss()
    self:_push(0)
    self:_adjust()
end

function Pacing:_push(value)
    -- Evict the oldest event when the window is full
    if #self.events >= self.windowSize then
        if self.events[1] == 1 then
            self.hitCount = self.hitCount - 1
        end
        table.remove(self.events, 1)
    end
    table.insert(self.events, value)
    self.hitCount = self.hitCount + value
end

function Pacing:_adjust()
    -- Wait for a minimum sample before making changes
    if #self.events < 4 then return end

    local hitRate = self.hitCount / #self.events

    if hitRate >= self.highThreshold then
        self.currentDelay = math.max(
            self.minDelay,
            self.currentDelay - self.stepFast)

    elseif hitRate <= self.lowThreshold then
        self.currentDelay = math.min(
            self.maxDelay,
            self.currentDelay + self.stepSlow)
    end
end

-- Returns the next spawn delay with a small random jitter so spawns
-- never feel perfectly metronomic.
function Pacing:getDelay()
    local jitter = math.random() * 0.25
    return math.max(self.minDelay, self.currentDelay + jitter)
end

function Pacing:reset()
    self.events       = {}
    self.hitCount     = 0
    self.currentDelay = self.baseDelay
end

return Pacing
