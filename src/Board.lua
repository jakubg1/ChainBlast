local class = require "class"

local Board = class:derive("Board")

-- Place your imports here
local Vec2 = require("src.Vector2")
local Tile = require("src.Tile")
local Chain = require("src.Chain")
local Crate = require("src.Crate")



function Board:new(level, layout)
    self.level = level
    self.layout = layout

    self.SIZE = Vec2(9)
    self.DIRECTIONS = {
        Vec2(0, -1),
        Vec2(1, 0),
        Vec2(0, 1),
        Vec2(-1, 0)
    }
    self.TILE_IDS = {
        {0, 0},
        {1, 0},
        {2, 0},
        {0, 1},
        {0, 2},
        {0, 3},
        {1, 2},
        {2, 3}
    }

    -- Tile coordinates go from (1, 1) to (9, 9).
    -- Each tile can be:
    --  - nil - no tile there;
    --  - Tile - tile there. Contents in a separate class.
    self.tiles = {}

    self.playerControl = true
    self.over = false
    self.hoverCoords = nil
    self.selecting = false
    self.selectedCoords = {}
    self.selectedDirections = {}
    -- It might be the case that we cross an already selected tile. In such case, this will not necessarily be the last entry in the selectedCoords table.
    self.selectingDirection = nil
    self.hintTime = 0
    self.hintCoords = nil

    self.fallingObjectCount = 0
    self.shufflingChainCount = 0
    self.rotatingChainCount = 0

    self.startAnimation = 0
    self.endAnimation = nil

    self:fill()
    _Game.SOUNDS.boardStart:play()
end


