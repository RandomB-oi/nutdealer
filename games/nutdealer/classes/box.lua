local module = {}
module.__index = module

local serial = 0

module.all = {}

local shadowColor = color.new(0,0,0,0.5)

module.new = function(scene)
	local self = setmetatable({}, module)
	self.maid = maid.new()
	self.scene = scene
    self.id = serial
    serial = serial + 1

	self.position = vector2.new(0, 0)
	self.size = vector2.new(100, 100)
    self.collidable = true

	self.hasShadow = true

    self.touched = signal.new()
	self.maid:giveTask(self.touched)
    self.touchEnded = signal.new()
	self.maid:giveTask(self.touchEnded)

	self.onInteract = signal.new()
	self.maid:giveTask(self.onInteract)

	local mainColor = color.new(1,1,1,1)
	self.maid.draw = self.scene.draw:connect(function()
		local size = self.size
		local pos = self.position
		
		love.graphics.push()
		love.graphics.translate(pos.x+size.x/2, pos.y+size.y/2)
		
		if self.hasShadow then
			shadowColor:apply()
			if self.image then
				love.graphics.cleanDrawImage(self.image, -size/2, size + 25)
			else
				love.graphics.rectangle("fill", -size.x/2, -size.y/2+ 25, size.x, size.y)
			end
		end

		local color = (self.color or mainColor) --* self:getLightColor()
		color:apply()
		if self.image then
			love.graphics.cleanDrawImage(self.image, -size/2, size)
		else
			love.graphics.rectangle("fill", -size.x/2, -size.y/2, size.x, size.y)
		end

		love.graphics.pop()
	end)
	
    module.all[self.id] = self
    self.maid:giveTask(function()
        module.all[self.id] = nil
    end)

	return self
end

function module:destroy()
	self.maid:destroy()
end

module.init = function()
	instance.addClass("box", module)
end

return module