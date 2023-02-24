local class = require "class"

local Sound = class:derive("Sound")

-- Place your imports here



function Sound:new(path, instances, isLooping)
    instances = instances or 4
    self.instances = {}
    for i = 1, instances do
        self.instances[i] = love.audio.newSource(path, "static")
        self.instances[i]:setLooping(isLooping or false)
    end
end



function Sound:play(volume, pitch)
    volume = volume or 1
    pitch = pitch or 1
    
    local instance = self:getFreeInstance()
    instance:stop()
    instance:setVolume(volume)
    instance:setPitch(pitch)
    instance:play()
end



function Sound:stop()
    for i, instance in ipairs(self.instances) do
        instance:stop()
    end
end



function Sound:getFreeInstance()
    for i, instance in ipairs(self.instances) do
        if not instance:isPlaying() then
            return instance
        end
    end
    return self.instances[1]
end



return Sound