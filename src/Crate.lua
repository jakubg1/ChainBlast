local class = require "class"
local Explosion = require "src.Explosion"

local Crate = class:derive("Crate")

-- Place your imports here
local Vec2 = require("src.Vector2")
local Chip = require("src.Chip")
local Spark = require("src.Spark")



function Crate:new(board, coords, health)
    self.TYPE = "crate"

    self.board = board
    self.coords = coords
    self.health = health

    self.tile = nil
end



function Crate:update(dt)
end



function Crate:getPos()
    return self.board:getTilePos(self.coords)
end



function Crate:damage()
    self.health = self.health - 1
    if self.health == 0 then
        self.tile:destroyObject()
    else
        for i = 1, 5 do
            table.insert(_Game.sparks, Chip(self:getPos() + 7 + Vec2(love.math.randomNormal(2, 0), love.math.randomNormal(2, 0))))
        end
    end
end



function Crate:onDestroy()
    for i = 1, 20 do
        table.insert(_Game.sparks, Chip(self:getPos() + 7 + Vec2(love.math.randomNormal(2, 0), love.math.randomNormal(2, 0))))
    end
    for i = 1, 4 do
        table.insert(_Game.sparks, Spark(self:getPos() + 7 + Vec2(love.math.randomNormal(2, 0), love.math.randomNormal(2, 0))))
    end
    table.insert(_Game.explosions, Explosion(self:getPos() - Vec2(15)))
    _Game.SOUNDS.crateDestroy:play()
end



function Crate:getSubsprite()
    return self.health
end



function Crate:draw()
    local sprite = _Game.SPRITES.crate
    local alpha = self.tile:getAlpha()

    -- Draw shadows first.
    _Display:drawSprite(sprite, self:getSubsprite(), self:getPos() + Vec2(1), {0, 0, 0}, 0.25 * alpha)

    -- Now the actual sprite.
    _Display:drawSprite(sprite, self:getSubsprite(), self:getPos(), nil, alpha)
end



return Crate