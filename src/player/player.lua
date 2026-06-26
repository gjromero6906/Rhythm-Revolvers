-- player.lua
-- Player class that handles keyboard input and target matching

local Difficulty = require("src.systems.difficulty")

local Player = {}
Player.__index = Player

function Player.new(difficulty)
    local self = setmetatable({}, Player)

    self.lastInputDirection = nil

    self.difficulty = difficulty or "easy"

    local config =
        Difficulty.getConfig(self.difficulty)

    self.keyBindings = config.keyBindings

    return self
end

function Player:setDifficulty(difficulty)
    self.difficulty = difficulty

    local config =
        Difficulty.getConfig(difficulty)

    self.keyBindings = config.keyBindings
end

function Player:handleKeyPress(key)
    for direction, keys in pairs(self.keyBindings) do

        for _, keyName in ipairs(keys) do

            if key == keyName then
                self.lastInputDirection = direction
                return direction
            end
        end
    end

    return nil
end

function Player:clearInput()
    self.lastInputDirection = nil
end

function Player:getLastDirection()
    return self.lastInputDirection
end

return Player