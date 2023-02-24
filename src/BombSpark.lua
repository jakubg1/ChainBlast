local class = require "class"

local BombSpark = class:derive("BombSpark")

-- Place your imports here
local Vec2 = require("src.Vector2")



function BombSpark:new(pos)
    self.pos = pos
    self.speed = Vec2(love.math.randomNormal(30, 75), 0):rotate(love.math.random() * math.pi * 2)
    self.acceleration = Vec2(0, 100)
    self.size = love.math.randomNormal(0.5, 2)
    self.color = {love.math.randomNormal(0.05, 1), love.math.randomNormal(0.1, 0.5), love.math.randomNormal(0.05, 0)}
    self.time = 0
end



function BombSpark:update(dt)
    self.speed = self.speed + self.acceleration * dt
    self.pos = self.pos + self.speed * dt
    self.time = self.time + dt
end



function BombSpark:canDespawn()
    return self.time >= 0.1
end



function BombSpark:draw()
    --local pd = self.speed / 25
    local pd = Vec2(self.size, 0):rotate(self.speed:angle())
    local p1 = self.pos - pd
    local p2 = self.pos + pd
    _Display:drawLine(p1, p2, self.color)
end



return BombSpark