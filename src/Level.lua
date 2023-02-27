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
    self.lost = false
    self.pause = false
    self.pauseAnimation = 0

    self.lastMousePos = _MousePos
    self.mouseIdleTime = 0

    self.bombMeter = 0
    self.bombMeterTime = nil
    self.bombMeterCoords = {}

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
    self.gameWinAnimation = nil
    self.gameWinChimePlayed = false
    self.gameOverAnimation = nil
    self.gameOverHeSaid = false
    self.gameResultsAnimation = nil
    self.gameResultsAnimationSoundStep = 1
    self.GAME_RESULTS_ANIMATION_SOUND_STEPS = {1.2, 1.6, 2, 2.4, 2.8, 3.8}

    self.hudAlpha = 0
    self.hudComboAlpha = 0
    self.hudComboValue = 0
    self.hudExtraTimeAlpha = 0
    self.hudExtraTimeValue = 0
    self.clockAlarm = false
    self.dangerMusic = false

    _Game.SOUNDS.levelStart:play()
    _Game.MUSIC.level:play()
end



function Level:update(dt)
    if self.pause then
        self.pauseAnimation = math.min(self.pauseAnimation + dt, 1)
    elseif self.pauseAnimation > 0 then
        self.pauseAnimation = math.max(self.pauseAnimation - dt, 0)
    else
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

            if self.lastMousePos == _MousePos and self:isTimerTicking() then
                self.mouseIdleTime = self.mouseIdleTime + dt
                if not self.pause and self.mouseIdleTime > 3 then
                    self:togglePause()
                    self.mouseIdleTime = 0
                end
            else
                self.mouseIdleTime = 0
            end
            self.lastMousePos = _MousePos
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

    if not self.clockAlarm and self.time < 5 and self:isTimerTicking() then
        self.clockAlarm = true
        _Game.SOUNDS.clockAlarm:play(0.5)
    end

    if self.clockAlarm and (self.time > 5 or not self:isTimerTicking()) then
        self.clockAlarm = false
        _Game.SOUNDS.clockAlarm:stop()
    end

    if not self.dangerMusic and self.time < 10 and self:isTimerTicking() then
        self.dangerMusic = true
        _Game.MUSIC.level:play(0, 0.5)
        _Game.MUSIC.danger:play()
    end

    if self.dangerMusic and self.time > 15 and self:isTimerTicking() then
        self.dangerMusic = false
        _Game.MUSIC.level:play(1, 2)
        _Game.MUSIC.danger:stop(1)
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
            if _Game.lives == 0 then
                self.loseAnimation = nil
                self.board = nil
                self.bombMeterTime = nil
                _Game.sparks = {}
                _Game.explosions = {}
                self.gameOverAnimation = 0
            end
        elseif self.loseAnimation >= 12.5 then
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

    if self.gameOverAnimation then
        self.gameOverAnimation = self.gameOverAnimation + dt
        self.hudAlpha = 0
        if not self.gameOverHeSaid and self.gameOverAnimation >= 5 then
            _Game.SOUNDS.gameOver:play()
            self.gameOverHeSaid = true
        end
        if self.gameOverAnimation >= 19 then
            self.gameOverAnimation = nil
            self.resultsAnimation = 0.5
        end
    end

    if self.gameWinAnimation then
        self.gameWinAnimation = self.gameWinAnimation + dt
        if not self.gameWinChimePlayed and self.gameWinAnimation >= 1 then
            _Game.SOUNDS.gameWin:play()
            self.gameWinChimePlayed = true
        end
    end

    if self.gameResultsAnimation then
        self.gameResultsAnimation = self.gameResultsAnimation + dt
        local threshold = self.GAME_RESULTS_ANIMATION_SOUND_STEPS[self.gameResultsAnimationSoundStep]
        if threshold and self.gameResultsAnimation >= threshold then
            _Game.SOUNDS.uiStats:play()
            self.gameResultsAnimationSoundStep = self.gameResultsAnimationSoundStep + 1
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
    return self.board and self.board.playerControl and self.timeCounting and self.pauseAnimation == 0