function Board:update(dt)
    -- Start animation
    if self.startAnimation then
        self.startAnimation = self.startAnimation + dt
        if self.startAnimation >= 4 then
            self.startAnimation = nil
        end
    end

    -- End animation
    if self.endAnimation then
        self.endAnimation = self.endAnimation + dt
        if self.endAnimation >= 4 then
            self.endAnimation = nil
            self.level:onBoardEnd()
        end
    end

    -- Game control
    if self.fallingObjectCount > 0 or self.shufflingChainCount > 0 or self.over then
        self.playerControl = false
    end

    if not self.playerControl and self.fallingObjectCount == 0 and self.shufflingChainCount == 0 and self.rotatingChainCount == 0 and not self.over then
        -- Do another shot.
        self:handleMatches()
        self:fillHoles()
        self:fillHolesUp()
        if self.fallingObjectCount == 0 and self.shufflingChainCount == 0 and self.rotatingChainCount == 0 then
            -- Nothing happened, grant the control to the player.
            if self:isTargetReached() then
                self:releaseChains()
                self.level:win()
            elseif not self:areMovesAvailable() then
                self:shuffle()
            else
                self.playerControl = true
                self.level.combo = 0
            end
        end
    end

    -- Tile hovering
    self.hoverCoords = nil
    if self.playerControl then
        local hoverCoords = self:getTileCoords(_Display.mousePos)
        if self:getTile(hoverCoords) then
            self.hoverCoords = hoverCoords
        end
        if not self.hintCoords then
            self.hintTime = self.hintTime + dt
            if self.hintTime >= 3 then
                self.hintCoords = self:getRandomMatchableTile().coords
                _Game.SOUNDS.hint:play()
            end
        end
    end

    -- Tile selecting
    if self.selecting and self.hoverCoords then
        local lastSelectedCoords = self.selectedCoords[#self.selectedCoords]
        if lastSelectedCoords then
            for i = 1, 4 do
                if lastSelectedCoords + self.DIRECTIONS[i] == self.hoverCoords then
                    if self.hoverCoords == self.selectedCoords[#self.selectedCoords - 1] then
                        -- We are going backwards!
                        self:shrinkSelection(i)
                    else
                        self:expandSelection(i)
                    end
                    break
                elseif lastSelectedCoords + self.DIRECTIONS[i] * 2 == self.hoverCoords then
                    -- Allow double expansions, for extra fast sweeps.
                    if self.hoverCoords == self.selectedCoords[#self.selectedCoords - 2] then
                        -- We are going backwards!
                        self:shrinkSelection(i)
                        self:shrinkSelection(i)
                    else
                        self:expandSelection(i)
                        self:expandSelection(i)
                    end
                    break
                end
            end
        else
            self:startSelection()
        end
    end

    -- Tile update
    for i = 1, self.SIZE.x do
        for j = 1, self.SIZE.y do
            local tile = self:getTile(Vec2(i, j))
            if tile then
                tile:update(dt)
            end
        end
    end
end



function Board:getTile(coords)
    if coords.x < 1 or coords.y < 1 or coords.x > self.SIZE.x or coords.y > self.SIZE.y then
        return nil
    end
    return self.tiles[coords.x][coords.y]
end



function Board:getTilePos(coords)
    return coords * 15 + Vec2(64, -14)
end



function Board:getTileCoords(pos)
    return ((pos - Vec2(64, -14)) / 15):floor()
end



function Board:fill()
    -- We will fill the board repeatedly until no premade matches exist.
    repeat
        for i = 1, 9 do
            self.tiles[i] = {}
            for j = 1, 9 do
                local tileID = self.layout[j][i]
                if tileID > 0 then
                    local coords = Vec2(i, j)
                    local tile = Tile(self, coords:clone(), (i + j) * 0.12)
                    local tileParams = self.TILE_IDS[tileID]
                    local object = nil
                    if tileParams[1] == 0 then
                        object = Chain(self, coords:clone())
                    else
                        object = Crate(self, coords:clone(), tileParams[1])
                    end
                    if tileParams[2] == 1 or tileParams[2] == 2 then
                        tile.iceType = 1
                        tile.iceLevel = tileParams[2]
                    elseif tileParams[2] == 3 then
                        tile.iceType = 2
                        tile.iceLevel = tileParams[2]
                    end
                    tile:setObject(object)
                    self.tiles[i][j] = tile
                end
            end
        end
    until #self:getMatchGroups() == 0 and self:areMovesAvailable()

    -- Move all the chains up and animate them accordingly.
    for i = 1, 9 do
        for j = 1, 9 do
            local coords = Vec2(i, j)
            local chain = self:getTile(coords) and self:getTile(coords):getChain()
            if chain then
                chain.coords = coords - Vec2(0, 10)
                chain:fallTo(coords, 2.5 + (i - 1) * 0.1)
            end
        end
    end
end



function Board:startSelection()
    local tile = self:getTile(self.hoverCoords)
    if tile and tile:getChain() then
        tile:select()
        table.insert(self.selectedCoords, self.hoverCoords)
    end
end



function Board:expandSelection(direction)
    local oppositeDirection = (direction + 1) % 4 + 1

    local newCoords = self.selectedCoords[#self.selectedCoords] + self.DIRECTIONS[direction]
    local tile = self:getTile(newCoords)
    local prevTile = self:getTile(self.selectedCoords[#self.selectedCoords])

    if tile and tile:getChain() and not tile:isSideSelected(oppositeDirection) and (not prevTile or not prevTile:getChain() or prevTile:getChain():matchesWithColor(tile:getChain().color)) then
        tile:select()
        tile:selectSide(oppositeDirection)
        tile:getChain():rotate(oppositeDirection, true)
        if prevTile and prevTile:getChain() then
            prevTile:selectSide(direction, true)
            if #self.selectedCoords == 1 then
                -- If we are selecting the second tile, the first one gets rotated as well!
                prevTile:getChain():rotate(oppositeDirection, true)
            end
        end
        table.insert(self.selectedCoords, newCoords)
        table.insert(self.selectedDirections, direction)
    end
end



function Board:shrinkSelection(direction)
    local oppositeDirection = (direction + 1) % 4 + 1

    local newCoords = self.selectedCoords[#self.selectedCoords] + self.DIRECTIONS[direction]
    local tile = self:getTile(newCoords)
    local prevTile = self:getTile(self.selectedCoords[#self.selectedCoords]) -- This tile will be unselected.

    if prevTile and prevTile:getChain() then
        prevTile:unselectSide(direction)
        if not prevTile:areSidesSelected() then
            prevTile:unselect()
            prevTile:getChain():unrotate()
        end
        if tile and tile:getChain() then
            tile:unselectSide(oppositeDirection)
        end
        table.remove(self.selectedCoords)
        table.remove(self.selectedDirections)
    end
end



function Board:finishSelection()
    for i, coords in ipairs(self.selectedCoords) do
        local tile = self:getTile(coords)
        assert(tile, string.format("Tried selecting a nonexistent tile on %s", coords))
        tile:unselect()
        tile:unselectSides()
    end
    self.selecting = false
    self.selectedCoords = {}
    self.selectedDirections = {}
    self:handleMatches()
    self:fillHoles()
    self:fillHolesUp()
    -- Unrotate all chains.
    for i = 1, self.SIZE.x do
        for j = 1, self.SIZE.y do
            local coords = Vec2(i, j)
            local tile = self:getTile(coords)
            if tile then
                local chain = tile:getChain()
                if chain then
                    chain:unrotate()
                end
            end
        end
    end
end



function Board:getMatchGroups()
    -- Store the groups themselves.
    local groups = {}
    -- All coordinates that have been used up already end up in this cumulative list too.
    local excludedCoords = {}

    for i = 1, self.SIZE.x do
        for j = 1, self.SIZE.y do
            local coords = Vec2(i, j)
            local tile = self:getTile(coords)
            if tile then
                local chain = tile:getChain()
                if chain then
                    local group = chain:getGroup()
                    -- If the group has at least three pieces, start storing.
                    if #group >= 3 then
                        local duplicate = false
                        -- 2 in 1: check for duplicates, and add the coordinates to the list so they can't be used up later.
                        for k, currentCoords in ipairs(group) do
                            for l, oldCoords in ipairs(excludedCoords) do
                                if currentCoords == oldCoords then
                                    duplicate = true
                                    break
                                end
                            end
                            if duplicate then
                                break
                            end
                            table.insert(excludedCoords, currentCoords)
                        end
                        if not duplicate then
                            table.insert(groups, group)
                        end
                    end
                end
            end
        end
    end

    return groups
end



function Board:handleMatches()
    for i, match in ipairs(self:getMatchGroups()) do
        for j, coords in ipairs(match) do
            local tile = self:getTile(coords)
            assert(tile, string.format("Tried selecting a nonexistent tile on %s", coords))
            tile:destroyObject()
            if tile.gold then
                self.level:addToBombMeter(1)
            end
            tile:impact()
            -- Remove all adjacent crates.
            for k = 1, 4 do
                local adjTile = self:getTile(coords + self.DIRECTIONS[k])
                if adjTile and adjTile:getObjectType() == "crate" then
                    adjTile:damageObject()
                end
            end
        end
        self.level:addCombo()
        local multiplier = (self.level.combo * (self.level.combo + 1)) / 2
        self.level:addScore((#match - 2) * 100 * multiplier)
        if #match > 3 then
            self.level:addTime(#match - 3)
        end
        self.level.largestGroup = math.max(self.level.largestGroup, #match)
        _Game.SOUNDS.chainDestroy:play()
        if self.level.combo > 1 then
            _Game.SOUNDS.combo:play(1, 0.65 + (self.level.combo - 2) * 0.1)
        end
        --if #match > 4 then
        --    _Game.SOUNDS.chainDestroyBig:play()
        --end

        self.level:startTimer()
        self.hintCoords = nil
        self.hintTime = 0
    end
end



function Board:fillHoles()
    for i = 1, self.SIZE.x do
        for j = self.SIZE.y, 0, -1 do
            local coords = Vec2(i, j)
            local tile = self:getTile(coords)
            if tile and not tile:getObject() then
                for k = j - 1, 0, -1 do
                    local seekCoords = Vec2(i, k)
                    local seekTile = self:getTile(seekCoords)
                    if seekTile and seekTile:getObjectType() == "chain" then
                        local seekObject = seekTile:getObject()
                        seekTile:setObject()
                        tile:setObject(seekObject)
                        seekObject:fallTo(coords)
                        break
                    end
                end
            end
        end
    end
end



function Board:fillHolesUp()
    for i = 1, self.SIZE.x do
        local tilesPlaced = 0
        for j = self.SIZE.y, 0, -1 do
            local coords = Vec2(i, j)
            local tile = self:getTile(coords)
            if tile and not tile:getObject() then
                local chain = Chain(self, Vec2(coords.x, -1 - tilesPlaced))
                chain:fallTo(coords)
                tile:setObject(chain)
                tilesPlaced = tilesPlaced + 1
            end
        end
    end
end



function Board:explodeBomb(bombCoords)
    for i = -1, 1 do
        for j = -1, 1 do
            local coords = bombCoords + Vec2(i, j)
            local tile = self:getTile(coords)
            if tile then
                tile:evaporateIce()
                if tile:getObject() and not tile:getObject().shuffleTarget then
                    if tile:getChain() then
                        --local distance = math.abs(i) + math.abs(j)                    (3 - distance)
                        tile:impact()
                        self.level:addScore(100)
                    end
                    tile:destroyObject()
                end
            end
        end
    end
    self:fillHoles()
    self:fillHolesUp()
    _Game.SOUNDS.explosion2:play()
end



function Board:areMovesAvailable()
    for i = 1, self.SIZE.x do
        for j = 1, self.SIZE.y do
            local coords = Vec2(i, j)
            local tile = self:getTile(coords)
            if tile then
                local chain = tile:getChain()
                if chain and chain:canMakeMatch() then
                    return true
                end
            end
        end
    end
    return false
end



function Board:shuffle()
    local coordsList = {}
    local chains = {}

    for i = 1, self.SIZE.x do
        for j = 1, self.SIZE.y do
            local coords = Vec2(i, j)
            local tile = self:getTile(coords)
            if tile then
                local chain = tile:getChain()
                if chain then
                    table.insert(coordsList, coords)
                    table.insert(chains, chain)
                end
            end
        end
    end

    repeat
        local shuffledCoords = {}
        for i, coords in ipairs(coordsList) do
            table.insert(shuffledCoords, love.math.random(1, #shuffledCoords + 1), coords)
        end

        for i = 1, #shuffledCoords do
            local coords = shuffledCoords[i]
            local chain = chains[i]
            self:getTile(coords):setObject(chain)
            chain:shuffleTo(coords)
        end
    until self:areMovesAvailable()

    _Game.SOUNDS.shuffle:play()
end



function Board:isTargetReached()
    for i = 1, self.SIZE.x do
        for j = 1, self.SIZE.y do
            local coords = Vec2(i, j)
            local tile = self:getTile(coords)
            if tile and not tile.gold then
                return false
            end
        end
    end
    return true
end



function Board:getRandomNonGoldTile(excludedCoords)
    excludedCoords = excludedCoords or {}

    local tiles = {}
    for i = 1, self.SIZE.x do
        for j = 1, self.SIZE.y do
            local coords = Vec2(i, j)
            local excluded = false
            for k, coordsE in ipairs(excludedCoords) do
                if coords == coordsE then
                    excluded = true
                    break
                end
            end
            if not excluded then
                local tile = self:getTile(coords)
                if tile and not tile.gold then
                    table.insert(tiles, tile)
                end
            end
        end
    end
    if #tiles == 0 then
        return
    end
    return tiles[love.math.random(#tiles)]
end



function Board:getRandomMatchableTile()
    local tiles = {}
    for i = 1, self.SIZE.x do
        for j = 1, self.SIZE.y do
            local coords = Vec2(i, j)
            local tile = self:getTile(coords)
            if tile then
                local chain = tile:getChain()
                if chain and chain:canMakeMatch() then
                    table.insert(tiles, tile)
                end
            end
        end
    end
    if #tiles == 0 then
        return
    end
    return tiles[love.math.random(#tiles)]
end



function Board:releaseChains()
    for i = 1, self.SIZE.x do
        for j = 1, self.SIZE.y do
            local coords = Vec2(i, j)
            local tile = self:getTile(coords)
            if tile then
                local chain = tile:getChain()
                if chain then
                    chain:release()
                end
            end
        end
    end
end



function Board:panicChains()
    self.over = true
    for i = 1, self.SIZE.x do
        for j = 1, self.SIZE.y do
            local coords = Vec2(i, j)
            local tile = self:getTile(coords)
            if tile then
                local chain = tile:getChain()
                if chain then
                    chain:panic()
                end
            end
        end
    end
end



function Board:nukeEverything()
    for i = 1, self.SIZE.x do
        for j = 1, self.SIZE.y do
            local coords = Vec2(i, j)
            local tile = self:getTile(coords)
            if tile then
                tile:destroyObject()
            end
        end
    end
    self.hintCoords = nil
    _Game.SOUNDS.explosion:play()
end



function Board:launchEndAnimation()
    self.endAnimation = 0
    for i = 1, self.SIZE.x do
        for j = 1, self.SIZE.y do
            local coords = Vec2(i, j)
            local tile = self:getTile(coords)
            if tile then
                tile:popOut((i + j - 2) * 0.12)
            end
        end
    end
    _Game.SOUNDS.boardEnd:play()
end



function Board:draw()
    local color = {0.75, 0.75, 0.75}

    -- Horizontal lines
    for i = 0, self.SIZE.y do
        -- Bounds
        local a = 1
        local b = 10
        if self.startAnimation then
            b = math.max(math.min((self.startAnimation * 9) - i, 10), 1)
        end
        if self.endAnimation then
            a = math.max(math.min(((self.endAnimation - 0.2) * 9) - i, 10), 1)
        end
        -- Chunks
        for j = 1, 9 do
            -- Chunk 1 goes from 1 to 2, chunk 2 goes from 2 to 3, etc.
            if a < j + 1 and b > j and (self:getTile(Vec2(j, i)) or self:getTile(Vec2(j, i + 1))) then
                _Display:drawLine(self:getTilePos(Vec2(math.max(a, j), i + 1)) - Vec2(1), self:getTilePos(Vec2(math.min(b, j + 1), i + 1)) - Vec2(0, 1), color)
            end
        end
    end

    -- Vertical lines
    for i = 0, self.SIZE.x do
        -- Bounds
        local a = 1
        local b = 10
        if self.startAnimation then
            b = math.max(math.min(((self.startAnimation - 0.2) * 9) - i, 10), 1)
        end
        if self.endAnimation then
            a = math.max(math.min(((self.endAnimation - 0.4) * 9) - i, 10), 1)
        end
        -- Chunks
        for j = 1, 9 do
            -- Chunk 1 goes from 1 to 2, chunk 2 goes from 2 to 3, etc.
            if a < j + 1 and b > j and (self:getTile(Vec2(i, j)) or self:getTile(Vec2(i + 1, j))) then
                _Display:drawLine(self:getTilePos(Vec2(i + 1, math.max(a, j))) - Vec2(1, 2), self:getTilePos(Vec2(i + 1, math.min(b, j + 1))) - Vec2(1), color)
            end
        end
    end


    -- Tiles
    for i = 1, self.SIZE.x do
        for j = 1, self.SIZE.y do
            local tile = self:getTile(Vec2(i, j))
            if tile then
                tile:draw()
            end
        end
    end

    -- Objects
    for i = 1, self.SIZE.x do
        for j = 1, self.SIZE.y do
            local tile = self:getTile(Vec2(i, j))
            if tile then
                tile:drawObject()
            end
        end
    end

    -- Selection frame
    for i = 1, self.SIZE.x do
        for j = 1, self.SIZE.y do
            local tile = self:getTile(Vec2(i, j))
            if tile and tile:isSelected() then
                tile:drawSelection()
            end
        end
    end

    -- Hint sprite
    if self.hintCoords then
        _Display:drawSprite(_Game.SPRITES.hint, math.floor((_Time * 15) % 10) + 1, self:getTilePos(self.hintCoords) - 2, _GetRainbowColor(_Time / 2))
    end

    -- Hover sprite
    if self.hoverCoords and not self.selecting and not self.level.pause then
        _Display:drawSprite(_Game.SPRITES.hover, math.floor(math.sin(_Time * 3) * 2 + 2) + 1, self:getTilePos(self.hoverCoords) - 5)
    end
end



function Board:mousepressed(x, y, button)
    if button == 1 then
        if self.hoverCoords and self:getTile(self.hoverCoords) and self:getTile(self.hoverCoords):getChain() then
            self.selecting = true
        end
    elseif button == 2 and false then
        -- debug
        local coords = self:getTileCoords(_Display.mousePos)
        if coords then
            --local tile = self:getTile(coords)
            --if tile and tile:getObjectType() == "chain" then
            --    tile:getObject():rotate()
            --end
            self.level:spawnBomb(coords)
        end
    end
end



function Board:mousereleased(x, y, button)
    if button == 1 then
        if self.selecting then
            self:finishSelection()
        end
    end
end



return Board