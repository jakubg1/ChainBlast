local class = require "class"
local Explosion = require "src.Explosion"

local Chain = class:derive("Chain")

-- Place your imports here
local Vec2 = require("src.Vector2")
local Spark = require("src.Spark")



function Chain:new(board, coords)
    self.TYPE = "chain"

    self.board = board
    self.coords = coords

    -- 1 = classic, 2 = cross
    self.shape = love.math.random() < 0.1 and 2 or 1
    self.color = love.math.random(1, 3)

    -- 1 = vertical, 2 = horizontal
    self.maxRotation = 3 - self.shape
    self.rotation = love.math.random(1, self.maxRotation)
    self.savedRotation = self.rotation -- This will be brought back if temporarily rotated.
    self.rotationAnim = nil

    self.tile = nil

    self.fallTarget = nil
    self.fallSpeed = 0
end



function Chain:update(dt)
    if self.fallTarget then
        self.fallSpeed = self.fallSpeed + 20 * dt
        self.coords.y = self.coords.y + self.fallSpeed * dt
        if self.coords.y >= self.fallTarget.y then
            self.coords.y = self.fallTarget.y
            self.fallTarget = nil
            self.fallSpeed = 0
            self.board.fallingObjectCount = self.board.fallingObjectCount - 1
        end
    end

    if self.rotationAnim then
        self.rotationAnim = self.rotationAnim + 40 * dt
        if self.rotationAnim >= 4 then
            self.rotationAnim = nil
        end
    end
end



function Chain:getPos()
    return self.board:getTilePos(self.coords)
end



function Chain:hasConnection(direction)
    if self.shape == 2 then
        return true
    end
    if self.rotation == 1 then
        return direction % 2 == 1
    elseif self.rotation == 2 then
        return direction % 2 == 0
    end
end



function Chain:isConnected(direction)
    if self.fallTarget or not self:hasConnection(direction) then
        return false
    end

    local tile = self.tile:getNeighbor(direction)
    if not tile or tile:getObjectType() ~= "chain" then
        return false
    end
    local chain = tile:getObject()
    if not chain.fallTarget and self.color == chain.color and chain:hasConnection((direction + 1) % 4 + 1) then
        return true
    end
end



function Chain:getGroup(excludedCoords)
    excludedCoords = excludedCoords or {self.coords}

    for i = 1, 4 do
        if self:isConnected(i) then
            local newTile = self.tile:getNeighbor(i)
            local newCoords = newTile.coords
            local newChain = newTile:getObject()
            local duplicate = false
            for j, c in ipairs(excludedCoords) do
                if newCoords == c then
                    duplicate = true
                    break
                end
            end
            if not duplicate then
                table.insert(excludedCoords, newCoords)
                newChain:getGroup(excludedCoords)
            end
        end
    end
    return excludedCoords
end



function Chain:rotate(rotation, temporary)
    rotation = rotation or self.rotation + 1
    local newRotation = (rotation - 1) % self.maxRotation + 1

    if self.rotation ~= newRotation then
        self.rotationAnim = 1
    end
    self.rotation = newRotation
    if not temporary then
        self.savedRotation = self.rotation
    end
end



function Chain:unrotate()
    self.rotation = self.savedRotation
end



function Chain:fallTo(coords)
    self.fallTarget = coords
    self.board.fallingObjectCount = self.board.fallingObjectCount + 1
end



function Chain:onDestroy()
    local pos = self:getPos() + 7 + Vec2(love.math.randomNormal(2, 0), love.math.randomNormal(2, 0))
    for i = 1, 20 do
        table.insert(_Game.sparks, Spark(pos))
    end
    table.insert(_Game.explosions, Explosion(self:getPos() - Vec2(15)))
end



function Chain:getSubsprite()
    if self.shape == 2 then
        return 9
    end
    if self.rotationAnim then
        return ((self.rotation % 2 + 1) * 4 - 3) + math.floor(self.rotationAnim)
    end
    return self.rotation * 4 - 3
end



function Chain:draw()
    local sprite = _Game.SPRITES.chains[self.color]

    -- Draw shadows first.
    _Display:drawSprite(sprite, self:getSubsprite(), self:getPos() + Vec2(1), {0, 0, 0}, 0.25)
    if self:isConnected(1) and not self.rotationAnim then
        _Display:drawSprite(_Game.SPRITES.chainLinks[self.color], 1, self:getPos() + Vec2(6, -6) + Vec2(1), {0, 0, 0}, 0.25)
    end
    if self:isConnected(4) and not self.rotationAnim then
        _Display:drawSprite(_Game.SPRITES.chainLinksH[self.color], 1, self:getPos() + Vec2(-6, 6) + Vec2(1), {0, 0, 0}, 0.25)
    end

    -- Now the actual sprite.
    _Display:drawSprite(sprite, self:getSubsprite(), self:getPos())
    if self:isConnected(1) and not self.rotationAnim then
        _Display:drawSprite(_Game.SPRITES.chainLinks[self.color], 1, self:getPos() + Vec2(6, -6))
    end
    if self:isConnected(4) and not self.rotationAnim then
        _Display:drawSprite(_Game.SPRITES.chainLinksH[self.color], 1, self:getPos() + Vec2(-6, 6))
    end
end



return Chain