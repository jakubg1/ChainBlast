-- Imports
local BadVersionScreen = require("src.BadVersionScreen")

local Vec2 = require("src.Vector2")
local Game = require("src.Game")
local Display = require("src.Display")



-- Consts
local _VERSION = {love.getVersion()}



-- Vars
_Time = 0
_MousePos = Vec2()
_Game = nil
_Display = nil



function love.load()
    if _VERSION[1] < 12 then
        _Game = BadVersionScreen()
    else
        _Game = Game()
        _Display = Display()
    end
end



function love.update(dt)
    _Time = _Time + dt
    _MousePos = Vec2(love.mouse.getPosition()) / 4

    _Game:update(dt)
end



function love.draw()
    _Game:draw()
    love.graphics.setCanvas()
end



function love.mousepressed(x, y, button)
    _Game:mousepressed(x, y, button)
end



function love.mousereleased(x, y, button)
    _Game:mousereleased(x, y, button)
end