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
        },
        {
            pos = Vec2(28, 0),
            size = Vec2(14)
        },
        {
            pos = Vec2(42, 0),
            size = Vec2(14)
        },
        {
            pos = Vec2(0, 14),
            size = Vec2(14)
        },
        {
            pos = Vec2(14),
            size = Vec2(14)
        },
        {
            pos = Vec2(28, 14),
            size = Vec2(14)
        },
        {
            pos = Vec2(42, 14),
            size = Vec2(14)
        },
        {
            pos = Vec2(0, 28),
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

    local SELECTION_ARROW_STATES = {
        {
            pos = Vec2(),
            size = Vec2(8, 5)
        },
        {
            pos = Vec2(13, 0),
            size = Vec2(5, 8)
        },
        {
            pos = Vec2(0, 5),
            size = Vec2(8, 5)
        },
        {
            pos = Vec2(8, 0),
            size = Vec2(5, 8)
        }
    }

    local TILE_STATES = {
        {
            pos = Vec2(),
            size = Vec2(14)
        },
        {
            pos = Vec2(0, 14),
            size = Vec2(14)
        },
        {
            pos = Vec2(0, 14),
            size = Vec2(14)
        },
        {
            pos = Vec2(14),
            size = Vec2(14)
        },
        {
            pos = Vec2(28, 14),
            size = Vec2(14)
        },
        {
            pos = Vec2(42, 14),
            size = Vec2(14)
        },
        {
            pos = Vec2(56, 14),
            size = Vec2(14)
        },
        {
            pos = Vec2(70, 14),
            size = Vec2(14)
        },
        {
            pos = Vec2(84, 14),
            size = Vec2(14)
        },
        {
            pos = Vec2(98, 14),
            size = Vec2(14)
        }
    }

    local EXPLOSION1_STATES = {
        {
            pos = Vec2(),
            size = Vec2(44)
        },
        {
            pos = Vec2(44, 0),
            size = Vec2(44)
        },
        {
            pos = Vec2(88, 0),
            size = Vec2(44)
        },
        {
            pos = Vec2(0, 44),
            size = Vec2(44)
        },
        {
            pos = Vec2(44),
            size = Vec2(44)
        },
        {
            pos = Vec2(88, 44),
            size = Vec2(44)
        },
        {
            pos = Vec2(0, 88),
            size = Vec2(44)
        },
        {
            pos = Vec2(44, 88),
            size = Vec2(44)
        },
        {
            pos = Vec2(88),
            size = Vec2(44)
        }
    }

    local ARROW_STATES = {
        {
            pos = Vec2(),
            size = Vec2(14)
        },
        {
            pos = Vec2(14, 0),
            size = Vec2(14)
        },
        {
            pos = Vec2(28, 0),
            size = Vec2(14)
        },
        {
            pos = Vec2(42, 0),
            size = Vec2(14)
        },
        {
            pos = Vec2(56, 0),
            size = Vec2(14)
        }
    }

    self.SPRITES = {
        chains = {
            Sprite("assets/sprites/chain_blue.png", CHAIN_STATES),
            Sprite("assets/sprites/chain_red.png", CHAIN_STATES),
            Sprite("assets/sprites/chain_yellow.png", CHAIN_STATES)
        },
        chainLinks = {
            Sprite("assets/sprites/chain_link_blue.png", {{pos = Vec2(), size = Vec2(2, 11)}}),
            Sprite("assets/sprites/chain_link_red.png", {{pos = Vec2(), size = Vec2(2, 11)}}),
            Sprite("assets/sprites/chain_link_yellow.png", {{pos = Vec2(), size = Vec2(2, 11)}}),
        },
        chainLinksH = {
            Sprite("assets/sprites/chain_linkh_blue.png", {{pos = Vec2(), size = Vec2(11, 2)}}),
            Sprite("assets/sprites/chain_linkh_red.png", {{pos = Vec2(), size = Vec2(11, 2)}}),
            Sprite("assets/sprites/chain_linkh_yellow.png", {{pos = Vec2(), size = Vec2(11, 2)}}),
        },
        hover = Sprite("assets/sprites/hover.png", HOVER_STATES),
        selection = Sprite("assets/sprites/selection.png", SELECTION_STATES),
        selectionArrows = Sprite("assets/sprites/selection_arrows.png", SELECTION_ARROW_STATES),
        tiles = Sprite("assets/sprites/tiles.png", TILE_STATES),
        explosion1 = Sprite("assets/sprites/explosion1.png", EXPLOSION1_STATES),
        arrow = Sprite("assets/sprites/arrow.png", ARROW_STATES)
    }

    self.FONTS = {
        standard = love.graphics.newImageFont("assets/fonts/standard.png", " abcdefghijklmnopqrstuvwxyząćęłńóśźżABCDEFGHIJKLMNOPQRSTUVWXYZĄĆĘŁŃÓŚŹŻ0123456789<>-+()[]_.,:;'!?@#$€%^&*\"/|\\", 1)
    }

    self.board = Board(20)

    self.sparks = {}
    self.explosions = {}

    self.score = 0
    self.scoreDisplay = 0
    self.combo = 0
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
    for i = #self.explosions, 1, -1 do
        local explosion = self.explosions[i]
        explosion:update(dt)
        if explosion:canDespawn() then
            table.remove(self.explosions, i)
        end
    end

    if self.scoreDisplay < self.score then
        self.scoreDisplay = self.scoreDisplay + math.ceil((self.score - self.scoreDisplay) / 8)
    end
end



function Game:addScore(amount)
    self.score = self.score + amount
end



function Game:draw()
    _Display:activate()

    -- Draw stuff onto the Display Canvas
    self.board:draw()
    for i, spark in ipairs(self.sparks) do
        spark:draw()
    end
    for i, explosion in ipairs(self.explosions) do
        explosion:draw()
    end
    _Display:drawText("Score:", 10, 50)
    _Display:drawText(self.scoreDisplay, 10, 65)

    -- Draw the Display Canvas
    _Display:draw()

    -- Do debug stuff
    love.graphics.setCanvas()
    _Display:drawText("You're in the game!", 10, 10)
    _Display:drawText(string.format("Hovered Tile: %s", self.board.hoverCoords), 10, 25)
    _Display:drawText(string.format("Sparks: %s", #self.sparks), 10, 40)

    _Display:drawText("Hovered:", 10, 70)
    if self.board.selecting then
        for i, coords in ipairs(self.board.selectedCoords) do
            _Display:drawText(tostring(coords), 20, 70 + i * 15)
        end
        for i, direction in ipairs(self.board.selectedDirections) do
            _Display:drawText(tostring(direction), 50, 77 + i * 15)
        end
    elseif self.board.hoverCoords then
        for i, coords in ipairs(self.board:getTile(self.board.hoverCoords):getObject():getGroup()) do
            _Display:drawText(tostring(coords), 20, 70 + i * 15)
        end
    else
        local y = 0
        for i, group in ipairs(self.board:getMatchGroups()) do
            y = y + 5
            for j, coords in ipairs(group) do
                y = y + 15
                _Display:drawText(tostring(coords), 20, 70 + y)
            end
        end
    end
end



function Game:mousepressed(x, y, button)
    self.board:mousepressed(x, y, button)
end



function Game:mousereleased(x, y, button)
    self.board:mousereleased(x, y, button)
end



return Game