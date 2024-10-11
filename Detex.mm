local player = game.Players.LocalPlayer
local camera = game.Workspace.CurrentCamera
local runService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local isCamLocked = false
local lockedPlayer = nil
local aimSpeed = 0.01 -- Adjust this for a stronger lock

-- Create sound effects
local lockSound = Instance.new("Sound")
lockSound.SoundId = "rbxassetid://YOUR_LOCK_SOUND_ID" -- Replace with your lock sound ID
lockSound.Volume = 0.5
lockSound.Parent = player.PlayerGui

local unlockSound = Instance.new("Sound")
unlockSound.SoundId = "rbxassetid://YOUR_UNLOCK_SOUND_ID" -- Replace with your unlock sound ID
unlockSound.Volume = 0.5
unlockSound.Parent = player.PlayerGui

-- Create a ScreenGui for health bars and button
local screenGui = Instance.new("ScreenGui", player.PlayerGui)

-- Create a draggable TextButton
local button = Instance.new("TextButton", screenGui)
button.Size = UDim2.new(0.15, 0, 0.05, 0) -- Adjust size as needed
button.Position = UDim2.new(0.5, -button.Size.X.Offset/2, 0.9, -button.Size.Y.Offset/2)
button.Text = "Toggle Camera Lock"
button.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
button.TextColor3 = Color3.new(1, 1, 1)

-- Function to create a health bar above the player's HumanoidRootPart
local function createHealthBar(player)
    local healthBar = Instance.new("Frame", screenGui)
    healthBar.Size = UDim2.new(0.1, 0, 0.02, 0)
    healthBar.BackgroundColor3 = Color3.new(0, 1, 0) -- Green
    healthBar.Position = UDim2.new(0.5, 0, 0.5, -40) -- Adjust as needed
    healthBar.Name = player.Name .. "_HealthBar"

    local healthDisplay = Instance.new("TextLabel", healthBar)
    healthDisplay.Size = UDim2.new(1, 0, 1, 0)
    healthDisplay.BackgroundTransparency = 1
    healthDisplay.TextColor3 = Color3.new(1, 1, 1) -- White
    healthDisplay.TextScaled = true

    return healthBar, healthDisplay
end

-- Function to create a green dot and health bar above the player's HumanoidRootPart
local function createGreenDot(player)
    local dot = Instance.new("BillboardGui")
    dot.Size = UDim2.new(0, 10, 0, 10)
    dot.Adornee = player.Character:WaitForChild("HumanoidRootPart")
    dot.AlwaysOnTop = true

    local frame = Instance.new("Frame", dot)
    frame.BackgroundColor3 = Color3.new(0, 1, 0) -- Green
    frame.Size = UDim2.new(1, 0, 1, 0)

    dot.StudsOffset = Vector3.new(0, 3, 0) -- 3 studs above
    dot.Parent = player.Character.HumanoidRootPart

    -- Create health bar for the player
    createHealthBar(player)
end

-- Create green dots and health bars for all players
for _, v in pairs(Players:GetPlayers()) do
    if v ~= player then
        createGreenDot(v)
    end
end

-- Function to lock camera on players with a green dot
local function lockCamera()
    if isCamLocked and lockedPlayer and lockedPlayer.Character then
        local targetPosition = lockedPlayer.Character.HumanoidRootPart.Position
        local currentPosition = camera.CFrame.Position

        -- Smoothly aim towards the target
        local newCameraPosition = currentPosition:Lerp(targetPosition + Vector3.new(0, 1, 2), aimSpeed)
        camera.CFrame = CFrame.new(newCameraPosition, targetPosition)

        -- Update health display
        local healthBar = screenGui:FindFirstChild(lockedPlayer.Name .. "_HealthBar")
        local healthDisplay = healthBar and healthBar:FindFirstChildOfClass("TextLabel")
        if healthDisplay then
            healthDisplay.Text = tostring(lockedPlayer.Health) .. "/" .. tostring(lockedPlayer.MaxHealth)
            -- Update health bar size
            healthBar.Size = UDim2.new(0.1 * (lockedPlayer.Health / lockedPlayer.MaxHealth), 0, 0.02, 0)
        end
    end
end

-- Button click event
button.MouseButton1Click:Connect(function()
    if not isCamLocked then
        local closestPlayer = nil
        local closestDistance = math.huge

        for _, v in pairs(Players:GetPlayers()) do
            if v ~= player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                local rootPosition = v.Character.HumanoidRootPart.Position
                local distance = (player.Character.HumanoidRootPart.Position - rootPosition).magnitude

                if distance < closestDistance then
                    closestDistance = distance
                    closestPlayer = v
                end
            end
        end

        if closestPlayer then
            isCamLocked = true
            lockedPlayer = closestPlayer
            lockSound:Play() -- Play lock sound
            Players:Chat("Camera locked on " .. lockedPlayer.Name) -- Chat notification
        end
    else
        isCamLocked = false
        lockedPlayer = nil
        unlockSound:Play() -- Play unlock sound
        Players:Chat("Camera unlocked") -- Chat notification
    end
end)

-- Draggable functionality
local dragging = false
local dragStart = nil
local startPos = nil

button.MouseButton1Down:Connect(function(input)
    dragging = true
    dragStart = input.Position
    startPos = button.Position
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        button.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = True
    end
end)

-- Check if the locked player is still valid
runService.RenderStepped:Connect(function()
    if isCamLocked and (not lockedPlayer or not lockedPlayer.Character or not lockedPlayer.Character:FindFirstChild("HumanoidRootPart")) then
        isCamLocked = false
        lockedPlayer = nil
    end
    lockCamera()
end)
