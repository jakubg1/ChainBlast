local class = require "class"

local Chip = class:derive("Chip")

-- Place your imports here
local Vec2 = require("src.Vector2")



function Chip:new(pos)
    self.pos = pos
    self.speed = Vec2(love.math.randomNormal(40, 100), 0):rotate(love.math.random() * math.pi * 2)
    self.angle = love.math.random() * math.pi * 2
    self.acceleration = Vec2(0, 200)
    self.size = math.max(love.math.randomNormal(2, 3), 1)
    self.color = {love.math.randomNormal(0.1, 0.6), love.math.randomNormal(0.05, 0.3), love.math.randomNormal(0.05, 0.1)}
    self.darkColor = {self.color[1] * 0.75, self.color[2] * 0.75, self.color[3] * 0.75}
end



function Chip:update(dt)
    self.speed = self.speed + self.acceleration * dt
    self.pos = self.pos + self.speed * dt
end



function Chip:canDespawn()
    return self.pos.y > 216
end



function Chip:draw()
    --local pd = self.speed / 25
    local pd = Vec2(self.size, 0):rotate(self.angle)
    local p1 = self.pos - pd
    local p2 = self.pos + pd
    _Display:drawLine(p1, p2, self.color, nil, 2)
    local colorVector = Vec2(0, 0.5):rotate(self.angle)
    _Display:drawLine(p1 + colorVector, p2 + colorVector, self.darkColor, nil)
end



return Chip