end



function Level:canPause()
    return not (self.startAnimation or self.winAnimation or self.loseAnimation or self.resultsAnimation or self.gameOverAnimation or self.gameWinAnimation or self.gameResultsAnimation)
end



function Level:togglePause()
    self.pause = not self.pause
    if self:canPause() then
        if self.pause then
            _Game.MUSIC.level:play(0, 1)
            _Game.MUSIC.danger:play(0, 1)
        else
            if self.dangerMusic then
                _Game.MUSIC.danger:play(1, 0.5)
            else
                _Game.MUSIC.level:play(1, 1)
            end
        end
    else
        self.pause = false
    end
end



function Level:addCombo()
    self.combo = self.combo + 1
    self.maxCombo = math.max(self.maxCombo, self.combo)
end



function Level:addToBombMeter(amount)
    -- Cooldown before next bombs
    if self.bombMeterTime or self.lost then
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
    _Game.MUSIC.level:stop(0.25)
    _Game.MUSIC.danger:stop(0.25)
end



function Level:lose()
    self.lost = true
    self.board:panicChains()
    _Game.lives = _Game.lives - 1

    self.loseAnimation = 0
    _Game.SOUNDS.levelLose:play()
    _Game.MUSIC.level:stop(0.25)
    _Game.MUSIC.danger:stop(0.25)
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

    if self.pauseAnimation > 0 then
        _Display:drawRect(Vec2(57, 0), Vec2(143, 150), true, {0, 0, 0}, self.pauseAnimation)
        _Display:drawText(string.format("Game Paused", self.number), Vec2(128, 70), Vec2(0.5), nil, {1, 1, 0}, self.pauseAnimation)
        local alpha = 0.5 + (_Time % 2) * 0.5
        if _Time % 2 > 1 then
            alpha = 1 + (1 - _Time % 2) * 0.5
        end
        _Display:drawText(string.format("Click to continue", self.number), Vec2(128, 80), Vec2(0.5), nil, nil, self.pauseAnimation * alpha)
    end

    if self.startAnimation then
        local alpha = math.min(self.startAnimation, 1)
        if self.startAnimation >= 6.5 then
            alpha = math.min(7.5 - self.startAnimation, 1)
        end
        if _Game.lives == 1 then
            _Display:drawText(string.format("Level %s", self.number), Vec2(101, 66), Vec2(0.5), nil, {0, 0, 0}, alpha * 0.5)
            _Display:drawText(string.format("Level %s", self.number), Vec2(100, 65), Vec2(0.5), nil, nil, alpha)
            alpha = math.max(math.min(self.startAnimation - 1.5, 1))
            if self.startAnimation >= 6.5 then
                alpha = math.min(7.5 - self.startAnimation, 1)
            end
            _Display:drawText(string.format("This is your last chance!", self.number), Vec2(101, 76), Vec2(0.5), nil, {0, 0, 0}, alpha * 0.5)
            _Display:drawText(string.format("This is your last chance!", self.number), Vec2(100, 75), Vec2(0.5), nil, {1, 0, 0}, alpha)
            _Display:drawText(string.format("Don't screw up!", self.number), Vec2(101, 86), Vec2(0.5), nil, {0, 0, 0}, alpha * 0.5)
            _Display:drawText(string.format("Don't screw up!", self.number), Vec2(100, 85), Vec2(0.5), nil, {1, 0, 0}, alpha)
        else
            _Display:drawText(string.format("Level %s", self.number), Vec2(101, 76), Vec2(0.5), nil, {0, 0, 0}, alpha * 0.5)
            _Display:drawText(string.format("Level %s", self.number), Vec2(100, 75), Vec2(0.5), nil, nil, alpha)
        end
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
                if _Game.lives > 0 then
                    text = "Click anywhere to try again!"
                else
                    text = "Click anywhere to continue!"
                end
            else
                if self.number == 10 then
                    text = "Click anywhere to continue!"
                end
            end
            --local alpha = (math.sin((self.resultsAnimation - 4.5) * math.pi) + 2) / 3
            local alpha = 0.5 + (self.resultsAnimation % 2) * 0.5
            if self.resultsAnimation % 2 > 1 then
                alpha = 1 + (1 - self.resultsAnimation % 2) * 0.5
            end
            _Display:drawText(text, Vec2(100, 130), Vec2(0.5), nil, nil, alpha)
        end
    end

    if self.gameOverAnimation then
        if self.gameOverAnimation > 5 then
            local alpha = math.min((17 - self.gameOverAnimation) / 4, 1)
            _Display:drawText("GAME", Vec2(100, 75), Vec2(0.5, 1), nil, {1, 0, 0}, alpha, 5)
            _Display:drawText("OVER", Vec2(100, 75), Vec2(0.5, 0), nil, {1, 0, 0}, alpha, 5)
        end
    end

    if self.gameWinAnimation then
        if self.gameWinAnimation > 0.5 and self.gameWinAnimation <= 9 then
            local alpha = math.max(self.gameWinAnimation * 2 - 0.5, 0)
            if self.gameWinAnimation > 7 then
                alpha = math.min((9 - self.gameWinAnimation) / 2, 1)
            end
            _Display:drawRect(Vec2(), Vec2(200, 150), true, _GetRainbowColor(math.min((self.gameWinAnimation - 2) / 2, 1.3)), alpha)
            _Display:drawText("YOU", Vec2(100, 75), Vec2(0.5, 1), nil, {0, 0, 0}, nil, 5)
            _Display:drawText("WIN!", Vec2(100, 75), Vec2(0.5, 0), nil, {0, 0, 0}, nil, 5)
        elseif self.gameWinAnimation > 9 then
            local alpha = math.min(math.max((self.gameWinAnimation - 9) * 2, 0), 1)
            _Display:drawText("Congratulations!", Vec2(100, 10), Vec2(0.5), nil, {1, 1, 0}, alpha)
            local yOffset = math.max((11 - self.gameWinAnimation) * 150, 0)
            local text = {
                "You've beaten all ten levels!",
                "But... is that the end? Well, I hope not!",
                "This is just a demo I've made in one week.",
                "I have a few more ideas for the full game!",
                --"I've had the concept for this game",
                --"sitting in my head for past few months!",
                "I hope you've enjoyed this journey.",
                "Were some levels too hard?",
                "Did you not like something?",
                "Or maybe you have some cool ideas?",
                "I'd love your feedback!"
            }
            for i, line in ipairs(text) do
                _Display:drawText(line, Vec2(100, 20 + i * 10 + yOffset), Vec2(0.5))
            end
        end
        if self.gameWinAnimation > 11.5 then
            local text = "Click anywhere to continue!"
            local alpha = 0.5 + (self.gameWinAnimation % 2) * 0.5
            if self.gameWinAnimation % 2 > 1 then
                alpha = 1 + (1 - self.gameWinAnimation % 2) * 0.5
            end
            _Display:drawText(text, Vec2(100, 130), Vec2(0.5), nil, nil, alpha)
        end
    end

    if self.gameResultsAnimation then
        local alpha = math.min(math.max((self.gameResultsAnimation - 0.5) * 2, 0), 1)
        _Display:drawText("Game Results", Vec2(100, 10), Vec2(0.5), nil, nil, alpha)
        if self.gameResultsAnimation > 1.2 then
            _Display:drawText("Chains Destroyed:", Vec2(20, 30), Vec2(0, 0.5))
        end
        if self.gameResultsAnimation > 1.3 then
            _Display:drawText(tostring(_Game.chainsDestroyed), Vec2(180, 30), Vec2(1, 0.5), nil, {1, 1, 0})
        end
        if self.gameResultsAnimation > 1.6 then
            _Display:drawText("Largest Link:", Vec2(20, 40), Vec2(0, 0.5))
        end
        if self.gameResultsAnimation > 1.7 then
            _Display:drawText(tostring(_Game.largestGroup), Vec2(180, 40), Vec2(1, 0.5), nil, {1, 1, 0})
        end
        if self.gameResultsAnimation > 2 then
            _Display:drawText("Max Combo:", Vec2(20, 50), Vec2(0, 0.5))
        end
        if self.gameResultsAnimation > 2.1 then
            _Display:drawText(tostring(_Game.maxCombo), Vec2(180, 50), Vec2(1, 0.5), nil, {1, 1, 0})
        end
        if self.gameResultsAnimation > 2.4 then
            _Display:drawText("Attempts per Level:", Vec2(20, 60), Vec2(0, 0.5))
        end
        if self.gameResultsAnimation > 2.5 then
            _Display:drawText(string.format("%s / %s = %.2f", _Game.levelsStarted, _Game.levelsBeaten + 1, _Game.levelsStarted / (_Game.levelsBeaten + 1)), Vec2(180, 60), Vec2(1, 0.5), nil, {1, 1, 0})
        end
        if self.gameResultsAnimation > 2.8 then
            _Display:drawText("Total Time:", Vec2(20, 70), Vec2(0, 0.5))
        end
        if self.gameResultsAnimation > 2.9 then
            _Display:drawText(string.format("%.1d:%.2d", _Game.timeElapsed / 60, _Game.timeElapsed % 60), Vec2(180, 70), Vec2(1, 0.5), nil, {1, 1, 0})
        end
        if self.gameResultsAnimation > 3.4 then
            _Display:drawText("Final Score:", Vec2(100, 90), Vec2(0.5))
        end
        if self.gameResultsAnimation > 3.8 then
            _Display:drawText(tostring(_Game.score), Vec2(100, 105), Vec2(0.5), nil, _GetRainbowColor(_Time / 4), nil, 2)
        end
        if self.gameResultsAnimation > 4.5 then
            local text = "Click anywhere to go to main menu!"
            local alpha = 0.5 + (self.gameResultsAnimation % 2) * 0.5
            if self.gameResultsAnimation % 2 > 1 then
                alpha = 1 + (1 - self.gameResultsAnimation % 2) * 0.5
            end
            _Display:drawText(text, Vec2(100, 130), Vec2(0.5), nil, nil, alpha)
        end
    end
