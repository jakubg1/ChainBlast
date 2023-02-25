local class = require "class"

local Display = class:derive("Display")

-- Place your imports here
local Vec2 = require("src.Vector2")



function Display:new()
    self.SIZE = Vec2(200, 150)
    self.SCALE = 4

    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("rough")
    self.canvas = love.graphics.newCanvas(200, 150)
end



function Display:activate()
    love.graphics.setCanvas(self.canvas)
end



function Display:drawLine(pos1, pos2, color, alpha, width)
    color = color or {1, 1, 1}
    width = width or 1
    love.graphics.setColor(color[1], color[2], color[3], alpha)
    love.graphics.setLineWidth(width)
    love.graphics.line(pos1.x + 0.5, pos1.y + 0.5, pos2.x + 0.5, pos2.y + 0.5)
end



function Display:drawRect(pos, size, filled, color, alpha)
    color = color or {1, 1, 1}
    love.graphics.setColor(color[1], color[2], color[3], alpha)
    love.graphics.rectangle(filled and "fill" or "line", pos.x, pos.y, size.x, size.y)
end



function Display:drawSprite(sprite, state, pos, color, alpha)
    color = color or {1, 1, 1}
    love.graphics.setColor(color[1], color[2], color[3], alpha)
    pos = pos:floor()
    if state then
        love.graphics.draw(sprite:getTexture(), sprite:getState(state), pos.x, pos.y)
    else
        love.graphics.draw(sprite:getTexture(), pos.x, pos.y)
    end
end



function Display:drawText(text, pos, align, font, color, alpha)
    color = color or {1, 1, 1}
    font = font or _Game.FONTS.standard

    love.graphics.setColor(color[1], color[2], color[3], alpha)
    love.graphics.setFont(font)
    if align then
        local size = self:getTextSize(text, font)
        pos = (pos - size * align):floor()
    end
    love.graphics.print(text, pos.x, pos.y)
end



function Display:getTextSize(text, font)
    font = font or _Game.FONTS.standard
    return Vec2(font:getWidth(text), font:getHeight())
end



function Display:draw()
    --love.graphics.setCanvas(self.canvas)
    --love.graphics.setColor(0.5, 1, 0)
    --love.graphics.line(0, 10, 100, 75)

    -- Draw the pixels onto the screen.
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.canvas, 0, 0, 0, self.SCALE)

    -- Clear the canvas and prepare it for the next frame.
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear()
end



return Display