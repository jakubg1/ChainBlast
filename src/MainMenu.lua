local class = require "class"

local MainMenu = class:derive("MainMenu")

-- Place your imports here
local Vec2 = require("src.Vector2")
local Star = require("src.Star")



function MainMenu:new()
    self.screen = ""
    self.screenTransition = nil
    self.screenTransitionTarget = nil
    self.fadeInTime = 0
    self.fadeInExploded = false
    self.fadeOutTime = nil

    self.options = {}
    self.optionsY = 60
    self.optionsHeader = nil
    self.selectedOption = nil
    self.cursorAnim = 1
    self.cursorAnimH = 0.5

    self.jokeTime = -10
    self.joke = nil

    self.stars = {}
    for i = 1, 100 do
        table.insert(self.stars, Star(love.math.random()))
    end
end



function MainMenu:update(dt)
    local selectedOptionOld = self.selectedOption
    self.selectedOption = nil

    if self.screenTransition then
        self.screenTransition = self.screenTransition + dt
        if self.screenTransition >= 0.6 then
            self:initScreen(self.screenTransitionTarget)
            self.screenTransition = nil
            self.screenTransitionTarget = nil
        end
    elseif self.fadeInTime then
        self.fadeInTime = self.fadeInTime + dt
        if not self.fadeInExploded and self.fadeInTime >= 1.5 then
            _Game.SOUNDS.explosion:play()
            self.fadeInExploded = true
        end
        if self.fadeInTime >= 2.5 then
            self:initScreen("main")
            _Game.MUSIC.menu:play()
            self.fadeInTime = nil
        end
    elseif self.fadeOutTime then
        self.fadeOutTime = self.fadeOutTime + dt
        if self.fadeOutTime >= 1 then
            _Game:startLevel()
        end
    else
        for i, option in ipairs(self.options) do
            local pos = _Display.mousePos
            if pos.x >= 60 and pos.x <= 140 and pos.y >= self.optionsY + i * 10 and pos.y < self.optionsY + (i + 1) * 10 then
                self.selectedOption = i
                if selectedOptionOld ~= i then
                    _Game.SOUNDS.uiHover:play()
                end
                break
            end
        end
    end

    if self.selectedOption then
        self.cursorAnim = self.cursorAnim * 0.5 + self.selectedOption * 0.5
        self.cursorAnimH = math.max(self.cursorAnimH - dt, 0)
    else
        self.cursorAnimH = math.min(self.cursorAnimH + dt, 0.5)
    end

    if self.screen == "main" then
        self.jokeTime = self.jokeTime + dt
        if self.jokeTime >= 0 and not self.joke then
            self.joke = self:getJoke()
            if not self.joke then
                self.jokeTime = -10
            end
        end
        if self.joke and self.jokeTime * 25 > _Display:getTextSize(self.joke).x + 200 then
            self.joke = nil
            self.jokeTime = -1
        end
    end

    for i = #self.stars, 1, -1 do
        local star = self.stars[i]
        star:update(dt)
        if star:canDespawn() then
            table.remove(self.stars, i)
            table.insert(self.stars, Star())
        end
    end
end



function MainMenu:initScreen(screen)
    self.screen = screen
    if screen == "main" then
        self.optionsHeader = "Main Menu"
        self.options = {"New Game", "Settings", "Credits", "Exit"}
        self.optionsY = 60
    elseif screen == "settings" then
        self.optionsHeader = "Settings"
        self.options = {
            "Sound Volume: " .. self:getBars(_Game.settings.soundVolume),
            "Music Volume: " .. self:getBars(_Game.settings.musicVolume),
            "Go Back"
        }
        self.optionsY = 60
    elseif screen == "credits" then
        self.optionsHeader = nil
        self.options = {"Special Thanks", "Back to Menu"}
        self.optionsY = 110
    elseif screen == "credits2" then
        self.optionsHeader = nil
        self.options = {"Credits", "Back to Menu"}
        self.optionsY = 110
    elseif screen == "_game" then
        self.fadeOutTime = 0
        _Game.MUSIC.menu:stop(1)
    elseif screen == "_quit" then
        love.event.quit()
    end
end



function MainMenu:transitionTo(screen)
    self.screenTransition = 0
    self.screenTransitionTarget = screen
end



function MainMenu:getBars(value)
    local text = ""
    for i = 1, 10 do
        text = text .. ((value + 0.005 > i / 10) and "|" or ".")
    end
    return string.format(text .. " %d%%", value * 100)
end



