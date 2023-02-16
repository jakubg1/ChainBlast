local TestClass = require("TestClass")



function love.load()
    _Test = TestClass(10)
end



function love.update(dt)
    _Test:update(dt)
    _Test:print()
end



function love.draw()

end