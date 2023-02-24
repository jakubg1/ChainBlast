local class = require "class"

local Bomb = class:derive("Bomb")

-- Place your imports here
local Vec2 = require("src.Vector2")
local BombSpark = require("src.BombSpark")



function Bomb:new(level, targetCoords)
    self.level = level
    self.targetCoords = targetCoords

    self.targetPos = self.level.board:getTilePos(self.targetCoords)
    self.pos = self.targetPos + Vec2(200, 0):rotate(love.math.random() * math.pi * 2)
    self.startPos = self.pos
    self.time = 0
    self.targetTime = 0.5
    self.exploded = false
end



function Bomb:update(dt)
    self.time = self.time + dt
    local t = self.time / self.targetTime
    self.pos = self.startPos * (1 - t) + self.targetPos * t
    if self.time >= self.targetTime then
        self.pos = self.targetPos
        self:explode()
    else
        table.insert(_Game.sparks, BombSpark(self.pos + Vec2(love.math.randomNormal(2, 0), love.math.randomNormal(2, 0))))
    end
end



function Bomb:explode()
    self.level.board:explodeBomb(self.targetCoords)
    self.exploded = true
end



function Bomb:canDespawn()
    return self.exploded
end



return Bomb