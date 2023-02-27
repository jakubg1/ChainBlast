local class = require "class"

local Music = class:derive("Music")

-- Place your imports here



function Music:new(path)
    self.sound = love.audio.newSource(path, "stream")
    self.sound:setLooping(true)

    self.volume = 0
    self.settingsVolume = 1

    self.targetVolumeStart = 0
    self.targetVolume = 0
    self.targetTime = nil
    self.targetTimeMax = nil
    self.targetStop = false
end



function Music:update(dt)
    if self.targetTime then
        self.targetTime = self.targetTime + dt
        local t = self.targetTime / self.targetTimeMax
        self.volume = self.targetVolumeStart * (1 - t) + self.targetVolume * t
        if self.targetTime >= self.targetTimeMax then
            if self.targetStop then
                self.sound:stop()
            end
            self.volume = self.targetVolume
            self.targetTime = nil
            self.targetTimeMax = nil
            self.targetStop = false
        end
        self.sound:setVolume(self.volume * self.settingsVolume)
    end

    if self.volume == 0 and self.sound:isPlaying() then
        self.sound:pause()
    end

    if self.volume > 0 and not self.sound:isPlaying() then
        self.sound:play()
    end
end



function Music:play(volume, transitionTime)
    volume = volume or 1
    transitionTime = transitionTime or 0

    self.targetVolumeStart = self.volume
    self.targetVolume = volume
    self.targetTime = 0
    self.targetTimeMax = transitionTime
end



function Music:stop(transitionTime)
    transitionTime = transitionTime or 0

    self.targetVolumeStart = self.volume
    self.targetVolume = 0
    self.targetTime = 0
    self.targetTimeMax = transitionTime
    self.targetStop = true
end



function Music:setVolume(volume)
    self.sound:setVolume(self.volume * volume)
    self.settingsVolume = volume
end



return Music