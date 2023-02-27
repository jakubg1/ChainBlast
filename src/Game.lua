local class = require "class"

local Game = class:derive("Game")

-- Place your imports here
local Vec2 = require("src.Vector2")
local Sprite = require("src.Sprite")
local Settings = require("src.Settings")
local Sound = require("src.Sound")
local Music = require("src.Music")

local MainMenu = require("src.MainMenu")
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

    local HINT_STATES = {
        {
            pos = Vec2(),
            size = Vec2(18)
        },
        {
            pos = Vec2(18, 0),
            size = Vec2(18)
        },
        {
            pos = Vec2(36, 0),
            size = Vec2(18)
        },
        {
            pos = Vec2(54, 0),
            size = Vec2(18)
        },
        {
            pos = Vec2(72, 0),
            size = Vec2(18)
        },
        {
            pos = Vec2(90, 0),
            size = Vec2(18)
        },
        {
            pos = Vec2(108, 0),
            size = Vec2(18)
        },
        {
            pos = Vec2(126, 0),
            size = Vec2(18)
        },
        {
            pos = Vec2(144, 0),
            size = Vec2(18)
        },
        {
            pos = Vec2(162, 0),
            size = Vec2(18)
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
        },
        {
            pos = Vec2(42, 28),
            size = Vec2(14)
        },
        {
            pos = Vec2(56, 28),
            size = Vec2(14)
        },
        {
            pos = Vec2(0, 28),
            size = Vec2(14)
        },
        {
            pos = Vec2(14, 28),
            size = Vec2(14)
        },
        {
            pos = Vec2(28),
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
            [0] = Sprite("assets/sprites/chain_rainbow.png", CHAIN_STATES),
            Sprite("assets/sprites/chain_blue.png", CHAIN_STATES),
            Sprite("assets/sprites/chain_red.png", CHAIN_STATES),
            Sprite("assets/sprites/chain_yellow.png", CHAIN_STATES),
            Sprite("assets/sprites/chain_green.png", CHAIN_STATES),
            Sprite("assets/sprites/chain_pink.png", CHAIN_STATES),
            Sprite("assets/sprites/chain_cyan.png", CHAIN_STATES)
        },
        chainLinks = {
            [0] = Sprite("assets/sprites/chain_link_rainbow.png", {{pos = Vec2(), size = Vec2(2, 11)}}),
            Sprite("assets/sprites/chain_link_blue.png", {{pos = Vec2(), size = Vec2(2, 11)}}),
            Sprite("assets/sprites/chain_link_red.png", {{pos = Vec2(), size = Vec2(2, 11)}}),
            Sprite("assets/sprites/chain_link_yellow.png", {{pos = Vec2(), size = Vec2(2, 11)}}),
            Sprite("assets/sprites/chain_link_green.png", {{pos = Vec2(), size = Vec2(2, 11)}}),
            Sprite("assets/sprites/chain_link_pink.png", {{pos = Vec2(), size = Vec2(2, 11)}}),
            Sprite("assets/sprites/chain_link_cyan.png", {{pos = Vec2(), size = Vec2(2, 11)}})
        },
        chainLinksH = {
            [0] = Sprite("assets/sprites/chain_linkh_rainbow.png", {{pos = Vec2(), size = Vec2(11, 2)}}),
            Sprite("assets/sprites/chain_linkh_blue.png", {{pos = Vec2(), size = Vec2(11, 2)}}),
            Sprite("assets/sprites/chain_linkh_red.png", {{pos = Vec2(), size = Vec2(11, 2)}}),
            Sprite("assets/sprites/chain_linkh_yellow.png", {{pos = Vec2(), size = Vec2(11, 2)}}),
            Sprite("assets/sprites/chain_linkh_green.png", {{pos = Vec2(), size = Vec2(11, 2)}}),
            Sprite("assets/sprites/chain_linkh_pink.png", {{pos = Vec2(), size = Vec2(11, 2)}}),
            Sprite("assets/sprites/chain_linkh_cyan.png", {{pos = Vec2(), size = Vec2(11, 2)}})
        },
        crate = Sprite("assets/sprites/crate.png", {{pos = Vec2(), size = Vec2(14)}, {pos = Vec2(14, 0), size = Vec2(14)}}),
        hover = Sprite("assets/sprites/hover.png", HOVER_STATES),
        hint = Sprite("assets/sprites/hint.png", HINT_STATES),
        selection = Sprite("assets/sprites/selection.png", SELECTION_STATES),
        selectionArrows = Sprite("assets/sprites/selection_arrows.png", SELECTION_ARROW_STATES),
        tiles = Sprite("assets/sprites/tiles.png", TILE_STATES),
        explosion1 = Sprite("assets/sprites/explosion1.png", EXPLOSION1_STATES),
        arrow = Sprite("assets/sprites/arrow.png", ARROW_STATES)
    }

    self.FONTS = {
        standard = love.graphics.newImageFont("assets/fonts/standard.png", " abcdefghijklmnopqrstuvwxyząćęłńóśźżABCDEFGHIJKLMNOPQRSTUVWXYZĄĆĘŁŃÓŚŹŻ0123456789<>-+()[]_.,:;'!?@#$€%^&*\"/|\\", 1)
    }
    self.FONTS.standard:setFilter("nearest", "nearest")

    self.SOUNDS = {
        boardStart = Sound("assets/sounds/board_start.wav", 1),
        boardEnd = Sound("assets/sounds/board_end.wav", 1),
        bombAlarm = Sound("assets/sounds/bomb_alarm.wav", 1),
        clock = Sound("assets/sounds/clock1.wav", 1),
        clockAlarm = Sound("assets/sounds/clock1.wav", 1, true),
        chainDestroy = Sound("assets/sounds/chain_destroy.wav"),
        chainDestroyBig = Sound("assets/sounds/chain_destroy_big.wav"),
        chainLand = Sound("assets/sounds/chain_land.wav"),
        chainRotate = Sound("assets/sounds/chain_rotate.wav"),
        combo = Sound("assets/sounds/combo.wav"),
        crateDestroy = Sound("assets/sounds/crate_destroy.wav"),
        explosion = Sound("assets/sounds/explosion.wav", 1),
        explosion2 = Sound("assets/sounds/explosion2.wav"),
        gameOver = Sound("assets/sounds/game_over_T.wav", 1),
        gameWin = Sound("assets/sounds/game_win_T.wav", 1, false, true),
        hint = Sound("assets/sounds/hint.wav", 1),
        iceBreak = Sound("assets/sounds/ice_break.wav"),
        levelLose = Sound("assets/sounds/level_lose_T.wav", 1, false, true),
        levelStart = Sound("assets/sounds/level_start_T.wav", 1),
        levelWin = Sound("assets/sounds/level_win_T.wav", 1, false, true),
        shuffle = Sound("assets/sounds/shuffle.wav", 1),
        uiHover = Sound("assets/sounds/ui_hover.wav"),
        uiSelect = Sound("assets/sounds/ui_select.wav"),
        uiStats = Sound("assets/sounds/ui_stats.wav")
    }

    self.MUSIC = {
        menu = Music("assets/music/menu.mp3"),
        level = Music("assets/music/level.mp3"),
        danger = Music("assets/music/danger.mp3")
    }

    -- 0: no tile
    -- 1: chain goes here
    -- 2: box
    -- 3: double box
    -- 4-6: ice (levels 1-3)
    -- 7: special - box+lv2 ice
    -- 8: special - 2xbox+lv3 ice
    self.LEVELS = {
        { -- Level 1
            time = 60,
            layout = {
                {0, 0, 0, 0, 0, 0, 0, 0, 0},
                {0, 1, 1, 1, 1, 1, 1, 1, 0},
                {0, 1, 1, 1, 1, 1, 1, 1, 0},
                {0, 1, 1, 1, 1, 1, 1, 1, 0},
                {0, 1, 1, 1, 1, 1, 1, 1, 0},
                {0, 1, 1, 1, 1, 1, 1, 1, 0},
                {0, 1, 1, 1, 1, 1, 1, 1, 0},
                {0, 1, 1, 1, 1, 1, 1, 1, 0},
                {0, 0, 0, 0, 0, 0, 0, 0, 0}
            }
        },
        { -- Level 2
            time = 40,
            layout = {
                {1, 0, 1, 0, 1, 0, 1, 0, 1},
                {1, 0, 1, 0, 1, 0, 1, 0, 1},
                {1, 0, 1, 0, 1, 0, 1, 0, 1},
                {1, 0, 1, 0, 1, 0, 1, 0, 1},
                {1, 0, 1, 0, 1, 0, 1, 0, 1},
                {1, 0, 1, 0, 1, 0, 1, 0, 1},
                {1, 0, 1, 0, 1, 0, 1, 0, 1},
                {1, 0, 1, 0, 1, 0, 1, 0, 1},
                {1, 0, 1, 0, 1, 0, 1, 0, 1}
            }
        },
        { -- Level 3
            time = 45,
            layout = {
                {0, 0, 1, 1, 1, 1, 1, 0, 0},
                {0, 1, 1, 1, 1, 1, 1, 1, 0},
                {1, 1, 2, 2, 1, 2, 2, 1, 1},
                {1, 2, 2, 2, 2, 2, 2, 2, 1},
                {1, 2, 2, 2, 2, 2, 2, 2, 1},
                {1, 1, 2, 2, 2, 2, 2, 1, 1},
                {1, 1, 1, 2, 2, 2, 1, 1, 1},
                {0, 1, 1, 1, 2, 1, 1, 1, 0},
                {0, 0, 1, 1, 1, 1, 1, 0, 0}
            }
        },
        { -- Level 4
            time = 40,
            layout = {
                {1, 1, 1, 1, 1, 1, 1, 1, 1},
                {1, 1, 1, 1, 1, 1, 1, 1, 1},
                {1, 1, 1, 1, 1, 1, 1, 1, 1},
                {0, 0, 0, 0, 0, 0, 0, 0, 0},
                {2, 2, 2, 2, 2, 2, 2, 2, 2},
                {2, 2, 2, 2, 2, 2, 2, 2, 2},
                {2, 2, 2, 2, 2, 2, 2, 2, 2},
                {2, 2, 2, 2, 2, 2, 2, 2, 2},
                {2, 2, 2, 2, 2, 2, 2, 2, 2}
            }
        },
        { -- Level 5
            time = 40,
            layout = {
                {0, 0, 0, 0, 0, 0, 0, 0, 0},
                {0, 4, 4, 4, 4, 4, 4, 4, 0},
                {0, 4, 4, 4, 4, 4, 4, 4, 0},
                {0, 4, 4, 5, 5, 5, 4, 4, 0},
                {0, 4, 4, 5, 5, 5, 4, 4, 0},
                {0, 4, 4, 5, 5, 5, 4, 4, 0},
                {0, 4, 4, 4, 4, 4, 4, 4, 0},
                {0, 4, 4, 4, 4, 4, 4, 4, 0},
                {0, 0, 0, 0, 0, 0, 0, 0, 0}
            }
        },
        { -- Level 6
            time = 40,
            layout = {
                {7, 7, 7, 7, 7, 7, 7, 7, 7},
                {7, 7, 7, 7, 7, 7, 7, 7, 7},
                {7, 7, 7, 7, 7, 7, 7, 7, 7},
                {7, 7, 7, 5, 5, 5, 7, 7, 7},
                {7, 7, 7, 5, 5, 5, 7, 7, 7},
                {7, 7, 7, 5, 5, 5, 7, 7, 7},
                {7, 7, 7, 7, 7, 7, 7, 7, 7},
                {7, 7, 7, 7, 7, 7, 7, 7, 7},
                {7, 7, 7, 7, 7, 7, 7, 7, 7}
            }
        },
        { -- Level 7
            time = 40,
            layout = {
                {3, 3, 3, 3, 3, 3, 1, 1, 1},
                {3, 3, 3, 3, 3, 1, 1, 1, 1},
                {3, 3, 3, 3, 1, 1, 1, 1, 1},
                {3, 3, 3, 1, 1, 1, 1, 1, 3},
                {3, 3, 1, 1, 1, 1, 1, 3, 3},
                {3, 1, 1, 1, 1, 1, 3, 3, 3},
                {1, 1, 1, 1, 1, 3, 3, 3, 3},
                {1, 1, 1, 1, 3, 3, 3, 3, 3},
                {1, 1, 1, 3, 3, 3, 3, 3, 3}
            }
        },
        { -- Level 8
            time = 45,
            layout = {
                {0, 0, 0, 0, 0, 0, 0, 0, 0},
                {5, 5, 5, 7, 7, 7, 7, 7, 7},
                {0, 0, 0, 0, 0, 0, 0, 0, 0},
                {5, 5, 5, 7, 7, 7, 7, 7, 7},
                {0, 0, 0, 0, 0, 0, 0, 0, 0},
                {5, 5, 5, 7, 7, 7, 7, 7, 7},
                {0, 0, 0, 0, 0, 0, 0, 0, 0},
                {5, 5, 5, 7, 7, 7, 7, 7, 7},
                {0, 0, 0, 0, 0, 0, 0, 0, 0}
            }
        },
        { -- Level 9
            time = 35,
            layout = {
                {5, 5, 5, 5, 5, 5, 5, 5, 5},
                {5, 5, 5, 5, 5, 5, 5, 5, 5},
                {5, 5, 5, 5, 5, 5, 5, 5, 5},
                {0, 0, 0, 0, 0, 0, 0, 0, 0},
                {0, 0, 1, 0, 1, 0, 1, 0, 0},
                {0, 0, 0, 0, 0, 0, 0, 0, 0},
                {0, 0, 1, 0, 1, 0, 1, 0, 0},
                {0, 0, 0, 0, 0, 0, 0, 0, 0},
                {0, 0, 1, 0, 1, 0, 1, 0, 0}
            }
        },
        { -- Level 10
            time = 35,
            layout = {
                {8, 6, 8, 6, 8, 6, 8, 6, 8},
                {6, 6, 6, 6, 6, 6, 6, 6, 6},
                {8, 6, 8, 6, 8, 6, 8, 6, 8},
                {6, 6, 6, 6, 6, 6, 6, 6, 6},
                {8, 6, 8, 6, 8, 6, 8, 6, 8},
                {6, 6, 6, 6, 6, 6, 6, 6, 6},
                {8, 6, 8, 6, 8, 6, 8, 6, 8},
                {6, 6, 6, 6, 6, 6, 6, 6, 6},
                {8, 6, 8, 6, 8, 6, 8, 6, 8}
            }
        },
        { -- Level DEBUG
            time = 45,
            layout = {
                {0, 0, 0, 0, 0, 0, 0, 0, 0},
                {0, 0, 0, 0, 0, 0, 0, 0, 0},
                {0, 0, 0, 0, 0, 0, 0, 0, 0},
                {0, 0, 0, 0, 0, 0, 0, 0, 0},
                {0, 0, 0, 0, 0, 0, 0, 0, 0},
                {0, 0, 0, 1, 1, 1, 0, 0, 0},
                {0, 0, 0, 0, 0, 0, 0, 0, 0},
                {0, 0, 0, 0, 0, 0, 0, 0, 0},
                {0, 0, 0, 0, 0, 0, 0, 0, 0}
            }
        }
    }

    self.settings = Settings()

    self.level = MainMenu()
    self.levelNumber = 1

    self.sparks = {}
    self.explosions = {}

    self.score = 0
    self.scoreDisplay = 0
    self.lives = 3

    -- Game stats
    self.timeElapsed = 0
    self.chainsDestroyed = 0
    self.maxCombo = 0
    self.largestGroup = 0
    self.levelsBeaten = 0
    self.levelsStarted = 0
