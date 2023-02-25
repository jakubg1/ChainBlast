local class = require "class"

local Level = class:derive("Level")

-- Place your imports here
local Vec2 = require("src.Vector2")
local Board = require("src.Board")
local Bomb = require("src.Bomb")



function Level:new(number, data)
    self.number = number
    self.data = data

    self.board = nil
    self.bombs = {}

    self.score = 0
    self.time = data.time
    self.timeCounting = false
    self.combo = 0
    self.bombMeter = 0
    self.bombMeterTime = nil
    self.bombMeterCoords = {}
    self.lost = false

    self.timeElapsed = 0
    self.maxCombo = 0
    self.largestGroup = 0

    self.startAnimation = 0
    self.winAnimation = nil
    self.loseAnimation = nil
    self.loseAnimationBoardNuked = false
    self.resultsAnimation = nil
    self.resultsAnimationSoundStep = 1
    self.RESULTS_ANIMATION_SOUND_STEPS = {1.2, 1.6, 2, 2.4, 2.8, 3.8}
    self.hudAlpha = 0
    self.hudComboAlpha = 0
    self.hudComboValue = 0
    self.hudExtraTimeAlpha = 0
    self.hudExtraTimeValue = 0
    self.clockAlarm = false

    _Game.SOUNDS.levelStart:play()
end



function Level:update(dt)
    if self.board then
        self.board:update(dt)
        -- The board can delete itself on its update!
        if self:isTimerTicking() then
            self.time = self.time - dt
            if self.time < 10 and math.floor(self.time) ~= math.floor(self.time + dt) then
                _Game.SOUNDS.clock:play()
            end
            if self.time <= 0 then
                self.time = 0
                if not self.bombMeterTime then
                    self:lose()
                end
            end
        end
        if self.board and not self.board.startAnimation and not self.board.endAnimation then
            self.timeElapsed = self.timeElapsed + dt
        end
    end

    if not self.clockAlarm and self.time < 5 and self:isTimerTicking() then
        self.clockAlarm = true
        _Game.SOUNDS.clockAlarm:play(0.5)
    end

    if self.clockAlarm and (self.time > 5 or not self:isTimerTicking()) then
        self.clockAlarm = false
        _Game.SOUNDS.clockAlarm:stop()
    end

    for i = #self.bombs, 1, -1 do
        local bomb = self.bombs[i]
        bomb:update(dt)
        if bomb:canDespawn() then
            table.remove(self.bombs, i)
        end
    end

    if self.bombMeterTime and self.board.shufflingChainCount == 0 then
        local n = math.floor(self.bombMeterTime / 0.5)
        self.bombMeterTime = self.bombMeterTime + dt
        if n ~= math.floor(self.bombMeterTime / 0.5) and n < 3 then
            local tile = self.board:getRandomNonGoldTile(self.bombMeterCoords)
            if tile then
                self:spawnBomb(tile.coords)
                table.insert(self.bombMeterCoords, tile.coords)
            end
        end
        if self.bombMeterTime >= 1.5 and #self.bombs == 0 then
            self.bombMeterTime = nil
            self.bombMeterCoords = {}
        end
    end

    if self.startAnimation then
        self.startAnimation = self.startAnimation + dt
        self.hudAlpha = math.max((self.startAnimation - 4) * 2, 0)
        if self.startAnimation >= 2.5 and not self.board then
            self.board = Board(self, self.data.layout)
        end
        if self.startAnimation >= 7.5 then
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
            self.loseAnimationBoardNuked = true
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
        local threshold = self.RESULTS_ANIMATION_SOUND_STEPS[self.resultsAnimationSoundStep]
        if threshold and self.resultsAnimation >= threshold then
            _Game.SOUNDS.uiStats:play()
            self.resultsAnimationSoundStep = self.resultsAnimationSoundStep + 1
        end
    end

    if self.combo >= 2 then
        self.hudComboAlpha = 1
        self.hudComboValue = self.combo
    else
        self.hudComboAlpha = math.max(self.hudComboAlpha - dt, 0)
    end

    if self.hudExtraTimeAlpha > 0 then
        self.hudExtraTimeAlpha = self.hudExtraTimeAlpha - dt
        if self.hudExtraTimeAlpha <= 0 then
            self.hudExtraTimeAlpha = 0
            self.hudExtraTimeValue = 0
        end
    end
end



function Level:addScore(amount)
    self.score = self.score + amount
    _Game.score = _Game.score + amount
end



function Level:addTime(amount)
    self.time = self.time + amount
    self.hudExtraTimeAlpha = 2
    self.hudExtraTimeValue = self.hudExtraTimeValue + amount
end



function Level:startTimer()
    self.timeCounting = true
end



function Level:isTimerTicking()
    return self.board and self.board.playerControl and self.timeCounting
end



function Level:addCombo()
    self.combo = self.combo + 1
    self.maxCombo = math.max(self.maxCombo, self.combo)
end



