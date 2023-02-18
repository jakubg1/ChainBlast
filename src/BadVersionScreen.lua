local class = require "class"

local BadVersionScreen = class:derive("BadVersionScreen")

-- Place your imports here



function BadVersionScreen:new()
    self.font = love.graphics.newFont(18)
    self.text = "You're using an outdated version of LOVE2D!\nYou need to download 12.0.\n\nClick on this screen to open a Github page where you can download the new version."
    self.url = "https://github.com/love2d/love/actions?query=branch%3A12.0-development"

    self.text = self.text .. "\n\nOr here's the URL itself:\n" .. self.url
end



function BadVersionScreen:update(dt)
    -- nada
end



function BadVersionScreen:draw()
    love.graphics.setFont(self.font)
    love.graphics.print(self.text, 10, 10)
end



function BadVersionScreen:mousepressed(x, y, button)
    if button == 1 then
        love.system.openURL(self.url)
    end
end



return BadVersionScreen