end



function Game:init()
    self.settings:load()
end



function Game:update(dt)
    self.level:update(dt)

    for musicN, music in pairs(self.MUSIC) do
        music:update(dt)
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
    self.levelsBeaten = self.levelsBeaten + 1
end



function Game:endGame()
    self.levelNumber = 1
    self.score = 0
    self.scoreDisplay = 0
    self.lives = 3

    self.timeElapsed = 0
    self.chainsDestroyed = 0
    self.maxCombo = 0
    self.largestGroup = 0
    self.levelsBeaten = 0
    self.levelsStarted = 0
end



function Game:startLevel(number)
    number = number or self.levelNumber
    self.level = Level(number, self.LEVELS[number])
    self.levelsStarted = self.levelsStarted + 1
end



function Game:backToMain()
    self.level = MainMenu()
end



function Game:draw()
    _Display:activate()

    -- Draw stuff onto the Display Canvas
    self.level:draw()
    
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

    _Display:drawText(string.format("FPS: %s", love.timer.getFPS()), Vec2(10, 10))
    --if self.level and self.level.mouseIdleTime then
    --    _Display:drawText(string.format("Mouse idle: %.2f", self.level.mouseIdleTime), Vec2(10, 20))
    --end

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
    self.level:mousepressed(x, y, button)
end



function Game:mousereleased(x, y, button)
    self.level:mousereleased(x, y, button)
end



function Game:keypressed(key)
    self.level:keypressed(key)
end



function Game:focus(focus)
    self.level:focus(focus)
end



function Game:quit()
    self.settings:save()
end



return Game