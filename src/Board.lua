local class = require "class"

local Board = class:derive("Board")

-- Place your imports here
local Vec2 = require("src.Vector2")
local Tile = require("src.Tile")
local Chain = require("src.Chain")



function Board:new()
    self.SIZE = Vec2(9)

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

    for i = 1, 9 do
        for j = 1, 9 do
            local coords = Vec2(i, j)
            local tile = Tile(self, coords:clone())
            tile:setObject(Chain(self, coords:clone()))
            self.tiles[i][j] = tile
        end
    end
    for i = 1, 9 do
        for j = 1, 9 do
            self:getTile(Vec2(i, j)):findNeighbors()
        end
    end

    self.hoverCoords = nil
    self.selecting = false
    self.selectedCoords = {}
end


function Board:update(dt)
    self.hoverCoords = nil
    local hoverCoords = self:getTileCoords(_MousePos)
    if hoverCoords.x >= 1 and hoverCoords.y >= 1 and hoverCoords.x <= self.SIZE.x and hoverCoords.y <= self.SIZE.y then
        self.hoverCoords = hoverCoords
    end

    if self.selecting and self.hoverCoords then
        local hoverTile = self:getTile(self.hoverCoords)
        if not hoverTile.selected then
            hoverTile.selected = true
            table.insert(self.selectedCoords, self.hoverCoords)
        end
    end

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
    return self.tiles[coords.x][coords.y]
end



function Board:getTilePos(coords)
    return coords * 15 + Vec2(44, -6)
end



function Board:getTileCoords(pos)
    return ((pos - Vec2(44, -6)) / 15):floor()
end



function Board:destroyTile(coords)
    local tile = self:getTile(coords)
    if tile then
        tile:destroyObject()
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
                local chain = Chain(self, Vec2(coords.x, -2 - tilesPlaced))
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
            if tile and tile.selected then
                tile:drawSelection()
            end
        end
    end

    -- Hover sprite
    if self.hoverCoords then
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
            for i = 1, 9 do
                self:destroyTile(Vec2(self.hoverCoords.x, i))
            end
            self:fillHoles()
            self:fillHolesUp()
        end
    end
end



function Board:mousereleased(x, y, button)
    if button == 1 then
        if self.selecting then
            self.selecting = false
            for i, coords in ipairs(self.selectedCoords) do
                self:destroyTile(coords)
                self:getTile(coords).selected = false
            end
            self.selectedCoords = {}
            self:fillHoles()
            self:fillHolesUp()
        end
    end
end



return Board