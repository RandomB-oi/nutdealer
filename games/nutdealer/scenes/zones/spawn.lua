local module = {}

local scene
local dialog
module.init = function()
    scene = mainGame:getScene("main-game")
    dialog = mainGame:getScene("dialog")
end

module.start = function()
    slotLoaded:connect(function(slotName, loadedData)
        local topWall = instance.new("box", scene)
        topWall.size = vector2.new(600, 50)
        local leftWall = instance.new("box", scene)
        leftWall.size = vector2.new(25, 400)
        local rightWall = instance.new("box", scene)
        rightWall.size = vector2.new(25, 400)
        rightWall.position = vector2.new(575, 0)
        local bottomWall = instance.new("box", scene)
        bottomWall.size = vector2.new(300, 50)
        bottomWall.position = vector2.new(0, 350)

        mainGame:createFlag("introduction", function(flagMaid)
            dialog.doDialog("hello")
            dialog.doDialog("welcome to nutdealer")
            dialog.doDialog("we uhhh... deal nuts or something ^-^")

            mainGame:reachFlag("introduction")
        end)
        
        mainGame:createFlag("talkBox", function(flagMaid)
            local talkBox = instance.new("box", scene)
            talkBox.position = vector2.new(250, 100)
            talkBox.size = vector2.new(50,50)
            talkBox.collidable = false
            talkBox.onInteract:connect(function()
                dialog.doDialog("I am *THE* nut dealer, do you want some nuts?", true)
                local response = mainGame:getScene("dialog").askQuestion({"sure", "no thanks"})

                if response == 1 then
                    dialog.doDialog("i took your money >:D")
                    
                    mainGame:reachFlag("talkBox")
                    return
                end

                dialog.doDialog("now let me be")
                dialog.doDialog("VERY CLEAR")

                mainGame:reachFlag("talkBox")
            end)
            flagMaid:giveTask(talkBox)
        end)
    end, 1)
end

return module