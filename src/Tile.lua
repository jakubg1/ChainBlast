local class = require "class"

local Tile = class:derive("Tile")

-- Place your imports here
local Vec2 = require("src.Vector2")



function Tile:new(board, coords)
    self.board = board
    self.coords = coords

    self.SELECTION_ARROW_OFFSETS = {
        Vec2(3, -3),
        Vec2(12, 3),
        Vec2(3, 12),
        Vec2(-3, 3)
    }

    self.object = nil
    self.selected = false
    self.selectedSides = {false, false, false, false}
    self.selectionArrows = {false, false, false, false}

    self.gold = false
    self.goldAnimation = nil
end



function Tile:update(dt)
    if self.object then
        self.object:update(dt)
    end
    if self.goldAnimation then
        self.goldAnimation = self.goldAnimation + dt * 10
        if self.goldAnimation >= 7 then
            self.goldAnimation = nil
        end
    end
end



function Tile:setObject(object)
    self.object = object
    if object then
        object.tile = self
    end
end



function Tile:getObject()
    return self.object
end



function Tile:getChain()
    if self:getObjectType() ~= "chain" then
        return nil
    end
    return self:getObject()
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



function Tile:makeGold()
    if self.gold then
        return
    end
    self.gold = true
    self.goldAnimation = 0
end



function Tile:getPos()
    return self.board:getTilePos(self.coords)
end



function Tile:getNeighbor(direction)
    return self.board:getTile(self.coords + self.board.DIRECTIONS[direction])
end



function Tile:select()
    self.selected = true
end



function Tile:unselect()
    self.selected = false
end



function Tile:isSelected()
    return self.selected
end



function Tile:selectSide(direction, visual)
    self.selectedSides[direction] = true
    if visual then
        self.selectionArrows[direction] = true
    end
end



function Tile:unselectSide(direction)
    self.selectedSides[direction] = false
    self.selectionArrows[direction] = false
end



function Tile:unselectSides()
    self.selectedSides = {false, false, false, false}
    self.selectionArrows = {false, false, false, false}
end



function Tile:isSideSelected(direction)
    return self.selectedSides[direction]
end



function Tile:areSidesSelected(direction)
    return self.selectedSides[1] or self.selectedSides[2] or self.selectedSides[3] or self.selectedSides[4]
end



function Tile:getSubsprite()
    if self.gold then
        if self.goldAnimation then
            return 4 + math.floor(self.goldAnimation)
        end
        return 3
    end
    return 1
end



function Tile:draw()
    _Display:drawSprite(_Game.SPRITES.tiles, self:getSubsprite(), self:getPos())
    if self:isSelected() then
        _Display:drawRect(self:getPos(), Vec2(14), {1, 1, 1}, 0.4)
    end
    if self.object then
        self.object:draw()
    end
--[[
    local color = {1, 0.5, 0}
    if self:isSideSelected(1) then
        _Display:drawRect(self:getPos(), Vec2(14, 2), color)
    end
    if self:isSideSelected(2) then
        _Display:drawRect(self:getPos() + Vec2(12, 0), Vec2(2, 14), color)
    end
    if self:isSideSelected(3) then
        _Display:drawRect(self:getPos() + Vec2(0, 12), Vec2(14, 2), color)
    end
    if self:isSideSelected(4) then
        _Display:drawRect(self:getPos(), Vec2(2, 14), color)
    end
    ]]
end



function Tile:drawSelection()
    local bounds = {}
    for i = 1, 4 do
        bounds[i] = not self:getNeighbor(i) or not self:getNeighbor(i):isSelected()
    end
    local top, right, bottom, left = unpack(bounds)

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

    for i = 1, 4 do
        if self.selectionArrows[i] then
            _Display:drawSprite(_Game.SPRITES.selectionArrows, i, pos + self.SELECTION_ARROW_OFFSETS[i])
        end
    end
end



return Tile