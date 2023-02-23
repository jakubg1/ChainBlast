local class = require "class"

local Game = class:derive("Game")

-- Place your imports here
local Vec2 = require("src.Vector2")
local Sprite = require("src.Sprite")
local Sound = require("src.Sound")
local Level = require("src.Level")



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
            pos = Vec2(112, 0),
            size = Vec2(16)
        },
        {
            pos = Vec2(112, 16),
            size = Vec2(18)
        },
        {
            pos = Vec2(112, 0),
            size = Vec2(16)
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
            [0] = Sprite("assets/sprites/chain_rainbow.png", CHAIN_STATES),
            Sprite("assets/sprites/chain_blue.png", CHAIN_STATES),
            Sprite("assets/sprites/chain_red.png", CHAIN_STATES),
            Sprite("assets/sprites/chain_yellow.png", CHAIN_STATES)
        },
        chainLinks = {
            [0] = Sprite("assets/sprites/chain_link_rainbow.png", {{pos = Vec2(), size = Vec2(2, 11)}}),
            Sprite("assets/sprites/chain_link_blue.png", {{pos = Vec2(), size = Vec2(2, 11)}}),
            Sprite("assets/sprites/chain_link_red.png", {{pos = Vec2(), size = Vec2(2, 11)}}),
            Sprite("assets/sprites/chain_link_yellow.png", {{pos = Vec2(), size = Vec2(2, 11)}}),
        },
        chainLinksH = {
            [0] = Sprite("assets/sprites/chain_linkh_rainbow.png", {{pos = Vec2(), size = Vec2(11, 2)}}),
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

    self.SOUNDS = {
        chainDestroy = Sound("assets/sounds/chain_destroy.wav"),
        chainLand = Sound("assets/sounds/chain_land.wav"),
        chainRotate = Sound("assets/sounds/chain_rotate.wav"),
        combo = Sound("assets/sounds/combo.wav"),
        shuffle = Sound("assets/sounds/shuffle.wav", 1)
    }

    self.LEVELS = {
        {
            time = 30,
            layout = {
                {1, 1, 1, 1, 1, 1, 1, 1, 1},
                {1, 1, 1, 1, 1, 1, 1, 1, 1},
                {1, 1, 1, 1, 1, 1, 1, 1, 1},
                {1, 1, 1, 1, 1, 1, 1, 1, 1},
                {1, 1, 1, 1, 1, 1, 1, 1, 1},
                {1, 1, 1, 1, 1, 1, 1, 1, 1},
                {1, 1, 1, 1, 1, 1, 1, 1, 1},
                {1, 1, 1, 1, 1, 1, 1, 1, 1},
                {1, 1, 1, 1, 1, 1, 1, 1, 1}
            }
        },
        {
            time = 60,
            layout = {
                {0, 0, 0, 0, 0, 1, 1, 1, 1},
                {0, 0, 0, 0, 1, 1, 1, 1, 1},
                {0, 0, 0, 1, 1, 1, 1, 1, 1},
                {0, 0, 1, 1, 1, 1, 1, 1, 1},
                {0, 1, 1, 1, 1, 1, 1, 1, 0},
                {1, 1, 1, 1, 1, 1, 1, 0, 0},
                {1, 1, 1, 1, 1, 1, 0, 0, 0},
                {1, 1, 1, 1, 1, 0, 0, 0, 0},
                {1, 1, 1, 1, 0, 0, 0, 0, 0}
            }
        }
    }

    self.level = nil
    self.levelNumber = 1

    self.sparks = {}
    self.explosions = {}

    self.score = 0
    self.scoreDisplay = 0
    self.lives = 3
end



function Game:update(dt)
    if self.level then
        self.level:update(dt)
    end

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



function Game:advanceLevel()
    self.levelNumber = self.levelNumber + 1
    self.lives = 3
end



function Game:startLevel(number)
    number = number or self.levelNumber
    self.level = Level(number, self.LEVELS[number])
end



function Game:draw()
    _Display:activate()

    -- Draw stuff onto the Display Canvas
    if self.level then
        self.level:draw()
    else
        _Display:drawText("Press LMB to start!", Vec2(10))
    end
    
    for i, spark in ipairs(self.sparks) do
        spark:draw()
    end
    for i, explosion in ipairs(self.explosions) do
        explosion:draw()
    end

    -- Draw the Display Canvas
    _Display:draw()

    -- Do debug stuff
    love.graphics.setCanvas()

    if self.level and false then
        local board = self.level.board
        if board then
            _Display:drawText("You're in the game!", Vec2(10))
            _Display:drawText(string.format("Hovered Tile: %s", board.hoverCoords), Vec2(10, 25))
            _Display:drawText(string.format("Sparks: %s", #self.sparks), Vec2(10, 40))

            _Display:drawText("Hovered:", Vec2(10, 70))
            if board.selecting then
                for i, coords in ipairs(board.selectedCoords) do
                    _Display:drawText(tostring(coords), Vec2(20, 70 + i * 15))
                end
                for i, direction in ipairs(board.selectedDirections) do
                    _Display:drawText(tostring(direction), Vec2(50, 77 + i * 15))
                end
            elseif board.hoverCoords and board:getTile(board.hoverCoords) then
                for i, coords in ipairs(board:getTile(board.hoverCoords):getObject():getGroup()) do
                    _Display:drawText(tostring(coords), Vec2(20, 70 + i * 15))
                end
            else
                local y = 0
                for i, group in ipairs(board:getMatchGroups()) do
                    y = y + 5
                    for j, coords in ipairs(group) do
                        y = y + 15
                        _Display:drawText(tostring(coords), Vec2(20, 70 + y))
                    end
                end
            end
        end
    end
end



function Game:mousepressed(x, y, button)
    if self.level then
        self.level:mousepressed(x, y, button)
    else
        if button == 1 then
            self:startLevel()
        end
    end
end



function Game:mousereleased(x, y, button)
    if self.level then
        self.level:mousereleased(x, y, button)
    end
end



return Game