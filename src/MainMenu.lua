local class = require "class"

local MainMenu = class:derive("MainMenu")

-- Place your imports here
local Vec2 = require("src.Vector2")
local Star = require("src.Star")



function MainMenu:new()
    self.screen = ""
    self.screenTransition = nil
    self.screenTransitionTarget = nil
    self.fadeTime = nil

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

    self:initScreen("main")
end



function MainMenu:update(dt)
    self.selectedOption = nil
    if self.screenTransition then
        self.screenTransition = self.screenTransition + dt
        if self.screenTransition >= 0.6 then
            self:initScreen(self.screenTransitionTarget)
            self.screenTransition = nil
            self.screenTransitionTarget = nil
        end
    elseif self.fadeTime then
        self.fadeTime = self.fadeTime + dt
        if self.fadeTime >= 1 then
            _Game:startLevel()
        end
    else
        for i, option in ipairs(self.options) do
            if _MousePos.x >= 60 and _MousePos.x <= 140 and _MousePos.y >= self.optionsY + i * 10 and _MousePos.y < self.optionsY + (i + 1) * 10 then
                self.selectedOption = i
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
        self.options = {"No settings yet...", "Go Back"}
        self.optionsY = 60
    elseif screen == "credits" then
        self.optionsHeader = nil
        self.options = {"Back"}
        self.optionsY = 120
    elseif screen == "_game" then
        self.fadeTime = 0
    elseif screen == "_quit" then
        love.event.quit()
    end
end



function MainMenu:transitionTo(screen)
    self.screenTransition = 0
    self.screenTransitionTarget = screen
end



function MainMenu:getJoke()
    local jokes = _LoadFile("pre_assets/witties.txt")
    if jokes then
        jokes = _StrSplit(jokes, "\n")
        return jokes[love.math.random(#jokes)]
    end
end



function MainMenu:draw()
    for i, star in ipairs(self.stars) do
        star:draw()
    end

    _Display:drawText("Connext? Chain Blast?", Vec2(100, 30), Vec2(0.5), nil, {0, 1, 0})

    if self.optionsHeader then
        _Display:drawText(self.optionsHeader, Vec2(100, self.optionsY - 5), Vec2(0.5, 0))
    end
    for i, option in ipairs(self.options) do
        local color = (i == self.selectedOption) and {1, 1, 1} or {0.8, 0.8, 0.8}
        _Display:drawText(option, Vec2(100, self.optionsY + i * 10), Vec2(0.5, 0), nil, color)
    end
    local xSeparation = self.cursorAnimH * self.cursorAnimH * 320
    local color = _GetRainbowColor(_Time / 4)
    _Display:drawText(">", Vec2(70 + math.sin(_Time * math.pi) * 4 - xSeparation, self.optionsY + self.cursorAnim * 10), Vec2(1, 0), nil, color)
    _Display:drawText("<", Vec2(130 - math.sin(_Time * math.pi) * 4 + xSeparation, self.optionsY + self.cursorAnim * 10), Vec2(0, 0), nil, color)

    _Display:drawText("LOVE Jam Demo", Vec2(2, 150), Vec2(0, 1))

    if self.screen == "main" and self.joke then
        _Display:drawText(self.joke, Vec2(200 - self.jokeTime * 25, 130), Vec2(0, 0.5), nil, {0.5, 0.5, 0.5})
    end

    if self.screen == "credits" then
        _Display:drawText("Made with <3", Vec2(100, 50), Vec2(0.5))
        _Display:drawText("For the LOVE Jam 2023!", Vec2(100, 60), Vec2(0.5))
        _Display:drawText("Music by @Crisps", Vec2(100, 80), Vec2(0.5))
        _Display:drawText("Copyright (C) 2023 jakubg1", Vec2(100, 100), Vec2(0.5))
        _Display:drawText("All assets and code are licensed", Vec2(100, 110), Vec2(0.5))
        _Display:drawText("under MIT License.", Vec2(100, 120), Vec2(0.5))
    end

    --local alpha = 0.5 + (_Time % 2) * 0.5
    --if _Time % 2 > 1 then
    --    alpha = 1 + (1 - _Time % 2) * 0.5
    --end
    --_Display:drawText("Click anywhere to start!", Vec2(100, 80), Vec2(0.5), nil, nil, alpha)

    if self.fadeTime then
        _Display:drawRect(Vec2(), Vec2(200, 150), true, {0, 0, 0}, self.fadeTime)
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
            if self.selectedOption == 2 then
                self:transitionTo("main")
            end
        elseif self.screen == "credits" then
            if self.selectedOption == 1 then
                self:transitionTo("main")
            end
        end
    end
end



function MainMenu:mousereleased(x, y, button)
    
end



return MainMenu