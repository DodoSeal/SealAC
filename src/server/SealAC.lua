--[[ Seal AC v1.1 ]]

--[[ 
    How to Setup:

    1. Put the Module in ServerScriptService
    2. Require the Module in a Server Script
    3. Call the module.Init() function

    Custom Settings:

    - Any line commented with "This is editable"
    - module.Init() Values

    Side Notes:

    - The module:FetchLagBacks() function is for debug and moderation
    - Editing any values or functions that aren't meant to be will break the module
    - Make sure you set the Player's WalkSpeed and JumpHeight on the server
    - To Teleport a Player, call the module:TeleportPlr() function in a server script
 ]]

local module = {}

function module.Init()
    module.WalkSpeed = 16 -- This is editable
    module.LagBacks = 0
    module.Enabled = true
    module.CheckDelay = 0.1
    module.JumpHeight = 7.2 -- This is editable
    module.LastPos = Vector3.new(0, 0, 0)
end

function CheckFalling(Player)
    local Character = Player.Character
    local HRP = Character.HumanoidRootPart
    local Humanoid = Character.Humanoid

    if HRP.AssemblyLinearVelocity.Y > 0 and Humanoid:GetStateEnabled(Enum.HumanoidStateType.Freefall) then
        return "Falling"
    else
        return false
    end
end

function GetMagnitudes(X1, X2, Y1, Y2, Z1, Z2)
    local XZ1 = Vector3.new(X1, 0, Z1)
    local XZ2 = Vector3.new(X2, 0, Z2)
    local XZ_Mag = (XZ1 - XZ2).Magnitude

    local Y1 = Vector3.new(0, Y1, 0)
    local Y2 = Vector3.new(0, Y2, 0)
    local Y_Mag = (Y1 - Y2).Magnitude

    return {XZ_Mag, Y_Mag}
end

function module:TeleportPlr(Player, EndPos)
    local Character = Player.Character

    module.Enabled = false
    task.wait(0.2)

    Character:MoveTo(EndPos)

    task.wait(0.2)
    module.Enabled = true
end

function PlayerCooldown(Player)
    local Character = Player.Character
    local Humanoid = Character.Humanoid

    Humanoid.WalkSpeed = 8 -- This is editable
    Humanoid.JumpHeight = 3.6 -- This is editable
    task.wait(1)
    Humanoid.WalkSpeed = module.WalkSpeed
    Humanoid.JumpHeight = module.JumpHeight
end

function LagBack(Player, Position)
    local PlrCooldownCo = coroutine.wrap(PlayerCooldown)

    module.Enabled = false
    task.wait(module.CheckDelay)

    Player.Character:MoveTo(Position)
    PlrCooldownCo(Player)

    task.wait(module.CheckDelay)
    module.Enabled = true
    module.LagBacks = module.LagBacks + 1
    --print(Player.Name, "| LagBacks:", module.LagBacks) -- Printing for Debug
end

function module:FetchLagBacks() -- This is optional
    return module.LagBacks
end

game.Players.PlayerAdded:Connect(function(Player)
    Player.CharacterAdded:Connect(function(Character)
        while task.wait(module.CheckDelay) do
            if not Character:FindFirstChild("HumanoidRootPart") then return end

            module.LastPos = Character.HumanoidRootPart.Position
            task.wait(module.CheckDelay)
            local MagnitudeTable = GetMagnitudes(module.LastPos.X, Character.HumanoidRootPart.Position.X, module.LastPos.Y, Character.HumanoidRootPart.Position.Y, module.LastPos.Z, Character.HumanoidRootPart.Position.Z)
            local XZ_Mag = MagnitudeTable[1]
            local Y_Mag = MagnitudeTable[2]

            if module.Enabled == false then return end

            if XZ_Mag > (Character.Humanoid.WalkSpeed * module.CheckDelay) + 1 and CheckFalling(Player) == false then
                LagBack(Player, module.LastPos)
            end

            if Y_Mag > (Character.Humanoid.JumpHeight * module.CheckDelay) + 4 and CheckFalling(Player) == "Falling" then
                LagBack(Player, module.LastPos)
            end
        end
    end)
end)

return module
