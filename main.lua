-- LÖVE game framework
-- Documentation: https://love2d.org/wiki/Main_Page

-- Window constants
local WIDTH = 800
local HEIGHT = 600

function love.load()
    -- Set window size
    love.window.setMode(WIDTH, HEIGHT)
    love.window.setTitle("Rhythm-Revolvers")
    
    -- Initialize game
end

function love.update(dt)
    -- Update game logic
end

function love.draw()
    -- Draw graphics
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end

