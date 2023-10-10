local module = {}
module.__index = module
module.derives = "games/topdowngame/classes/item"

module.new = function(self)
	self.itemClass = "pickaxe"
	self.stackSize = 1
	self.image = love.graphics.newImage("games/topdowngame/assets/pickaxe.png")
	self.color = color.new(1, 1, 1)
	
	return self
end

function module:use()
	print(":3")
end

module.init = function()
	instance.addClass("pickaxe", module)
end

module.start = function()
	module.addRecipe(
		{
			"sss",
			"_w_",
			"_w_",
		}, 
		{
			s="stone",
			w="wood",
		}, 
		{
			name="pickaxe",
			amount=1,
			itemClass="pickaxe"
		})
end

return module