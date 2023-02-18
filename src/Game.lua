local class = require "class"

local Game = class:derive("Game")

-- Place your imports here
local Vec2 = require("src.Vector2")
local Sprite = require("src.Sprite")
local Board = require("src.Board")



function Game:new()
    local CHAIN_STATES = {
        {
            pos = Vec2(),
            size = Vec2(14)
        },
        {
            pos = Vec2(14, 0),
            size = Vec2(14)
        }
    }

    local HOVER_STATES = {
        {
            pos = Vec2(),
            size = Vec2(24)
        },
        {
            pos = Vec2(24, 0),
            size = Vec2(24)
        },
        {
            pos = Vec2(48, 0),
            size = Vec2(24)
        },
        {
            pos = Vec2(72, 0),
            size = Vec2(24)
        }
    }

    local SELECTION_STATES = {
        {
            pos = Vec2(),
            size = Vec2(2)
        },
        {
            pos = Vec2(2, 0),
            size = Vec2(15, 2)
        },
        {
            pos = Vec2(16, 0),
            size = Vec2(2)
        },
        {
            pos = Vec2(16, 2),
            size = Vec2(2, 15)
        },
        {
            pos = Vec2(16),
            size = Vec2(2)
        },
        {
            pos = Vec2(2, 16),
            size = Vec2(15, 2)
        },
        {
            pos = Vec2(0, 16),
            size = Vec2(2)
        },
        {
            pos = Vec2(0, 2),
            size = Vec2(2, 15)
        }
    }

    self.SPRITES = {
        chains = {
            Sprite("assets/sprites/chain_blue.png", CHAIN_STATES),
            Sprite("assets/sprites/chain_red.png", CHAIN_STATES),
            Sprite("assets/sprites/chain_yellow.png", CHAIN_STATES)
        },
        hover = Sprite("assets/sprites/hover.png", HOVER_STATES),
        selection = Sprite("assets/sprites/selection.png", SELECTION_STATES)
    }

    self.board = Board(20)

    self.sparks = {}
end



function Game:update(dt)
    self.board:update(dt)

    for i = #self.sparks, 1, -1 do
        local spark = self.sparks[i]
        spark:update(dt)
        if spark:canDespawn() then
            table.remove(self.sparks, i)
        end
    end
end



function Game:draw()
    _Display:activate()

    -- Draw stuff onto the Display Canvas
    self.board:draw()
    for i, spark in ipairs(self.sparks) do
        spark:draw()
    end

    -- Draw the Display Canvas
    _Display:draw()

    -- Do debug stuff
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("You're in the game!", 10, 10)
    love.graphics.print(string.format("Hovered Tile: %s", self.board.hoverCoords), 10, 25)
    love.graphics.print(string.format("Sparks: %s", #self.sparks), 10, 40)
    love.graphics.print("Hovered:", 10, 70)
    for i, coords in ipairs(self.board.selectedCoords) do
        love.graphics.print(coords, 20, 70 + i * 15)
    end
end



function Game:mousepressed(x, y, button)
    self.board:mousepressed(x, y, button)
end



function Game:mousereleased(x, y, button)
    self.board:mousereleased(x, y, button)
end



return Game