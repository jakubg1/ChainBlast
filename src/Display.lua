local class = require "class"

local Display = class:derive("Display")

-- Place your imports here
local Vec2 = require("src.Vector2")



function Display:new()
    self.SIZE = Vec2(240, 135)
    self.mousePos = Vec2()

    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("rough")
    self.canvas = love.graphics.newCanvas(self.SIZE.x, self.SIZE.y)
    self.motionBlurCanvas = love.graphics.newCanvas(self.SIZE.x, self.SIZE.y)
    self.motionBlurStrength = 0 -- 0.65?

    -- On my particular laptop with AMD A9, the lines and rectangles are drawn one pixel lower than they should.
    -- I have no idea why's that, but this value hopefully resolves the problem.
    local name, version, vendor, device = love.graphics.getRendererInfo()
    self.PRIMITIVE_Y_ADJUST = (device == "AMD Radeon(TM) R5 Graphics") and 0 or 0.5
end



function Display:update(dt)
    self.mousePos = (_MousePos - self:getCanvasOffset()) / self:getScale()
end



function Display:getScale()
    local windowSize = Vec2(love.window.getMode())
    return math.floor(windowSize.y / self.SIZE.y)
end



function Display:getCanvasOffset()
    local windowSize = Vec2(love.window.getMode())
    return ((windowSize - self.SIZE * self:getScale()) / 2):floor()
end



function Display:activate()
    love.graphics.setCanvas(self.canvas)
end



function Display:drawLine(pos1, pos2, color, alpha, width)
    color = color or {1, 1, 1}
    width = width or 1
    love.graphics.setColor(color[1], color[2], color[3], alpha)
    love.graphics.setLineWidth(width)
    love.graphics.line(pos1.x + 0.5, pos1.y + 0.5 + self.PRIMITIVE_Y_ADJUST, pos2.x + 0.5, pos2.y + 0.5 + self.PRIMITIVE_Y_ADJUST)
end



function Display:drawRect(pos, size, filled, color, alpha)
    color = color or {1, 1, 1}
    love.graphics.setColor(color[1], color[2], color[3], alpha)
    love.graphics.rectangle(filled and "fill" or "line", pos.x, pos.y + self.PRIMITIVE_Y_ADJUST, size.x, size.y)
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



function Display:drawText(text, pos, align, font, color, alpha, scale)
    color = color or {1, 1, 1}
    font = font or _Game.FONTS.standard
    scale = scale or 1

    love.graphics.setColor(color[1], color[2], color[3], alpha)
    love.graphics.setFont(font)
    if align then
        local size = self:getTextSize(text, font) * scale
        pos = (pos - size * align):floor()
    end
    love.graphics.print(text, pos.x, pos.y, 0, scale)
end



function Display:getTextSize(text, font)
    font = font or _Game.FONTS.standard
    return Vec2(font:getWidth(text), font:getHeight())
end



function Display:draw()
    --love.graphics.setCanvas(self.canvas)
    --love.graphics.setColor(0.5, 1, 0)
    --love.graphics.line(0, 10, 100, 75)

    -- Apply motion blur.
    love.graphics.setColor(1, 1, 1, self.motionBlurStrength)
    love.graphics.draw(self.motionBlurCanvas)

    -- Draw the pixels onto the screen.
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1)
    local offset = self:getCanvasOffset()
    love.graphics.draw(self.canvas, offset.x, offset.y, 0, self:getScale())

    -- Store the frame onto the motion blur buffer.
    love.graphics.setCanvas(self.motionBlurCanvas)
    love.graphics.draw(self.canvas)

    -- Clear the canvas and prepare it for the next frame.
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear()
end



return Display