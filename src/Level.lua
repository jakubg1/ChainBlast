local class = require "class"

local Level = class:derive("Level")

-- Place your imports here
local Vec2 = require("src.Vector2")
local Board = require("src.Board")



function Level:new(number, data)
    self.number = number
    self.data = data

    self.board = nil

    self.score = 0
    self.time = data.time
    self.combo = 0
    self.lost = false

    self.timeElapsed = 0
    self.maxCombo = 0
    self.largestGroup = 0

    self.startAnimation = 0
    self.winAnimation = nil
    self.loseAnimation = nil
    self.loseAnimationBoardNuked = false
    self.resultsAnimation = nil
    self.hudAlpha = 0
end



function Level:update(dt)
    if self.startAnimation then
        self.startAnimation = self.startAnimation + dt
        self.hudAlpha = math.max((self.startAnimation - 4) * 2, 0)
        if self.startAnimation >= 2.5 and not self.board then
            self.board = Board(self, self.data.layout)
        end
        if self.startAnimation >= 10.5 and not self.board.started then
            self.board.started = true
        end
        if self.startAnimation >= 11.5 then
            self.startAnimation = nil
            self.hudAlpha = 1
        end
    end

    if self.winAnimation then
        self.winAnimation = self.winAnimation + dt
        if self.winAnimation >= 5 then
            self.winAnimation = nil
            self.board:launchEndAnimation()
        end
    end

    if self.loseAnimation then
        self.loseAnimation = self.loseAnimation + dt
        if self.loseAnimation >= 1 and not self.loseAnimationBoardNuked then
            self.board:nukeEverything()
        end
        if self.loseAnimation >= 12.5 then
            self.loseAnimation = nil
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
            if self.time <= 0 then
                self.time = 0
                self:lose()
            end
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



function Level:lose()
    self.lost = true
    self.board:lose()
    _Game.lives = _Game.lives - 1

    self.loseAnimation = 0
end



function Level:onBoardEnd()
    self.board = nil
    self:addScore(math.ceil(self.time * 10) * 100)
    self.resultsAnimation = 0
end



