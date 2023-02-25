local class = require "class"

local Tile = class:derive("Tile")

-- Place your imports here
local Vec2 = require("src.Vector2")
local IceShard = require "src.IceShard"



function Tile:new(board, coords, popDelay)
    self.board = board
    self.coords = coords
    self.popDelay = popDelay

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
    self.iceLevel = 0
    self.iceType = nil
    self.popAnimation = nil
    self.popOutDelay = nil
    self.popOutAnimation = nil
    self.poppedOut = false

    self.debug = false
end



function Tile:update(dt)
    if self.object then
        self.object:update(dt)
    end

    if self.popDelay then
        self.popDelay = self.popDelay - dt
        if self.popDelay <= 0 then
            self.popDelay = nil
            self.popAnimation = 1
        end
    end
    if self.popAnimation then
        self.popAnimation = self.popAnimation + dt * 10
        if self.popAnimation >= 7 then
            self.popAnimation = nil
        end
    end

    if self.popOutDelay then
        self.popOutDelay = self.popOutDelay - dt
        if self.popOutDelay <= 0 then
            self.popOutDelay = nil
            self.popOutAnimation = 1
        end
    end
    if self.popOutAnimation then
        self.popOutAnimation = self.popOutAnimation + dt * 10
        if self.popOutAnimation >= 7 then
            self.popOutAnimation = nil
            self.poppedOut = true
        end
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



function Tile:damageObject()
    if self.object and not self.object.fallTarget then
        self.object:damage()
    end
end



function Tile:destroyObject()
    if self.object and not self.object.fallTarget then
        self.object:onDestroy()
        self.object = nil
    end
end



function Tile:damageIce()
    if not self.iceType then
        return
    end
    self.iceLevel = self.iceLevel - 1
    if self.iceLevel == 0 then
        self.iceType = nil
        for i = 1, 10 do
            table.insert(_Game.sparks, IceShard(self:getPos() + 7 + Vec2(love.math.randomNormal(2, 0), love.math.randomNormal(2, 0))))
        end
    end
    for i = 1, 5 do
        table.insert(_Game.sparks, IceShard(self:getPos() + 7 + Vec2(love.math.randomNormal(2, 0), love.math.randomNormal(2, 0))))
    end
    _Game.SOUNDS.iceBreak:play()
end



function Tile:evaporateIce()
    -- Skip the effect, water evaporates!
    self.iceLevel = 0
    self.iceType = nil
end



function Tile:makeGold()
    if self.gold then
        return
    end
    self.gold = true
    self.goldAnimation = 0
end



function Tile:impact()
    if self.iceType then
        self:damageIce()
    elseif not self.gold then
        self:makeGold()
    end
end



function Tile:popOut(delay)
    self.popOutDelay = delay
end



function Tile:setDebug(debug)
    self.debug = debug
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



function Tile:getAlpha()
    if self.popDelay or self.poppedOut then
        return 0
    elseif self.popAnimation then
        return (self.popAnimation - 1) / 6
    elseif self.popOutAnimation then
        return (7 - self.popOutAnimation) / 6
    end
    return 1
end



function Tile:getSubsprite()
    --if self.popAnimation then
    --    return 9 + math.floor(self.popAnimation)
    --end
    if self.gold then
        if self.goldAnimation then
            return 3 + math.floor(self.goldAnimation)
        end
        return 2
    end
    if self.iceType == 1 then
        return 18 - self.iceLevel
    elseif self.iceType == 2 then
        return 21 - self.iceLevel
    end
    return 1
end



function Tile:draw()
    if self.popDelay or self.poppedOut then
        -- This Tile has not popped up yet or has already been popped out.
        return
    end

    local subsprite = self:getSubsprite()
    local pos = self:getPos()
    --if subsprite >= 13 and subsprite <= 15 then
    --    pos = pos - Vec2(1)
    --    if subsprite == 14 then
    --        pos = pos - Vec2(1)
    --    end
    --end
    _Display:drawSprite(_Game.SPRITES.tiles, subsprite, pos, nil, self:getAlpha())

    if self:isSelected() then
        _Display:drawRect(self:getPos(), Vec2(14), true, {1, 1, 1}, 0.4)
    end
    if self.debug then
        _Display:drawRect(self:getPos(), Vec2(14), true, {0, 0, 1}, 0.4)
    end

    -- Debug side code
--[[
    local color = {1, 0.5, 0}
    if self:isSideSelected(1) then
        _Display:drawRect(self:getPos(), Vec2(14, 2), true, color)
    end
    if self:isSideSelected(2) then
        _Display:drawRect(self:getPos() + Vec2(12, 0), true, Vec2(2, 14), color)
    end
    if self:isSideSelected(3) then
        _Display:drawRect(self:getPos() + Vec2(0, 12), true, Vec2(14, 2), color)
    end
    if self:isSideSelected(4) then
        _Display:drawRect(self:getPos(), Vec2(2, 14), true, color)
    end
    ]]
end



function Tile:drawObject()
    if self.object then
        self.object:draw()
    end
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