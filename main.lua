-- Imports
local BadVersionScreen = require("src.BadVersionScreen")

local json = require("json")
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
		_Game:init()
        _Display = Display()
    end
end



function love.update(dt)
    _Time = _Time + dt
    _MousePos = Vec2(love.mouse.getPosition())

	_Display:update(dt)
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



function love.keypressed(key)
	_Game:keypressed(key)
end



function love.focus(focus)
	_Game:focus(focus)
end



function love.quit()
	_Game:quit()
end



-- The functions below have been copied from OpenSMCE, another project that I've created!

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



function _LoadJson(path)
	local contents = _LoadFile(path)
	assert(contents, string.format("Could not JSON-decode: %s, file does not exist", path))
	local success, data = pcall(function() return json.decode(contents) end)
	assert(success, string.format("JSON error: %s: %s", path, data))
	assert(data, string.format("Could not JSON-decode: %s, error in file contents", path))
	return data
end



function _SaveFile(path, data)
	local file = io.open(path, "w")
	assert(file, string.format("SAVE FILE FAIL: %s", path))
	io.output(file)
	io.write(data)
	io.close(file)
end



function _SaveJson(path, data)
	_SaveFile(path, json.encode(data))
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