-- BuzzScript Rivals - Fully Functional Executor-Safe Cheat
-- Billboard ESP + Cursor Aim Assist + GUI + FOV Circle

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

-- SETTINGS
local ESP_Color = Color3.fromRGB(255, 140, 0)
local AimFOV = 85
local AimSpeed = 0.25 -- Lower = faster lock

local HoldingShoot = false
local ESP_Enabled = false
local Aimlock_Enabled = false

-- GUI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "BuzzScriptRivals"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 200, 0, 110)
frame.Position = UDim2.new(0.05, 0, 0.05, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
title.TextColor3 = Color3.new(1,1,1)
title.Text = "BuzzScript Rivals"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16

local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size = UDim2.new(0, 25, 0, 25)
closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 18
closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
    for _,v in pairs(Players:GetPlayers()) do
        if v.Character and v.Character:FindFirstChild("BuzzESP") then
            v.Character.BuzzESP:Destroy()
        end
    end
    ESP_Enabled = false
    Aimlock_Enabled = false
    if FOVCircle then
        FOVCircle.Visible = false
        FOVCircle:Remove()
    end
end)

local toggleESP = Instance.new("TextButton", frame)
toggleESP.Size = UDim2.new(1, -20, 0, 25)
toggleESP.Position = UDim2.new(0, 10, 0, 35)
toggleESP.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
toggleESP.TextColor3 = Color3.new(1,1,1)
toggleESP.Text = "Enable ESP"
toggleESP.Font = Enum.Font.SourceSans
toggleESP.TextSize = 16

local toggleAimlock = Instance.new("TextButton", frame)
toggleAimlock.Size = UDim2.new(1, -20, 0, 25)
toggleAimlock.Position = UDim2.new(0, 10, 0, 70)
toggleAimlock.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
toggleAimlock.TextColor3 = Color3.new(1,1,1)
toggleAimlock.Text = "Enable Aimlock"
toggleAimlock.Font = Enum.Font.SourceSans
toggleAimlock.TextSize = 16

-- Drawing FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = ESP_Color
FOVCircle.Thickness = 2
FOVCircle.Filled = false
FOVCircle.NumSides = 100
FOVCircle.Radius = AimFOV * 4 -- scale radius visually
FOVCircle.Visible = false

-- Input tracking
UIS.InputBegan:Connect(function(input, gp)
    if not gp and input.UserInputType == Enum.UserInputType.MouseButton1 then
        HoldingShoot = true
    end
end)
UIS.InputEnded:Connect(function(input, gp)
    if not gp and input.UserInputType == Enum.UserInputType.MouseButton1 then
        HoldingShoot = false
    end
end)

-- ESP Functions
local function createESP(plr)
    if plr == LocalPlayer then return end
    local char = plr.Character
    if char and not char:FindFirstChild("BuzzESP") then
        local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
        if rootPart then
            local billboard = Instance.new("BillboardGui", char)
            billboard.Name = "BuzzESP"
            billboard.Adornee = rootPart
            billboard.Size = UDim2.new(0, 100, 0, 40)
            billboard.AlwaysOnTop = true
            billboard.ResetOnSpawn = false

            local bg = Instance.new("Frame", billboard)
            bg.Size = UDim2.new(1, 0, 1, 0)
            bg.BackgroundTransparency = 0.5
            bg.BackgroundColor3 = Color3.new(0, 0, 0)
            bg.BorderSizePixel = 0
            bg.ZIndex = 0

            local nameLabel = Instance.new("TextLabel", billboard)
            nameLabel.Size = UDim2.new(1, 0, 0, 20)
            nameLabel.Position = UDim2.new(0, 0, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.TextColor3 = ESP_Color
            nameLabel.TextStrokeTransparency = 0
            nameLabel.Text = plr.Name
            nameLabel.Font = Enum.Font.SourceSansBold
            nameLabel.TextScaled = true
            nameLabel.ZIndex = 1
        end
    end
end

local function removeESP(plr)
    local char = plr.Character
    if char and char:FindFirstChild("BuzzESP") then
        char.BuzzESP:Destroy()
    end
end

-- ESP Toggle
toggleESP.MouseButton1Click:Connect(function()
    ESP_Enabled = not ESP_Enabled
    toggleESP.Text = ESP_Enabled and "Disable ESP" or "Enable ESP"
    if not ESP_Enabled then
        for _,v in pairs(Players:GetPlayers()) do
            removeESP(v)
        end
    else
        for _,v in pairs(Players:GetPlayers()) do
            if v.Character then
                createESP(v)
            end
        end
    end
end)

-- Aimlock Toggle
toggleAimlock.MouseButton1Click:Connect(function()
    Aimlock_Enabled = not Aimlock_Enabled
    toggleAimlock.Text = Aimlock_Enabled and "Disable Aimlock" or "Enable Aimlock"
    FOVCircle.Visible = Aimlock_Enabled
end)

-- Aimlock Functions
local function getClosestToMouse()
    local closest, dist = nil, AimFOV
    local mousePos = UIS:GetMouseLocation()

    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local pos, onscreen = Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
            if onscreen then
                local magnitude = (Vector2.new(pos.X,pos.Y) - Vector2.new(mousePos.X,mousePos.Y)).Magnitude
                if magnitude < dist then
                    dist = magnitude
                    closest = plr.Character.HumanoidRootPart.Position
                end
            end
        end
    end

    return closest
end

-- Run Loops
RunService.RenderStepped:Connect(function()
    -- Update FOV circle position around mouse
    if Aimlock_Enabled then
        local mousePos = UIS:GetMouseLocation()
        FOVCircle.Position = Vector2.new(mousePos.X, mousePos.Y + 36) -- offset for taskbar height
        FOVCircle.Radius = AimFOV * 4 -- You can tweak this scale
    end

    if ESP_Enabled then
        for _,plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    createESP(plr)
                else
                    removeESP(plr)
                end
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if Aimlock_Enabled and HoldingShoot then
        local target = getClosestToMouse()
        if target then
            local mousePos = UIS:GetMouseLocation()
            local screenPos = Camera:WorldToViewportPoint(target)
            local aimPos = Vector2.new(screenPos.X, screenPos.Y)

            -- Move mouse toward aimPos (relative movement)
            mousemoverel((aimPos.X - mousePos.X) * AimSpeed, (aimPos.Y - mousePos.Y) * AimSpeed)
        end
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    removeESP(plr)
end)
