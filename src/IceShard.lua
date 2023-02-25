local class = require "class"

local IceShard = class:derive("IceShard")

-- Place your imports here
local Vec2 = require("src.Vector2")



function IceShard:new(pos)
    self.pos = pos
    self.speed = Vec2(love.math.randomNormal(40, 100), 0):rotate(love.math.random() * math.pi * 2)
    self.acceleration = Vec2(0, 200)
    self.size = love.math.randomNormal(0.5, 2)
    self.color = {love.math.randomNormal(0.05, 0.2), love.math.randomNormal(0.1, 0.6), love.math.randomNormal(0.1, 0.9)}
end



function IceShard:update(dt)
    self.speed = self.speed + self.acceleration * dt
    self.pos = self.pos + self.speed * dt
end



function IceShard:canDespawn()
    return self.pos.y > 216
end



function IceShard:draw()
    local pd = Vec2(self.size)
    local p1 = self.pos - pd
    _Display:drawRect(p1, pd * 2, true, self.color, 0.8)
end



return IceShard