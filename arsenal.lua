-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Settings
local ESP_Color = Color3.fromRGB(255, 165, 0)
local ESP_Enabled = false
local Aimlock_Enabled = false

local Aimlock_FOV = 120 -- Aimlock detection circle radius in pixels
local Aimlock_Smoothness = 0.2 -- 0 = instant, closer to 1 = slower

local Min_Y = 10  -- Map floor height
local Max_Y = 500 -- Map ceiling height

local ESP_Objects = {}

-- FOV Circle (Visible when Aimlock enabled)
local FOV_Circle = Drawing.new("Circle")
FOV_Circle.Color = ESP_Color
FOV_Circle.Thickness = 2
FOV_Circle.Filled = false
FOV_Circle.Transparency = 1
FOV_Circle.Visible = false

-- GUI Setup
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "ArsenalGUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 200, 0, 110)
frame.Position = UDim2.new(0.05, 0, 0.05, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
title.TextColor3 = Color3.new(1,1,1)
title.Text = "Arsenal Script"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16

local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size = UDim2.new(0, 25, 0, 25)
closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 18

closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
    FOV_Circle.Visible = false
    ESP_Enabled = false
    Aimlock_Enabled = false
    for _, esp in pairs(ESP_Objects) do
        esp.Box.Visible = false
        esp.Name.Visible = false
    end
end)

local toggleESP = Instance.new("TextButton", frame)
toggleESP.Size = UDim2.new(1, -20, 0, 25)
toggleESP.Position = UDim2.new(0, 10, 0, 35)
toggleESP.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleESP.TextColor3 = Color3.new(1,1,1)
toggleESP.Text = "Enable ESP"
toggleESP.Font = Enum.Font.SourceSans
toggleESP.TextSize = 16

local toggleAimlock = Instance.new("TextButton", frame)
toggleAimlock.Size = UDim2.new(1, -20, 0, 25)
toggleAimlock.Position = UDim2.new(0, 10, 0, 70)
toggleAimlock.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleAimlock.TextColor3 = Color3.new(1,1,1)
toggleAimlock.Text = "Enable Aimlock"
toggleAimlock.Font = Enum.Font.SourceSans
toggleAimlock.TextSize = 16

toggleESP.MouseButton1Click:Connect(function()
    ESP_Enabled = not ESP_Enabled
    toggleESP.Text = ESP_Enabled and "Disable ESP" or "Enable ESP"
    if not ESP_Enabled then
        for _, esp in pairs(ESP_Objects) do
            esp.Box.Visible = false
            esp.Name.Visible = false
        end
    end
end)

toggleAimlock.MouseButton1Click:Connect(function()
    Aimlock_Enabled = not Aimlock_Enabled
    toggleAimlock.Text = Aimlock_Enabled and "Disable Aimlock" or "Enable Aimlock"
    FOV_Circle.Visible = Aimlock_Enabled
end)

-- Helper functions
local function isEnemy(player)
    local localTeam = LocalPlayer.Team
    if not localTeam or not player.Team then return true end
    return player.Team ~= localTeam
end

local function isValidTarget(player)
    if not player or not player.Character then return false end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    return hrp.Position.Y > Min_Y and hrp.Position.Y < Max_Y
end

local function createESP(player)
    if ESP_Objects[player] then return end
    local box = Drawing.new("Square")
    box.Color = ESP_Color
    box.Thickness = 2
    box.Filled = false
    box.Visible = false

    local name = Drawing.new("Text")
    name.Text = player.Name
    name.Color = ESP_Color
    name.Size = 16
    name.Center = true
    name.Outline = true
    name.Visible = false

    ESP_Objects[player] = {Box = box, Name = name}
end

local function removeESP(player)
    if ESP_Objects[player] then
        ESP_Objects[player].Box:Remove()
        ESP_Objects[player].Name:Remove()
        ESP_Objects[player] = nil
    end
end

-- ESP Update Loop
RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    FOV_Circle.Position = Vector2.new(mousePos.X, mousePos.Y)
    FOV_Circle.Radius = Aimlock_FOV

    if not ESP_Enabled then
        for _, esp in pairs(ESP_Objects) do
            esp.Box.Visible = false
            esp.Name.Visible = false
        end
        return
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isEnemy(player) and isValidTarget(player) and player.Character and player.Character:FindFirstChild("Head") then
            createESP(player)

            local esp = ESP_Objects[player]
            local rootPart = player.Character.HumanoidRootPart
            local head = player.Character.Head

            local rootPos, rootVis = Camera:WorldToViewportPoint(rootPart.Position)
            local headPos, headVis = Camera:WorldToViewportPoint(head.Position)

            if rootVis and headVis then
                local height = math.abs(headPos.Y - rootPos.Y)
                local width = height / 2

                esp.Box.Position = Vector2.new(rootPos.X - width/2, rootPos.Y - height/2)
                esp.Box.Size = Vector2.new(width, height)
                esp.Box.Visible = true

                esp.Name.Position = Vector2.new(rootPos.X, rootPos.Y - height/2 - 15)
                esp.Name.Visible = true
            else
                esp.Box.Visible = false
                esp.Name.Visible = false
            end
        else
            removeESP(player)
        end
    end
end)

-- Aimlock Hold Logic (no prediction)
local HoldingClick = false

UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.UserInputType == Enum.UserInputType.MouseButton1 then
        HoldingClick = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if not gp and input.UserInputType == Enum.UserInputType.MouseButton1 then
        HoldingClick = false
    end
end)

RunService.RenderStepped:Connect(function()
    if Aimlock_Enabled and HoldingClick then
        local closest = nil
        local shortestDist = Aimlock_FOV
        local mousePos = UserInputService:GetMouseLocation()

        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and isEnemy(player) and isValidTarget(player) and player.Character and player.Character:FindFirstChild("Head") then
                local head = player.Character.Head
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)

                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = player
                    end
                end
            end
        end

        if closest then
            local head = closest.Character.Head
            local camPos = Camera.CFrame.Position
            local direction = (head.Position - camPos).Unit
            local targetCFrame = CFrame.new(camPos, camPos + direction)

            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Aimlock_Smoothness)
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)
