local class = require "class"

local Sound = class:derive("Sound")

-- Place your imports here



function Sound:new(path, instances)
    instances = instances or 4
    self.instances = {}
    for i = 1, instances do
        self.instances[i] = love.audio.newSource(path, "static")
    end
end



function Sound:play(pitch)
    pitch = pitch or 1
    
    local instance = self:getFreeInstance()
    instance:setPitch(pitch)
    instance:stop()
    instance:play()
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