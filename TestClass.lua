local class = require "class"

local TestClass = class:derive("TestClass")

-- Place your imports here



function TestClass:new(x)
    self.x = x
end


function TestClass:update(x)
    self.x = self.x + x
end


function TestClass:print()
    print(self.x)
end



return TestClass