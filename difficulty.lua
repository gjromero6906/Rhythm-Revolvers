-- difficulty.lua
-- Difficulty configurations with key mappings for each level

local Difficulty = {}

Difficulty.levels = {
    easy = {
        name = "Easy",
        keys = {"w", "s", "a", "d", "up", "down", "left", "right"},
        directions = {"up", "down", "left", "right"},
        keyBindings = {
            up = {"up", "w"},
            down = {"down", "s"},
            left = {"left", "a"},
            right = {"right", "d"}
        }
    },
    medium = {
        name = "Medium",
        keys = {"a", "s", "d", "f", "g", "h", "j", "k", "l"},
        directions = {"a", "s", "d", "f", "g", "h", "j", "k", "l"},
        keyBindings = {
            a = {"a"},
            s = {"s"},
            d = {"d"},
            f = {"f"},
            g = {"g"},
            h = {"h"},
            j = {"j"},
            k = {"k"},
            l = {"l"}
        }
    },
    hard = {
        name = "Hard",
        keys = {"q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "a", "s", "d", "f", "g", "h", "j", "k", "l", "z", "x", "c", "v", "b", "n", "m"},
        directions = {"q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "a", "s", "d", "f", "g", "h", "j", "k", "l", "z", "x", "c", "v", "b", "n", "m"},
        keyBindings = {}
    },
    extreme = {
        name = "Extreme",
        keys = {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"},
        directions = {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"},
        keyBindings = {}
    }
}

-- Build keyBindings for hard and extreme (one key per direction)
for dir in pairs(Difficulty.levels.hard.directions) do
    local key = Difficulty.levels.hard.directions[dir]
    Difficulty.levels.hard.keyBindings[key] = {key}
end

for dir in pairs(Difficulty.levels.extreme.directions) do
    local key = Difficulty.levels.extreme.directions[dir]
    Difficulty.levels.extreme.keyBindings[key] = {key}
end

function Difficulty.getConfig(level)
    return Difficulty.levels[level] or Difficulty.levels.easy
end

function Difficulty.getRandomDirection(level)
    local config = Difficulty.getConfig(level)
    return config.directions[math.random(#config.directions)]
end

return Difficulty
