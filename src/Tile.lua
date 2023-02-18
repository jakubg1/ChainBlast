local class = require "class"

local Tile = class:derive("Tile")

-- Place your imports here
local Vec2 = require("src.Vector2")



function Tile:new(board, coords)
    self.board = board
    self.coords = coords

    self.neighbors = {}
    self.object = nil
    self.selected = false

    self.COLOR = {0.25, 0.25, 0.25}
    self.COLOR_SELECTED = {0.4, 0.4, 0.4}
end



function Tile:findNeighbors()
    if self.coords.y > 1 then
        self.neighbors[1] = self.board:getTile(self.coords + Vec2(0, -1))
    end
    if self.coords.x < 9 then
        self.neighbors[2] = self.board:getTile(self.coords + Vec2(1, 0))
    end
    if self.coords.y < 9 then
        self.neighbors[3] = self.board:getTile(self.coords + Vec2(0, 1))
    end
    if self.coords.x > 1 then
        self.neighbors[4] = self.board:getTile(self.coords + Vec2(-1, 0))
    end
end



function Tile:update(dt)
    if self.object then
        self.object:update(dt)
    end
end



function Tile:setObject(object)
    self.object = object
end



function Tile:getObject()
    return self.object
end



function Tile:getObjectType()
    if self.object then
        return self.object.TYPE
    end
end



function Tile:destroyObject()
    if self.object then
        self.object:onDestroy()
    end
    self.object = nil
end



function Tile:getPos()
    return self.board:getTilePos(self.coords)
end



function Tile:draw()
    _Display:drawRect(self:getPos(), Vec2(14), self.selected and self.COLOR_SELECTED or self.COLOR)
    if self.object then
        self.object:draw()
    end
end



function Tile:drawSelection()
    local top = not self.neighbors[1] or not self.neighbors[1].selected
    local right = not self.neighbors[2] or not self.neighbors[2].selected
    local bottom = not self.neighbors[3] or not self.neighbors[3].selected
    local left = not self.neighbors[4] or not self.neighbors[4].selected

    local sprite = _Game.SPRITES.selection
    local pos = self:getPos()
    -- Subsprite 1 is top left corner, 2 is top side, 3 is top right corner, and so on, clockwise.
    if top and left then
        _Display:drawSprite(sprite, 1, pos + Vec2(-2))
    end
    if top then
        _Display:drawSprite(sprite, 2, pos + Vec2(0, -2))
    end
    if top and right then
        _Display:drawSprite(sprite, 3, pos + Vec2(14, -2))
    end
    if right then
        _Display:drawSprite(sprite, 4, pos + Vec2(14, 0))
    end
    if bottom and right then
        _Display:drawSprite(sprite, 5, pos + Vec2(14))
    end
    if bottom then
        _Display:drawSprite(sprite, 6, pos + Vec2(0, 14))
    end
    if bottom and left then
        _Display:drawSprite(sprite, 7, pos + Vec2(-2, 14))
    end
    if left then
        _Display:drawSprite(sprite, 8, pos + Vec2(-2, 0))
    end
end



return Tile