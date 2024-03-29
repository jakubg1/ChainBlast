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

    self.tile = nil

    -- 1 = classic, 2 = cross
    self.shape = love.math.random() < 0.1 and 2 or 1
    -- 0 = rainbow
    self.color = love.math.random() < 0.05 and 0 or love.math.random(1, 3)

    -- 1 = vertical, 2 = horizontal
    self.maxRotation = 3 - self.shape
    self.rotation = love.math.random(1, self.maxRotation)
    self.savedRotation = self.rotation -- This will be brought back if temporarily rotated.
    self.rotationAnim = nil

    self.fallTarget = nil
    self.fallSpeed = 0
    self.fallDelay = nil
    self.shuffleStart = nil
    self.shuffleTarget = nil
    self.shuffleTime = 0
    self.releasePos = nil
    self.releaseSpeed = nil
    self.releaseTime = nil
    self.panicTime = nil
    self.panicOffset = Vec2()



    self.LINK_OFFSETS = {
        Vec2(6, 0),
        Vec2(8, 6),
        Vec2(6, 8),
        Vec2(0, 6)
    }
    self.LINK_SUBSPRITES = {2, 1, 1, 2}
end



function Chain:update(dt)
    if self.rotationAnim then
        self.rotationAnim = self.rotationAnim + 40 * dt
        if self.rotationAnim >= 4 then
            self.rotationAnim = nil
        end
    end
    
    if self.fallTarget then
        if self.fallDelay then
            self.fallDelay = self.fallDelay - dt
            if self.fallDelay <= 0 then
                self.fallDelay = nil
            end
        end
        if not self.fallDelay then
            self.fallSpeed = self.fallSpeed + 20 * dt
            self.coords.y = self.coords.y + self.fallSpeed * dt
            if self.coords.y >= self.fallTarget.y then
                self.coords.y = self.fallTarget.y
                self.fallTarget = nil
                self.fallSpeed = 0
                self.board.fallingObjectCount = self.board.fallingObjectCount - 1
                -- Play the landing sound only when there's no falling chain below.
                if not self.tile:getNeighbor(3) or not self.tile:getNeighbor(3):getChain() or not self.tile:getNeighbor(3):getChain().fallDelay then
                    _Game.SOUNDS.chainLand:play()
                end
            end
        end
    end

    if self.shuffleTarget then
        self.shuffleTime = self.shuffleTime + dt
        local t = 0
        if self.shuffleTime > 0 then
            t = 1 - math.sin((1 - self.shuffleTime / 0.5) * (math.pi / 2))
        end
        self.coords = self.shuffleStart * (1 - t) + self.shuffleTarget * t
        if self.shuffleTime >= 0.5 then
            self.coords = self.shuffleTarget
            self.shuffleStart = nil
            self.shuffleTarget = nil
            self.shuffleTime = 0
            self.board.shufflingChainCount = self.board.shufflingChainCount - 1
        end
    end

    if self.releaseSpeed then
        self.releaseTime = self.releaseTime + dt
        self.releaseSpeed = self.releaseSpeed + Vec2(0, self.releaseTime * 3.75)
        self.releasePos = self.releasePos + self.releaseSpeed * dt
    end

    if self.panicTime then
        self.panicTime = self.panicTime + dt
        self.panicOffset = Vec2(love.math.randomNormal(self.panicTime), love.math.randomNormal(self.panicTime))
    end
end



function Chain:getPos()
    if self.releasePos then
        return self.releasePos
    end
    return self.board:getTilePos(self.coords) + self.panicOffset
end



function Chain:matchesWithColor(color)
    return self.color == color or self.color == 0 or color == 0
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
    if self.fallTarget or self.shuffleTarget or self.releaseSpeed or not self:hasConnection(direction) then
        return false
    end

    local tile = self.tile:getNeighbor(direction)
    if not tile or tile:getObjectType() ~= "chain" then
        return false
    end
    local chain = tile:getObject()
    if not chain.fallTarget and self:matchesWithColor(chain.color) and chain:hasConnection((direction + 1) % 4 + 1) then
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



function Chain:canMakeMatch(directions)
    if not directions then
        if self.shape == 1 then
            return self:canMakeMatch({1, 3}) or self:canMakeMatch({2, 4})
        elseif self.shape == 2 then
            return self:canMakeMatch({1, 2, 3, 4})
        end
    end

    local potentialConnections = 0
    for i, direction in ipairs(directions) do
        local tile = self.tile:getNeighbor(direction)
        if tile then
            local chain = tile:getChain()
            if chain and self:matchesWithColor(chain.color) then
                potentialConnections = potentialConnections + 1
            end
        end
        if potentialConnections >= 2 then
            return true
        end
    end
    return false
end



function Chain:rotate(rotation, temporary)
    rotation = rotation or self.rotation + 1
    local newRotation = (rotation - 1) % self.maxRotation + 1

    if self.rotation ~= newRotation then
        self.rotationAnim = 1
        _Game.SOUNDS.chainRotate:play()
    end
    self.rotation = newRotation
    if not temporary then
        self.savedRotation = self.rotation
    end
end



function Chain:unrotate()
    self.rotation = self.savedRotation
end



function Chain:fallTo(coords, delay)
    if not self.fallTarget then
        self.board.fallingObjectCount = self.board.fallingObjectCount + 1
    end
    self.fallTarget = coords
    self.fallDelay = delay
end



function Chain:shuffleTo(coords)
    if not self.shuffleTarget then
        self.board.shufflingChainCount = self.board.shufflingChainCount + 1
    end
    self.shuffleStart = self.coords
    self.shuffleTarget = coords
    self.shuffleTime = love.math.random() * -0.5
end



function Chain:release()
    self.board.fallingObjectCount = self.board.fallingObjectCount + 1
    self.releasePos = self:getPos()
    self.releaseSpeed = Vec2(love.math.random() * 75 - 37.5, love.math.random() * -37.5 - 75)
    self.releaseTime = 0
end



function Chain:panic()
    self.panicTime = 0
end



function Chain:onDestroy()
    for i = 1, 20 do
        table.insert(_Game.sparks, Spark(self:getPos() + 7 + Vec2(love.math.randomNormal(2, 0), love.math.randomNormal(2, 0))))
    end
    table.insert(_Game.explosions, Explosion(self:getPos() - Vec2(15)))
    if not self.panicTime then
        _Game.chainsDestroyed = _Game.chainsDestroyed + 1
    end
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
    if not self.rotationAnim then
        for i = 1, 4 do
            if self:isConnected(i) then
                local linkSprite = (i % 2 == 1) and _Game.SPRITES.chainLinks[self.color] or _Game.SPRITES.chainLinksH[self.color]
                _Display:drawSprite(linkSprite, self.LINK_SUBSPRITES[i], self:getPos() + self.LINK_OFFSETS[i] + Vec2(1), {0, 0, 0}, 0.25)
            end
        end
    end

    -- Now the actual sprite.
    _Display:drawSprite(sprite, self:getSubsprite(), self:getPos())
    if not self.rotationAnim then
        for i = 1, 4 do
            if self:isConnected(i) then
                local linkSprite = (i % 2 == 1) and _Game.SPRITES.chainLinks[self.color] or _Game.SPRITES.chainLinksH[self.color]
                _Display:drawSprite(linkSprite, self.LINK_SUBSPRITES[i], self:getPos() + self.LINK_OFFSETS[i])
            end
        end
    end
    _Display:drawSprite(_Game.SPRITES.powerups, 1, self:getPos())
end



return Chain