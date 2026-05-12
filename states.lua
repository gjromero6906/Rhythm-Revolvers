-- states.lua
-- Shared state constants for the game and menu

local States = {
    game = {
        menu = "menu",
        playing = "playing",
        paused = "paused"
    },
    menu = {
        main = "main",
        nameInput = "nameInput",
        difficultySelect = "difficultySelect",
        leaderboard = "leaderboard"
    }
}

return States