function Level:addToBombMeter(amount)
    -- Cooldown before next bombs
    if self.bombMeterTime then
        return
    end
    self.bombMeter = self.bombMeter + amount
    if self.bombMeter >= 100 then
        self.bombMeter = 0
        self.bombMeterTime = 0
        _Game.SOUNDS.bombAlarm:play()
    end
end



function Level:spawnBomb(targetCoords)
    table.insert(self.bombs, Bomb(self, targetCoords))
end



function Level:win()
    self.winAnimation = 0
    _Game.SOUNDS.levelWin:play()
end



function Level:lose()
    self.lost = true
    self.board:panicChains()
    _Game.lives = _Game.lives - 1

    self.loseAnimation = 0
    _Game.SOUNDS.levelLose:play()
end



function Level:onBoardEnd()
    self.board = nil
    self.bombMeterTime = nil
    self:addScore(self:getTimeBonus())
    self.resultsAnimation = 0
end



function Level:getTimeBonus()
    return math.ceil(self.time * 10) * 30
end



function Level:draw()
    if self.board then
        self.board:draw()
    end

    if self.startAnimation then
        local alpha = math.min(self.startAnimation, 1)
        if self.startAnimation >= 6.5 then
            alpha = math.min(7.5 - self.startAnimation, 1)
        end
        _Display:drawText(string.format("Level %s", self.number), Vec2(101, 76), Vec2(0.5), nil, {0, 0, 0}, alpha * 0.5)
        _Display:drawText(string.format("Level %s", self.number), Vec2(100, 75), Vec2(0.5), nil, nil, alpha)
    end

    if self.hudAlpha > 0 then
        -- Score
        _Display:drawText("Score", Vec2(4, 30), Vec2(), nil, nil, self.hudAlpha)
        _Display:drawRect(Vec2(4, 41), Vec2(52, 10), false, nil, self.hudAlpha)
        _Display:drawText(tostring(_Game.scoreDisplay), Vec2(54, 40), Vec2(1, 0), nil, nil, self.hudAlpha)
        if self.hudComboAlpha > 0 then
            _Display:drawText(string.format("x%s", self.hudComboValue), Vec2(56, 30), Vec2(1, 0), nil, nil, self.hudAlpha * self.hudComboAlpha)
        end

        -- Timer
        _Display:drawText("Time", Vec2(4, 55), Vec2(), nil, nil, self.hudAlpha)
        _Display:drawRect(Vec2(4, 66), Vec2(52, 10), false, nil, self.hudAlpha)
        if self.time < 9.9 then
            if self.time > 5 or not self:isTimerTicking() or _Time % 0.25 < 0.125 then
                _Display:drawText(string.format("%.1f", self.time), Vec2(54, 65), Vec2(1, 0), nil, {1, 0, 0}, self.hudAlpha)
            end
        else
            _Display:drawText(string.format("%.1d:%.2d", self.time / 60, self.time % 60), Vec2(54, 65), Vec2(1, 0), nil, nil, self.hudAlpha)
        end
        if self.hudExtraTimeAlpha > 0 then
            _Display:drawText(string.format("+%s", self.hudExtraTimeValue), Vec2(56, 55), Vec2(1, 0), nil, nil, self.hudAlpha * self.hudExtraTimeAlpha)
        end

        -- Power meter
        _Display:drawText("Power", Vec2(4, 80), Vec2(), nil, nil, self.hudAlpha)
        _Display:drawRect(Vec2(4, 91), Vec2(52, 10), false, nil, self.hudAlpha)
        if self.bombMeterTime then
            if _Time % 0.3 < 0.15 then
                _Display:drawRect(Vec2(4, 92), Vec2(51, 9), true, {1, 0, 0}, self.hudAlpha)
            end
            _Display:drawText(string.format("BOMBS: %s", math.max(3 - math.floor(self.bombMeterTime / 0.5), 0)), Vec2(54, 90), Vec2(1, 0), nil, nil, self.hudAlpha)
        else
            local color = (self.bombMeter > 90 and _Time % 0.5 < 0.25) and {1, 0.8, 0.2} or {1, 0.7, 0}
            _Display:drawRect(Vec2(4, 92), Vec2((self.bombMeter / 100) * 51, 9), true, color, self.hudAlpha)
            _Display:drawText(tostring(self.bombMeter), Vec2(54, 90), Vec2(1, 0), nil, nil, self.hudAlpha)
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
                text = string.format("%.1fs = %s", self.time, self:getTimeBonus())
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
            --local alpha = (math.sin((self.resultsAnimation - 4.5) * math.pi) + 2) / 3
            local alpha = 0.5 + (self.resultsAnimation % 2) * 0.5
            if self.resultsAnimation % 2 > 1 then
                alpha = 1 + (1 - self.resultsAnimation % 2) * 0.5
            end
            _Display:drawText(text, Vec2(100, 130), Vec2(0.5), nil, nil, alpha)
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
        _Game.SOUNDS.uiSelect:play()
    end
end



function Level:mousereleased(x, y, button)
    if self.board then
        self.board:mousereleased(x, y, button)
    end
end



return Level