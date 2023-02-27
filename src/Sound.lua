local class = require "class"

local Sound = class:derive("Sound")

-- Place your imports here



function Sound:new(path, instances, isLooping, asMusic)
    instances = instances or 4
    self.volumeGovernedByMusicSetting = asMusic or false -- This is useful for music cues that are actually sounds (like level finish).

    self.instances = {}
    for i = 1, instances do
        self.instances[i] = {sound = love.audio.newSource(path, "static"), volume = 1}
        self.instances[i].sound:setLooping(isLooping or false)
    end

    self.volume = 1
end



function Sound:play(volume, pitch)
    volume = volume or 1
    pitch = pitch or 1
    
    local instance = self:getFreeInstance()
    instance.sound:stop()
    instance.sound:setVolume(volume * self.volume)
    instance.sound:setPitch(pitch)
    instance.sound:play()
    instance.volume = volume
end



function Sound:stop()
    for i, instance in ipairs(self.instances) do
        instance.sound:stop()
    end
end



function Sound:setVolume(volume, asMusic)
    asMusic = asMusic or false
    if self.volumeGovernedByMusicSetting ~= asMusic then
        return
    end
    
    for i, instance in ipairs(self.instances) do
        instance.sound:setVolume(instance.volume * volume)
    end
    self.volume = volume
end



function Sound:getFreeInstance()
    for i, instance in ipairs(self.instances) do
        if not instance.sound:isPlaying() then
            return instance
        end
    end
    return self.instances[1]
end



return Sound