function Level:draw()
    if self.board then
        self.board:draw()
    end

    if self.startAnimation then
        if self.startAnimation < 7.5 then
            local alpha = math.min(self.startAnimation, 1)
            if self.startAnimation >= 6.5 then
                alpha = math.min(7.5 - self.startAnimation, 1)
            end
            _Display:drawText(string.format("Level %s", self.number), Vec2(101, 76), Vec2(0.5), nil, {0, 0, 0}, alpha * 0.5)
            _Display:drawText(string.format("Level %s", self.number), Vec2(100, 75), Vec2(0.5), nil, nil, alpha)
        elseif self.startAnimation < 11.5 then
            -- Uhhh... Why just starting a timer when the player makes their first move instead?
            local text = tostring(math.ceil(10.5 - self.startAnimation))
            if self.startAnimation >= 10.5 then
                text = "Start!"
            end
            local alpha = math.min((11.5 - self.startAnimation) * 2, 1)
            _Display:drawText(text, Vec2(101, 76), Vec2(0.5), nil, {0, 0, 0}, alpha * 0.5)
            _Display:drawText(text, Vec2(100, 75), Vec2(0.5), nil, nil, alpha)
        end
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

    if self.loseAnimation then
        local alpha = math.max(math.min(self.loseAnimation - 1.5, 0.5), 0)
        if self.loseAnimation >= 11 then
            alpha = (12 - self.loseAnimation) / 2
        end
        _Display:drawRect(Vec2(0, 0), Vec2(200, 150), true, {0, 0, 0}, alpha)
        local textAlpha = math.max(math.min((self.loseAnimation - 2) / 2, 1), 0)
        if self.loseAnimation >= 11 then
            textAlpha = math.min(12 - self.loseAnimation, 1)
        end
        local texts = {"2 attempts left!", "Last attempt left!!!", "Uh oh..."}
        local text = texts[3 - _Game.lives]
        _Display:drawText(text, Vec2(101, 76), Vec2(0.5), nil, {0, 0, 0}, textAlpha * 0.5)
        _Display:drawText(text, Vec2(100, 75), Vec2(0.5), nil, {1, 0, 0}, textAlpha)
    end

    if self.resultsAnimation then
        local alpha = math.min(math.max((self.resultsAnimation - 0.5) * 2, 0), 1)
        _Display:drawText(string.format("Level %s", self.number), Vec2(100, 10), Vec2(0.5), nil, nil, alpha)
        if self.lost then
            _Display:drawText("Failed!", Vec2(100, 20), Vec2(0.5), nil, {1, 0, 0}, alpha)
        else
            _Display:drawText("Complete!", Vec2(100, 20), Vec2(0.5), nil, {0, 1, 0}, alpha)
        end
        if self.resultsAnimation > 1.2 then
            _Display:drawText("Time Elapsed:", Vec2(20, 40), Vec2(0, 0.5))
        end
        if self.resultsAnimation > 1.3 then
            _Display:drawText(string.format("%.1d:%.2d", self.timeElapsed / 60, self.timeElapsed % 60), Vec2(180, 40), Vec2(1, 0.5), nil, {1, 1, 0})
        end
        if self.resultsAnimation > 1.6 then
            _Display:drawText("Max Combo:", Vec2(20, 50), Vec2(0, 0.5))
        end
        if self.resultsAnimation > 1.7 then
            _Display:drawText(tostring(self.maxCombo), Vec2(180, 50), Vec2(1, 0.5), nil, {1, 1, 0})
        end
        if self.resultsAnimation > 2 then
            _Display:drawText("Largest Link:", Vec2(20, 60), Vec2(0, 0.5))
        end
        if self.resultsAnimation > 2.1 then
            _Display:drawText(tostring(self.largestGroup), Vec2(180, 60), Vec2(1, 0.5), nil, {1, 1, 0})
        end
        if self.resultsAnimation > 2.4 then
            _Display:drawText("Time Bonus:", Vec2(20, 70), Vec2(0, 0.5))
        end
        if self.resultsAnimation > 2.5 then
            local text = "No Bonus!"
            if not self.lost then
                text = string.format("%.1fs = %s", self.time, math.ceil(self.time * 10) * 100)
            end
            _Display:drawText(text, Vec2(180, 70), Vec2(1, 0.5), nil, {1, 1, 0})
        end
        if self.resultsAnimation > 2.8 then
            _Display:drawText("Level Score:", Vec2(20, 80), Vec2(0, 0.5))
        end
        if self.resultsAnimation > 2.9 then
            _Display:drawText(tostring(self.score), Vec2(180, 80), Vec2(1, 0.5), nil, {1, 1, 0})
        end
        if self.resultsAnimation > 3.4 then
            _Display:drawText("Total Score:", Vec2(20, 100), Vec2(0, 0.5))
        end
        if self.resultsAnimation > 3.8 then
            _Display:drawText(tostring(_Game.score), Vec2(180, 100), Vec2(1, 0.5), nil, {1, 1, 0})
        end
        if self.resultsAnimation > 4.5 then
            local text = "Click anywhere to start next level!"
            if self.lost then
                text = "Click anywhere to try again!"
            end
            _Display:drawText(text, Vec2(100, 130), Vec2(0.5), nil, nil, (math.sin((self.resultsAnimation - 4.5) * math.pi) + 2) / 3)
        end
    end
end



function Level:mousepressed(x, y, button)
    if self.board then
        self.board:mousepressed(x, y, button)
    end
    if button == 1 and self.resultsAnimation and self.resultsAnimation > 4.5 then
        if not self.lost then
            _Game:advanceLevel()
        end
        _Game:startLevel()
    end
end



function Level:mousereleased(x, y, button)
    if self.board then
        self.board:mousereleased(x, y, button)
    end
end



return Level