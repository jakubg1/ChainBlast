local class = require "class"

local Explosion = class:derive("Explosion")

-- Place your imports here
local Vec2 = require("src.Vector2")



function Explosion:new(pos)
    self.pos = pos
    self.frame = 1
end



function Explosion:update(dt)
    self.frame = self.frame + dt * 30
end



function Explosion:canDespawn()
    return self.frame >= 10
end



function Explosion:draw()
    _Display:drawSprite(_Game.SPRITES.explosion1, math.floor(self.frame), self.pos)
end



return Explosion