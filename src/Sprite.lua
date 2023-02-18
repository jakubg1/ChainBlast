local class = require "class"

local Sprite = class:derive("Sprite")

-- Place your imports here



function Sprite:new(texPath, states)
    self.texture = love.graphics.newImage(texPath)
    self.states = {}

    for stateN, state in pairs(states) do
        self.states[stateN] = love.graphics.newQuad(state.pos.x, state.pos.y, state.size.x, state.size.y, self.texture:getWidth(), self.texture:getHeight())
    end
end



function Sprite:getTexture()
    return self.texture
end



function Sprite:getState(name)
    return self.states[name]
end



return Sprite