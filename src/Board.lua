local class = require "class"

local Board = class:derive("Board")

-- Place your imports here
local Vec2 = require("src.Vector2")
local Tile = require("src.Tile")
local Chain = require("src.Chain")



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
        local hoverCoords = self:getTileCoords(_MousePos)
        if hoverCoords.x >= 1 and hoverCoords.y >= 1 and hoverCoords.x <= self.SIZE.x and hoverCoords.y <= self.SIZE.y then
            self.hoverCoords = hoverCoords
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
    return coords * 15 + Vec2(44, -6)
end



function Board:getTileCoords(pos)
    return ((pos - Vec2(44, -6)) / 15):floor()
end



function Board:fill()
    -- We will fill the board repeatedly until no premade matches exist.
    repeat
        for i = 1, 9 do
            self.tiles[i] = {}
            for j = 1, 9 do
                --if i + j >= 7 and i + j <= 13 then
                if self.layout[j][i] == 1 then
                    local coords = Vec2(i, j)
                    local tile = Tile(self, coords:clone(), (i + j) * 0.12)
                    local chain = Chain(self, coords:clone())
                    tile:setObject(chain)
                    self.tiles[i][j] = tile
                end
            end
        end
    until #self:getMatchGroups() == 0

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
            tile:makeGold()
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

        self.level:startTimer()
    end
end



function Board:fillHoles()
    for i = 1, self.SIZE.x do
        for j = self.SIZE.y, 0, -1 do
            local coords = Vec2(i, j)
            local tile = self:getTile(coords)
            if tile and tile:getObjectType() ~= "chain" then
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
            if tile and tile:getObjectType() ~= "chain" then
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
            if tile and tile:getObject() and not tile:getObject().shuffleTarget then
                if tile:getChain() then
                    tile:makeGold()
                    self.level:addScore(100)
                end
                tile:destroyObject()
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



function Board:getRandomNonGoldTile()
    local tiles = {}
    for i = 1, self.SIZE.x do
        for j = 1, self.SIZE.y do
            local coords = Vec2(i, j)
            local tile = self:getTile(coords)
            if tile and not tile.gold then
                table.insert(tiles, tile)
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



function Board:lose()
    self.over = true
    self:panicChains()
end



function Board:panicChains()
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
        local y = 8 + i * 15
        local w = 136
        if self.startAnimation then
            w = math.max(math.min((self.startAnimation * 125) - 15 * i, 136), 0)
        elseif self.endAnimation then
            w = -math.max(math.min(((self.endAnimation - 0.2) * 125) - 15 * i, 136), 0)
        end
        if w > 0 then
            _Display:drawLine(Vec2(58, y), Vec2(58 + w, y), color)
        elseif w < 0 or self.endAnimation then
            _Display:drawLine(Vec2(58 - w, y), Vec2(194, y), color)
        end
    end
    -- Vertical lines
    for i = 0, self.SIZE.x do
        local x = 58 + i * 15
        local h = 135
        if self.startAnimation then
            h = math.max(math.min(((self.startAnimation - 0.2) * 125) - 15 * i, 135), 0)
        elseif self.endAnimation then
            h = -math.max(math.min(((self.endAnimation - 0.4) * 125) - 15 * i, 135), 0)
        end
        if h > 0 then
            _Display:drawLine(Vec2(x, 8), Vec2(x, 8 + h), color)
        elseif h < 0 or self.endAnimation then
            _Display:drawLine(Vec2(x, 8 - h), Vec2(x, 143), color)
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

    -- Hover sprite
    if self.hoverCoords and not self.selecting then
        _Display:drawSprite(_Game.SPRITES.hover, math.floor(math.sin(_Time * 3) * 2 + 2) + 1, self:getTilePos(self.hoverCoords) - 5)
    end
end



function Board:mousepressed(x, y, button)
    if button == 1 then
        if self.hoverCoords and self:getTile(self.hoverCoords) and self:getTile(self.hoverCoords):getChain() then
            self.selecting = true
        end
    elseif button == 2 then
        local coords = self:getTileCoords(_MousePos)
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