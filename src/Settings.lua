local class = require "class"

local Settings = class:derive("Settings")

-- Place your imports here



function Settings:new()
    self.PATH = "settings.txt"

    self.musicVolume = 0.5
    self.soundVolume = 0.2
end



function Settings:decreaseMusicVolume()
    self.musicVolume = math.max(math.floor((self.musicVolume - 0.1) * 10 + 0.5) / 10, 0)
    self:apply()
end

function Settings:increaseMusicVolume()
    self.musicVolume = math.min(math.floor((self.musicVolume + 0.1) * 10 + 0.5) / 10, 1)
    self:apply()
end



function Settings:decreaseSoundVolume()
    self.soundVolume = math.max(math.floor((self.soundVolume - 0.1) * 10 + 0.5) / 10, 0)
    self:apply()
end

function Settings:increaseSoundVolume()
    self.soundVolume = math.min(math.floor((self.soundVolume + 0.1) * 10 + 0.5) / 10, 1)
    self:apply()
end



function Settings:apply()
    for soundN, sound in pairs(_Game.SOUNDS) do
        sound:setVolume(self.soundVolume)
        sound:setVolume(self.musicVolume, true)
    end
    for musicN, music in pairs(_Game.MUSIC) do
        music:setVolume(self.musicVolume)
    end
end



function Settings:load()
    local success, contents = pcall(function() return _LoadJson(self.PATH) end)
    if success and contents then
        self.musicVolume = contents.musicVolume
        self.soundVolume = contents.soundVolume
    end
    self:apply()
end



function Settings:save()
    local t = {
        musicVolume = self.musicVolume,
        soundVolume = self.soundVolume
    }
    _SaveJson(self.PATH, t)
end



return Settings