end



function Level:mousepressed(x, y, button)
    if self.board then
        self.board:mousepressed(x, y, button)
    end
    if button == 1 then
        if self.pause then
            self:togglePause()
        end
        if self.resultsAnimation and self.resultsAnimation > 4.5 then
            _Game.largestGroup = math.max(_Game.largestGroup, self.largestGroup)
            _Game.maxCombo = math.max(_Game.maxCombo, self.maxCombo)
            _Game.timeElapsed = _Game.timeElapsed + self.timeElapsed
            if _Game.lives == 0 then
                self.resultsAnimation = nil
                self.gameResultsAnimation = 0
            elseif not self.lost and self.number == 10 then
                self.resultsAnimation = nil
                self.gameWinAnimation = 0
            else
                if not self.lost then
                    _Game:advanceLevel()
                end
                _Game:startLevel()
            end
            _Game.SOUNDS.uiSelect:play()
        elseif self.gameWinAnimation and self.gameWinAnimation > 11.5 then
            self.gameWinAnimation = nil
            self.gameResultsAnimation = 0
        elseif self.gameResultsAnimation and self.gameResultsAnimation > 4.5 then
            _Game:endGame()
            _Game:backToMain()
            _Game.SOUNDS.uiSelect:play()
        end
    end
end



function Level:mousereleased(x, y, button)
    if self.board then
        self.board:mousereleased(x, y, button)
    end
end



function Level:keypressed(key)
    if key == "space" then
        self:togglePause()
    end
end



function Level:focus(focus)
    if not focus and not self.pause then
        self:togglePause()
    end
end



return Level