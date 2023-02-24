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



function _GetRainbowColor(t)
    t = t * 3
    local r = math.min(math.max(2 * (1 - math.abs(t % 3)), 0), 1) + math.min(math.max(2 * (1 - math.abs((t % 3) - 3)), 0), 1)
    local g = math.min(math.max(2 * (1 - math.abs((t % 3) - 1)), 0), 1)
    local b = math.min(math.max(2 * (1 - math.abs((t % 3) - 2)), 0), 1)
    return {r, g, b}
end



function _LoadFile(path)
	local file, err = io.open(path, "r")
	if not file then
		return
	end
	io.input(file)
	local contents = io.read("*a")
	io.close(file)
	return contents
end



function _StrSplit(s, k)
	local t = {}
	local l = k:len()
	while true do
		local n = s:find("%" .. k)
		if n then
			table.insert(t, s:sub(1, n - 1))
			s = s:sub(n + l)
		else
			table.insert(t, s)
			return t
		end
	end
end