function MainMenu:getJoke()
    local jokes = _LoadFile("pre_assets/witties.txt")
    if jokes then
        jokes = _StrSplit(jokes, "\n")
        return jokes[love.math.random(#jokes)]
    end
end



function MainMenu:draw()
    if self.fadeInTime and self.fadeInTime < 1.5 then
        _Display:drawText("Chain", Vec2(95 - (1.5 - self.fadeInTime) * 300, 30), Vec2(1, 0.5), nil, {0, 1, 0}, nil, 2)
        _Display:drawText("Blast", Vec2(105 + (1.5 - self.fadeInTime) * 300, 30), Vec2(0, 0.5), nil, {0, 1, 0}, nil, 2)
    else
        for i, star in ipairs(self.stars) do
            star:draw()
        end

        _Display:drawText("Chain Blast", Vec2(100, 30), Vec2(0.5), nil, {0, 1, 0}, nil, 2)
        _Display:drawText("LOVE Jam Demo", Vec2(2, 150), Vec2(0, 1))
        _Display:drawText("Version 1.0.1", Vec2(198, 150), Vec2(1, 1))

        if self.fadeInTime then
            _Display:drawRect(Vec2(), Vec2(200, 150), true, nil, 2.5 - self.fadeInTime)
        end
    end

    if self.optionsHeader then
        _Display:drawText(self.optionsHeader, Vec2(100, self.optionsY - 5), Vec2(0.5, 0))
    end
    for i, option in ipairs(self.options) do
        local color = (i == self.selectedOption) and {1, 1, 1} or {0.8, 0.8, 0.8}
        _Display:drawText(option, Vec2(100, self.optionsY + i * 10), Vec2(0.5, 0), nil, color)
    end

    local xWidthPrev = 0
    local xWidthNext = 0
    if self.cursorAnim >= 1 and self.cursorAnim <= #self.options then
        xWidthPrev = _Display:getTextSize(self.options[math.floor(self.cursorAnim)]).x * (1 - self.cursorAnim % 1)
        xWidthNext = _Display:getTextSize(self.options[math.ceil(self.cursorAnim)]).x * (self.cursorAnim % 1)
    end
    local xWidth = math.max((xWidthPrev + xWidthNext) / 2 - 20, 0)
    local xSeparation = math.max(self.cursorAnimH * self.cursorAnimH * 320, xWidth)
    local color = _GetRainbowColor(_Time / 4)
    _Display:drawText(">", Vec2(70 + math.sin(_Time * math.pi) * 4 - xSeparation, self.optionsY + self.cursorAnim * 10 + 0.5), Vec2(1, 0), nil, color)
    _Display:drawText("<", Vec2(130 - math.sin(_Time * math.pi) * 4 + xSeparation, self.optionsY + self.cursorAnim * 10 + 0.5), Vec2(0, 0), nil, color)

    if self.screen == "main" and self.joke then
        _Display:drawText(self.joke, Vec2(200 - self.jokeTime * 25, 130), Vec2(0, 0.5), nil, {0.5, 0.5, 0.5})
    end

    if self.screen == "credits" then
        _Display:drawText("Made with <3", Vec2(100, 45), Vec2(0.5))
        _Display:drawText("For the LOVE Jam 2023!", Vec2(100, 55), Vec2(0.5))
        _Display:drawText("Music by @Crisps", Vec2(100, 70), Vec2(0.5))
        _Display:drawText("Copyright (C) 2023 jakubg1", Vec2(100, 80), Vec2(0.5))
        _Display:drawText("All assets (besides music) and code", Vec2(100, 90), Vec2(0.5))
        _Display:drawText("are licensed under MIT License.", Vec2(100, 100), Vec2(0.5))
        _Display:drawText("More info in README.txt", Vec2(100, 110), Vec2(0.5))
    elseif self.screen == "credits2" then
        _Display:drawText("Special Thanks", Vec2(100, 45), Vec2(0.5))
        _Display:drawText("- MumboJumbo for making Chainz,", Vec2(100, 60), Vec2(0.5))
        _Display:drawText("the game which I took inspiration from!", Vec2(100, 70), Vec2(0.5))
        _Display:drawText("- @increpare for making BFXR!", Vec2(100, 85), Vec2(0.5))
        _Display:drawText("- LOVE2D authors and community!", Vec2(100, 95), Vec2(0.5))
        _Display:drawText("esp. @Aidan, @softmagic, @Maiori.iso & others", Vec2(100, 105), Vec2(0.5))
    end

    --local alpha = 0.5 + (_Time % 2) * 0.5
    --if _Time % 2 > 1 then
    --    alpha = 1 + (1 - _Time % 2) * 0.5
    --end
    --_Display:drawText("Click anywhere to start!", Vec2(100, 80), Vec2(0.5), nil, nil, alpha)

    if self.fadeOutTime then
        _Display:drawRect(Vec2(), Vec2(200, 150), true, {0, 0, 0}, self.fadeOutTime)
    end
end



function MainMenu:mousepressed(x, y, button)
    if button == 1 then
        if self.screen == "main" then
            if self.selectedOption == 1 then
                self:transitionTo("_game")
            elseif self.selectedOption == 2 then
                self:transitionTo("settings")
            elseif self.selectedOption == 3 then
                self:transitionTo("credits")
            elseif self.selectedOption == 4 then
                self:transitionTo("_quit")
            end
        elseif self.screen == "settings" then
            if self.selectedOption == 1 then
                _Game.settings:increaseSoundVolume()
                self:initScreen("settings")
            elseif self.selectedOption == 2 then
                _Game.settings:increaseMusicVolume()
                self:initScreen("settings")
            elseif self.selectedOption == 3 then
                self:transitionTo("main")
            end
        elseif self.screen == "credits" then
            if self.selectedOption == 1 then
                self:transitionTo("credits2")
            elseif self.selectedOption == 2 then
                self:transitionTo("main")
            end
        elseif self.screen == "credits2" then
            if self.selectedOption == 1 then
                self:transitionTo("credits")
            elseif self.selectedOption == 2 then
                self:transitionTo("main")
            end
        end
        if self.selectedOption then
            _Game.SOUNDS.uiSelect:play()
        end
    elseif button == 2 then
        if self.screen == "settings" then
            if self.selectedOption == 1 then
                _Game.settings:decreaseSoundVolume()
                self:initScreen("settings")
                _Game.SOUNDS.uiSelect:play()
            elseif self.selectedOption == 2 then
                _Game.settings:decreaseMusicVolume()
                self:initScreen("settings")
                _Game.SOUNDS.uiSelect:play()
            end
        end
    end
end



function MainMenu:mousereleased(x, y, button)
    
end



function MainMenu:keypressed(key)
    if self.screen == "_game" then
        local keys = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0"}
        for i, k in ipairs(keys) do
            if k == key then
                _Game.levelNumber = i
            end
        end
    end
end



function MainMenu:focus(focus)
    
end



return MainMenu