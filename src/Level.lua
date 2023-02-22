local class = require "class"

local Level = class:derive("Level")

-- Place your imports here
local Vec2 = require("src.Vector2")
local Board = require("src.Board")



function Level:new()
    self.board = nil

    self.score = 0
    self.time = 60
    self.combo = 0

    self.timeElapsed = 0
    self.maxCombo = 0
    self.largestGroup = 0

    self.startAnimation = 0
    self.winAnimation = nil
    self.resultsAnimation = nil
    self.hudAlpha = 0
end



function Level:update(dt)
    if self.startAnimation then
        self.startAnimation = self.startAnimation + dt
        self.hudAlpha = math.max((self.startAnimation - 7) * 2, 0)
        if self.startAnimation >= 7.5 then
            self.startAnimation = nil
            self.hudAlpha = 1
            self.board = Board(self)
        end
    end

    if self.winAnimation then
        self.winAnimation = self.winAnimation + dt
        if self.winAnimation >= 5 then
            self.winAnimation = nil
            self.board:launchEndAnimation()
        end
    end

    if self.resultsAnimation then
        self.resultsAnimation = self.resultsAnimation + dt
        self.hudAlpha = math.max(1 - self.resultsAnimation * 2, 0)
    end

    if self.board then
        self.board:update(dt)
        -- The board can delete itself on its update!
        if self.board and self.board.playerControl then
            self.time = self.time - dt
        end
        if self.board and not self.board.startAnimation and not self.board.endAnimation then
            self.timeElapsed = self.timeElapsed + dt
        end
    end
end



function Level:addScore(amount)
    self.score = self.score + amount
    _Game.score = _Game.score + amount
end



function Level:addTime(amount)
    self.time = self.time + amount
end



function Level:addCombo()
    self.combo = self.combo + 1
    self.maxCombo = math.max(self.maxCombo, self.combo)
end



function Level:win()
    self.winAnimation = 0
end



function Level:onBoardEnd()
    self.board = nil
    self:addScore(math.ceil(self.time * 10) * 100)
    self.resultsAnimation = 0
end



function Level:draw()
    if self.startAnimation then
        local pos = Vec2(100, 75 - math.max(self.startAnimation - 4, 0) * 25)
        local alpha = math.min(self.startAnimation, 1)
        _Display:drawText("Level 1", pos, Vec2(0.5), nil, nil, alpha)
    end

    if self.board then
        self.board:draw()
    end

    if self.hudAlpha > 0 then
        _Display:drawText("Score:", Vec2(10, 50), Vec2(), nil, nil, self.hudAlpha)
        _Display:drawRect(Vec2(4, 66), Vec2(52, 10), false, nil, self.hudAlpha)
        _Display:drawText(tostring(_Game.scoreDisplay), Vec2(54, 65), Vec2(1, 0), nil, nil, self.hudAlpha)
        _Display:drawText("Time:", Vec2(10, 90), Vec2(), nil, nil, self.hudAlpha)
        if self.time < 10 then
            _Display:drawText(string.format("%.1f", self.time), Vec2(54, 105), Vec2(1, 0), nil, nil, self.hudAlpha)
        else
            _Display:drawText(string.format("%.1d:%.2d", self.time / 60, self.time % 60), Vec2(50, 105), Vec2(1, 0), nil, nil, self.hudAlpha)
        end
    end

    if self.winAnimation then
        local alpha = math.min(self.winAnimation, 0.5)
        if self.winAnimation >= 4.5 then
            alpha = 5 - self.winAnimation
        end
        _Display:drawRect(Vec2(0, 0), Vec2(200, 150), true, {0, 0, 0}, alpha)
        local textPos = Vec2(250 - math.min(self.winAnimation * 300, 150), 75)
        local textAlpha = math.min(5 - self.winAnimation, 1)
        _Display:drawText("Level Complete!", textPos + Vec2(1), Vec2(0.5), nil, {0, 0, 0}, textAlpha * 0.5)
        _Display:drawText("Level Complete!", textPos, Vec2(0.5), nil, {0, 1, 0}, textAlpha)
    end

    if self.resultsAnimation then
        local alpha = math.min(math.max((self.resultsAnimation - 0.5) * 2, 0), 1)
        _Display:drawText("Level Complete!", Vec2(100, 10), Vec2(0.5), nil, {0, 1, 0}, alpha)
        _Display:drawText("Time Elapsed:", Vec2(20, 30), Vec2(0, 0.5))
        _Display:drawText(string.format("%.1d:%.2d", self.timeElapsed / 60, self.timeElapsed % 60), Vec2(180, 30), Vec2(1, 0.5), nil, {1, 1, 0})
        _Display:drawText("Max Combo:", Vec2(20, 45), Vec2(0, 0.5))
        _Display:drawText(tostring(self.maxCombo), Vec2(180, 45), Vec2(1, 0.5), nil, {1, 1, 0})
        _Display:drawText("Largest Link:", Vec2(20, 60), Vec2(0, 0.5))
        _Display:drawText(tostring(self.largestGroup), Vec2(180, 60), Vec2(1, 0.5), nil, {1, 1, 0})
        _Display:drawText("Time Bonus:", Vec2(20, 75), Vec2(0, 0.5))
        _Display:drawText(string.format("%.1fs = %s", self.time, math.ceil(self.time * 10) * 100), Vec2(180, 75), Vec2(1, 0.5), nil, {1, 1, 0})
        _Display:drawText("Level Score:", Vec2(20, 90), Vec2(0, 0.5))
        _Display:drawText(tostring(self.score), Vec2(180, 90), Vec2(1, 0.5), nil, {1, 1, 0})
        _Display:drawText("TOTAL SCORE:", Vec2(20, 105), Vec2(0, 0.5))
        _Display:drawText(tostring(_Game.score), Vec2(180, 105), Vec2(1, 0.5), nil, {1, 1, 0})
    end
end



function Level:mousepressed(x, y, button)
    if self.board then
        self.board:mousepressed(x, y, button)
    end
end



function Level:mousereleased(x, y, button)
    if self.board then
        self.board:mousereleased(x, y, button)
    end
end



return Level