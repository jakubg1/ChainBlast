local class = require "class"

local Board = class:derive("Board")

-- Place your imports here
local Vec2 = require("src.Vector2")
local Tile = require("src.Tile")
local Chain = require("src.Chain")



function Board:new()
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
    self.tiles = {
        {{}, {}, {}, {}, {}, {}, {}, {}, {}},
        {{}, {}, {}, {}, {}, {}, {}, {}, {}},
        {{}, {}, {}, {}, {}, {}, {}, {}, {}},
        {{}, {}, {}, {}, {}, {}, {}, {}, {}},
        {{}, {}, {}, {}, {}, {}, {}, {}, {}},
        {{}, {}, {}, {}, {}, {}, {}, {}, {}},
        {{}, {}, {}, {}, {}, {}, {}, {}, {}},
        {{}, {}, {}, {}, {}, {}, {}, {}, {}},
        {{}, {}, {}, {}, {}, {}, {}, {}, {}}
    }

    -- We will fill the board repeatedly until no premade matches exist.
    repeat
        for i = 1, 9 do
            for j = 1, 9 do
                local coords = Vec2(i, j)
                local tile = Tile(self, coords:clone())
                tile:setObject(Chain(self, coords:clone()))
                self.tiles[i][j] = tile
            end
        end
    until #self:getMatchGroups() == 0

    self.playerControl = true
    self.hoverCoords = nil
    self.selecting = false
    self.selectedCoords = {}
    self.selectedDirections = {}
    -- It might be the case that we cross an already selected tile. In such case, this will not necessarily be the last entry in the selectedCoords table.
    self.selectingDirection = nil

    self.fallingObjectCount = 0
    self.rotatingChainCount = 0
end


function Board:update(dt)
    -- Game control
    if self.fallingObjectCount > 0 then
        self.playerControl = false
    end

    if not self.playerControl and self.fallingObjectCount == 0 and self.rotatingChainCount == 0 then
        -- Do another shot.
        self:handleMatches()
        self:fillHoles()
        self:fillHolesUp()
        if self.fallingObjectCount == 0 and self.rotatingChainCount == 0 then
            -- Nothing happened, grant the control to the player.
            self.playerControl = true
            _Game.combo = 0
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



function Board:startSelection()
    local tile = self:getTile(self.hoverCoords)
    if tile and tile:getChain() then
        tile:select()
        table.insert(self.selectedCoords, self.hoverCoords)
    end
end



function Board:expandSelection(direction)
    local oppositeDirection = (direction + 1) % 4 + 1

    local tile = self:getTile(self.hoverCoords)
    local prevTile = self:getTile(self.selectedCoords[#self.selectedCoords])

    if tile and tile:getChain() and not tile:isSideSelected(oppositeDirection) then
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
        table.insert(self.selectedCoords, self.hoverCoords)
        table.insert(self.selectedDirections, direction)
    end
end



function Board:shrinkSelection(direction)
    local oppositeDirection = (direction + 1) % 4 + 1

    local tile = self:getTile(self.hoverCoords)
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
            local chain = self:getTile(coords):getChain()
            chain:unrotate()
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
            local chain = self:getTile(coords):getChain()
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

    return groups
end



function Board:handleMatches()
    for i, match in ipairs(self:getMatchGroups()) do
        for j, coords in ipairs(match) do
            local tile = self:getTile(coords)
            assert(tile, string.format("Tried selecting a nonexistent tile on %s", coords))
            tile:destroyObject()
            tile:makeGold()
        end
        _Game.combo = _Game.combo + 1
        local multiplier = (_Game.combo * (_Game.combo + 1)) / 2
        _Game:addScore((#match - 2) * 100 * multiplier)
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



function Board:draw()
    local color = {0.75, 0.75, 0.75}
    -- Horizontal lines
    for i = 0, self.SIZE.y do
        local y = 8 + i * 15
        _Display:drawLine(Vec2(58, y), Vec2(194, y), color)
    end
    -- Vertical lines
    for i = 0, self.SIZE.x do
        local x = 58 + i * 15
        _Display:drawLine(Vec2(x, 8), Vec2(x, 143), color)
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
        if self.hoverCoords then
            self.selecting = true
        end
    elseif button == 2 then
        if self.hoverCoords then
            local tile = self:getTile(self.hoverCoords)
            if tile and tile:getObjectType() == "chain" then
                tile:getObject():rotate()
            end
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