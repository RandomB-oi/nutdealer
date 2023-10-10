local module = {}

keybinds = {
    interact = "return",
    dialogAdvance = "return",

    dialogSkip = "rshift",

    sprint = "lshift",
    left = "a",
    right = "d",
    up = "w",
    down = "s",
}

local scene
module.init = function()
	scene = mainGame:getScene("main-game")
	scene:pause()
	scene:disable()

    love.graphics.setBackgroundColor(0,0.5,0)

    mainCharacter = instance.new("entity", scene)

    scene.inputBegan:connect(function(key)
        if mainGame:getScene("dialog").dialogActive then return end
        if key == keybinds.interact then
            for index, box in pairs(instance.getClass("box").all) do
                if mainCharacter:isIntersecting(box.position, box.size) then
                    box.onInteract:fire()
                    return
                end
            end
        end
    end,9)

    local lastSave = os.clock()
    scene.update:connect(function(dt)
        local moveDirection = vector2.new()

        do
            local t = os.clock()
            if t - lastSave > 1 then
                lastSave = t
                mainGame:saveSlot()
            end
        end

        local facing

        if love.keyboard.isDown(keybinds.up) then
            moveDirection.y = moveDirection.y - 1
            facing = "n"
        end
        if love.keyboard.isDown(keybinds.down) then
            moveDirection.y = moveDirection.y + 1
            facing = "s" 
        end
        if love.keyboard.isDown(keybinds.left) then
            moveDirection.x = moveDirection.x - 1
            facing = "w"
        end
        if love.keyboard.isDown(keybinds.right) then
            moveDirection.x = moveDirection.x + 1
            facing = "e"
        end
        
        local walkspeed = 100
        if love.keyboard.isDown(keybinds.sprint) then
            walkspeed = walkspeed * 2
        end

        mainCharacter.facing = facing or mainCharacter.facing
        mainCharacter.velocity = moveDirection * walkspeed
    end)
end

module.start = function()
    slotLoaded:connect(function(slotName, loadedData)
        if loadedData.playerPosition then
            mainCharacter.position.x = loadedData.playerPosition.x
            mainCharacter.position.y = loadedData.playerPosition.y
        end
    end)
end

return module