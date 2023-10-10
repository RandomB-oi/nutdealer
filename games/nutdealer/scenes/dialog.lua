local module = {}

local scene
module.init = function()
	scene = mainGame:getScene("dialog")
	scene:unpause()
	scene:enable()

    local dialogGui = instance.new("gui", scene)
	dialogGui.size = udim2.new(1, 0, 0.4, 0)
	dialogGui.position = udim2.new(0.5, 0, 1, 0)
	dialogGui.anchorPoint = vector2.new(0.5, 1)
	dialogGui.color = color.from255(0,0,0)
	
    local textBox = instance.new("text", scene)
    textBox.size = udim2.fromScale(1,1)
    textBox.parent = dialogGui

    local actionLabels = {}
    for y = 1, 3 do
        for x = 1, 2 do
            local newActionLabel = instance.new("text", scene)
            newActionLabel.size = udim2.new(0.5, 0, 0.333, 0)
            newActionLabel.position = udim2.new(x-1, 0, y/3, 0)
            newActionLabel.anchorPoint = vector2.new(x-1, 1)
            newActionLabel.color = color.from255(255,255,255,100)
            newActionLabel.parent = dialogGui
            newActionLabel.active = false
            actionLabels[(y-1)*2+x] = newActionLabel
        end
    end

    dialogGui.active = false

    local dialogMaid = maid.new()
    local dialogSignal = signal.new()
    local letterSlow = {
        ["."] = 1/3,
        ["?"] = 1/2,
        ["!"] = 1/2,
        [","] = 1/5,
    }
    function scene.doDialog(text)
        dialogMaid:destroy()
        local begin = os.clock()
        local lengths = {}
        for i = 1, text:len(), 1 do
            local letter = text:sub(i,i)
            local length = letterSlow[letter] or (1/20)
            table.insert(lengths, length)
        end
        textBox:setText("")
        dialogGui.active = true
        textBox.active = true
        module.dialogActive = true
        local done = false
        dialogMaid:giveTask(function()
            dialogGui.active = false
            textBox.active = false
            module.dialogActive = false
        end)
        dialogMaid:giveTask(scene.update:connect(function(dt)
            local timePassed = os.clock() - begin

            local newText = nil
            for i, dur in ipairs(lengths) do
                if timePassed >= dur then
                    timePassed = timePassed - dur
                    newText = text:sub(1, i)
                    if i == #lengths then
                        done = true
                    end
                else
                    break
                end
            end
            if newText then
                textBox:setText(newText)
            end
        end))

        local gameScene = mainGame:getScene("main-game")
        dialogMaid:giveTask(scene.inputBegan:connect(function(key)
            if key == keybinds.dialogSkip and not done then
                textBox:setText(text)
                begin = -math.huge
            elseif key == keybinds.dialogAdvance and done then
                gameScene:unpause()
                dialogSignal:fire()
            end
        end, 12))

        dialogMaid:giveTask(dialogSignal)

        gameScene:pause()

        dialogSignal:wait()
        dialogMaid:destroy()
    end

    function scene.askQuestion(responses)
        local gameScene = mainGame:getScene("main-game")
        local selection = 1

        dialogGui.active = true
        module.dialogActive = true
        dialogMaid:giveTask(function()
            gameScene:unpause()
            dialogGui.active = false
            module.dialogActive = false

            for index, actionLabel in pairs(actionLabels) do
                actionLabel.active = false
            end
        end)

        dialogMaid:giveTask(scene.inputBegan:connect(function(key)
            if key == keybinds.dialogAdvance then
                gameScene:unpause()
                dialogSignal:fire()
                return
            end

            local directions = {
                [keybinds.up] = selection - 2,
                [keybinds.down] = selection + 2,
                [keybinds.left] = selection - 1,
                [keybinds.right] = selection + 1,
            }
            local dir = directions[key]
            if dir and responses[dir] then
                selection = dir
            end
        end))
        dialogMaid:giveTask(scene.guiDraw:connect(function()
            for index, actionLabel in pairs(actionLabels) do
                if responses[index] then
                    actionLabel:setText(responses[index])
                    if index == selection then
                        actionLabel.color.a = 1
                    else
                        actionLabel.color.a = 1/4
                    end
                    actionLabel.active = true
                else
                    actionLabel.active = false
                end
            end
        end))

        gameScene:pause()

        dialogMaid:giveTask(dialogSignal)
        dialogSignal:wait()
        dialogMaid:destroy()

        return selection
    end
end

module.start = function()
    -- scene.doDialog("Hello World!")
end

return module