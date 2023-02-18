local class = require "class"

local Chain = class:derive("Chain")

-- Place your imports here
local Spark = require("src.Spark")



function Chain:new(board, coords)
    self.TYPE = "chain"

    self.board = board
    self.coords = coords
    self.fallTarget = nil
    self.fallSpeed = 0

    self.color = love.math.random(1, 3)
    -- 1 = vertical, 2 = horizontal
    self.rotation = love.math.random(1, 2)
end



function Chain:update(dt)
    if self.fallTarget then
        self.fallSpeed = self.fallSpeed + 12 * dt
        self.coords.y = self.coords.y + self.fallSpeed * dt
        if self.coords.y >= self.fallTarget.y then
            self.coords.y = self.fallTarget.y
            self.fallTarget = nil
            self.fallSpeed = 0
            --self.board:setChain(self.coords, self)
        end
    end
end



function Chain:getPos()
    return self.board:getTilePos(self.coords)
end



function Chain:fallTo(coords)
    self.fallTarget = coords
end



function Chain:onDestroy()
    local pos = self:getPos() + 7
    for i = 1, 15 do
        table.insert(_Game.sparks, Spark(pos))
    end
end



function Chain:draw()
    local sprite = _Game.SPRITES.chains[self.color]
    _Display:drawSprite(sprite, self.rotation, self:getPos())
end



return Chain