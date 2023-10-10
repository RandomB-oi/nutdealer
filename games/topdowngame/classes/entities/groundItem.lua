local module = {}
module.__index = module
module.derives = "games/topdowngame/classes/entity"

module.new = function(self)
	self.size = vector2.new(0.5, 0.5)
	self.item = nil

	self.maid.draw = self.scene.draw:connect(function()
		if self.item then
			local size = self.size * self.world.blockSize
			local pos = self.position * self.world.blockSize
			local cf = cframe.new(pos.x, pos.y)
			self.item:render(cf, size)
		end
	end)
	
	return self
end

module.init = function()
	instance.addClass("groundItem", module)
end

return module