local class = require "class"

local Star = class:derive("Star")

-- Place your imports here
local Vec2 = require("src.Vector2")



function Star:new(t)
    t = t or 0

    self.maxTime = 3 + love.math.random() * 7
    self.time = self.maxTime * t

    self.startPos = Vec2(200, love.math.random() * 250 - 100)
    self.endPos = Vec2(0, self.startPos.y + 100)
    self.pos = self.startPos * (1 - t) + self.endPos * t

    self.brightness = love.math.randomNormal(0.1, 0.4) + (10 - self.maxTime) * 0.1
    --self.color = {love.math.randomNormal(0.05, 1), love.math.randomNormal(0.1, 0.5), love.math.randomNormal(0.05, 0)}
end



function Star:update(dt)
    self.time = self.time + dt
    local t = self.time / self.maxTime
    self.pos = self.startPos * (1 - t) + self.endPos * t
end



function Star:canDespawn()
    return self.time >= self.maxTime
end



function Star:draw()
    _Display:drawRect(self.pos, Vec2(1), true, {1, 1, 1}, self.brightness)
end



return Star