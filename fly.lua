-- Fly GUI LocalScript
-- Place this LocalScript in StarterPlayer > StarterPlayerScripts.
-- Creates its own GUI. Toggle Fly, then move with WASD / thumbstick.
-- Space = rise, LeftControl = descend. Press Fly again to stop.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local FLY_SPEED = 65
local VERTICAL_SPEED = 50

local flying = false
local character
local humanoid
local rootPart
local attachment
local velocity
local orientation
local flyConnection
local inputConnection
local keys = {
    W = false, A = false, S = false, D = false,
    Space = false, LeftControl = false
}

local function getCharacter()
    character = player.Character or player.CharacterAdded:Wait()
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
end

getCharacter()

-- GUI
local oldGui = playerGui:FindFirstChild("FlyGui")
if oldGui then oldGui:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "FlyGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(220, 112)
panel.Position = UDim2.new(0, 20, 0.45, 0)
panel.BackgroundColor3 = Color3.fromRGB(24, 25, 34)
panel.BorderSizePixel = 0
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(90, 160, 255)
stroke.Thickness = 1.5
stroke.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 30)
title.Position = UDim2.fromOffset(10, 7)
title.BackgroundTransparency = 1
title.Text = "FLIGHT CONTROL"
title.TextColor3 = Color3.fromRGB(235, 240, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.Parent = panel

local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(1, -24, 0, 38)
toggle.Position = UDim2.fromOffset(12, 42)
toggle.BackgroundColor3 = Color3.fromRGB(45, 105, 190)
toggle.Text = "FLY: OFF"
toggle.TextColor3 = Color3.new(1, 1, 1)
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 15
toggle.AutoButtonColor = true
toggle.Parent = panel

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggle

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -16, 0, 22)
hint.Position = UDim2.fromOffset(8, 83)
hint.BackgroundTransparency = 1
hint.Text = "WASD move • Space up • Ctrl down"
hint.TextColor3 = Color3.fromRGB(170, 180, 200)
hint.Font = Enum.Font.Gotham
hint.TextSize = 10
hint.Parent = panel

local function setFlyButton()
    toggle.Text = flying and "FLY: ON" or "FLY: OFF"
    toggle.BackgroundColor3 = flying
        and Color3.fromRGB(25, 155, 105)
        or Color3.fromRGB(45, 105, 190)
end

local function cleanupFlight()
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    if velocity then velocity:Destroy(); velocity = nil end
    if orientation then orientation:Destroy(); orientation = nil end
    if attachment then attachment:Destroy(); attachment = nil end
    if humanoid and humanoid.Parent then
        humanoid.PlatformStand = false
        humanoid.AutoRotate = true
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

local function stopFlying()
    flying = false
    cleanupFlight()
    setFlyButton()
end

local function startFlying()
    if not character or not humanoid or not rootPart
        or humanoid.Health <= 0 then
        getCharacter()
    end

    if not rootPart or not humanoid or humanoid.Health <= 0 then
        return
    end

    flying = true
    humanoid.AutoRotate = false
    humanoid.PlatformStand = true

    attachment = Instance.new("Attachment")
    attachment.Name = "FlyAttachment"
    attachment.Parent = rootPart

    velocity = Instance.new("LinearVelocity")
    velocity.Name = "FlyVelocity"
    velocity.Attachment0 = attachment
    velocity.RelativeTo = Enum.ActuatorRelativeTo.World
    velocity.VectorVelocity = Vector3.zero
    velocity.MaxForce = math.huge
    velocity.Parent = rootPart

    orientation = Instance.new("AlignOrientation")
    orientation.Name = "FlyOrientation"
    orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    orientation.Attachment0 = attachment
    orientation.Responsiveness = 18
    orientation.MaxTorque = math.huge
    orientation.Parent = rootPart

    setFlyButton()

    flyConnection = RunService.RenderStepped:Connect(function()
        if not flying or not rootPart or not rootPart.Parent then
            stopFlying()
            return
        end

        local camera = workspace.CurrentCamera
        if not camera then return end

        local forward = camera.CFrame.LookVector
        local right = camera.CFrame.RightVector
        local move = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += forward end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= forward end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += right end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= right end

        -- Keep keyboard movement level; vertical movement has separate controls.
        move = Vector3.new(move.X, 0, move.Z)
        if move.Magnitude > 0 then
            move = move.Unit * FLY_SPEED
        end

        local vertical = 0
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            vertical += VERTICAL_SPEED
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            vertical -= VERTICAL_SPEED
        end

        velocity.VectorVelocity = move + Vector3.new(0, vertical, 0)

        local look = Vector3.new(forward.X, 0, forward.Z)
        if look.Magnitude > 0.01 then
            orientation.CFrame = CFrame.lookAt(Vector3.zero, look.Unit)
        end
    end)
end

toggle.Activated:Connect(function()
    if flying then
        stopFlying()
    else
        startFlying()
    end
end)

-- Keep the GUI button in sync after respawning and remove old flight movers.
player.CharacterAdded:Connect(function(newCharacter)
    stopFlying()
    character = newCharacter
    humanoid = newCharacter:WaitForChild("Humanoid")
    rootPart = newCharacter:WaitForChild("HumanoidRootPart")
end)

-- Reset key state if the window loses focus.
UserInputService.WindowFocusReleased:Connect(function()
    for key in pairs(keys) do
        keys[key] = false
    end
end)

setFlyButton()
