-- BuzzScript Arsenal V3 | With Ghost Mode & Triggerbot and FOV-scaled Aimlock Strength

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Aimlock = false
local ESP = false
local GhostMode = false
local FOV = 100 -- Starter FOV for normal mode
local Holding = false
local LockedTarget = nil

-- Smoothness scaling by FOV
local baseSmoothness = 0.03  -- slowest smoothness at min FOV
local maxSmoothness = 0.15   -- fastest smoothness at max FOV (500)
local Smoothness = 0.08      -- initial value; will be overridden by updateSmoothness()

local function updateSmoothness()
    local ratio = math.clamp(FOV / 500, 0, 1)
    Smoothness = baseSmoothness + (maxSmoothness - baseSmoothness) * ratio
end
updateSmoothness()

---------------------------
-- FOV Circles Setup
---------------------------
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.Radius = FOV
fovCircle.Filled = false
fovCircle.Transparency = 1
fovCircle.Visible = false
fovCircle.Color = Color3.fromRGB(255, 85, 0) -- orange normal

local ghostFOVCircle = Drawing.new("Circle")
ghostFOVCircle.Thickness = 0
ghostFOVCircle.Radius = 500 -- max FOV
ghostFOVCircle.Filled = false
ghostFOVCircle.Transparency = 0 -- invisible
ghostFOVCircle.Visible = false

---------------------------
-- ESP Tables
---------------------------
local ESPBoxes, Tracers, Outlines = {}, {}, {}
local AllTracers = {}

---------------------------
-- GUI Setup
---------------------------
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "BuzzScriptArsenal"
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 320, 0, 300)
frame.Position = UDim2.new(0.7, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
title.Text = "BuzzScript Arsenal V3"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.BorderSizePixel = 0

local close = Instance.new("TextButton", frame)
close.Size = UDim2.new(0, 30, 0, 30)
close.Position = UDim2.new(1, -35, 0, 3)
close.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
close.Text = "X"
close.TextColor3 = Color3.new(1, 1, 1)
close.Font = Enum.Font.GothamBold
close.TextSize = 14
close.BorderSizePixel = 0
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)
close.MouseButton1Click:Connect(function() gui.Enabled = false end)

local function MakeButton(name, positionY, callback)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 280, 0, 40)
    btn.Position = UDim2.new(0, 20, 0, positionY)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.Text = name .. ": OFF"
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = name .. (state and ": ON" or ": OFF")
        callback(state)
    end)
    return btn
end

local aimlockBtn = MakeButton("Aimlock", 50, function(v)
    Aimlock = v
    if not GhostMode then
        fovCircle.Visible = v
    else
        fovCircle.Visible = false
    end
end)

local espBtn = MakeButton("ESP", 100, function(v)
    ESP = v
    for _, obj in pairs({ESPBoxes, Tracers, Outlines}) do
        for _, i in pairs(obj) do
            i.Visible = v
        end
    end
end)

local ghostBtn = MakeButton("Ghost Mode", 150, function(v)
    GhostMode = v
    if v then
        fovCircle.Visible = false
        ghostFOVCircle.Visible = true
        Aimlock = true
        aimlockBtn.Text = "Aimlock: ON"
        FOV = 500
        ghostFOVCircle.Radius = FOV
        updateSmoothness()
        Holding = false
    else
        ghostFOVCircle.Visible = false
        fovCircle.Visible = Aimlock
        FOV = 100
        fovCircle.Radius = FOV
        updateSmoothness()
        Holding = false
        LockedTarget = nil
    end
end)

-- FOV Label & Slider (disabled in ghost mode)
local FOVLabel = Instance.new("TextLabel", frame)
FOVLabel.Size = UDim2.new(0, 280, 0, 20)
FOVLabel.Position = UDim2.new(0, 20, 0, 210)
FOVLabel.BackgroundTransparency = 1
FOVLabel.Text = "FOV: " .. FOV
FOVLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FOVLabel.Font = Enum.Font.Gotham
FOVLabel.TextSize = 14

local FOVSlider = Instance.new("TextButton", frame)
FOVSlider.Size = UDim2.new(0, 280, 0, 20)
FOVSlider.Position = UDim2.new(0, 20, 0, 235)
FOVSlider.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
FOVSlider.Text = ""
Instance.new("UICorner", FOVSlider).CornerRadius = UDim.new(0, 8)

local fill = Instance.new("Frame", FOVSlider)
fill.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
fill.Size = UDim2.new(FOV/500, 0, 1, 0)
fill.BorderSizePixel = 0
Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 8)

local dragging = false
FOVSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
    end
end)
FOVSlider.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        if not GhostMode then
            local rel = math.clamp((input.Position.X - FOVSlider.AbsolutePosition.X) / FOVSlider.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            FOV = math.floor(rel * 500)
            FOVLabel.Text = "FOV: " .. FOV
            fovCircle.Radius = FOV
            updateSmoothness()
        end
    end
end)

---------------------------
-- Visibility Check
---------------------------
local function isVisible(part)
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit * (part.Position - origin).Magnitude
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, part.Parent}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.IgnoreWater = true
    local raycast = workspace:Raycast(origin, direction, raycastParams)
    return not raycast
end

---------------------------
-- Get Closest Player to Mouse within FOV
---------------------------
local function getClosest()
    local closest, shortest = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            if p.Team ~= LocalPlayer.Team then
                local head = p.Character.Head
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist
                    if GhostMode then
                        dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    else
                        dist = (Vector2.new(pos.X, pos.Y) - UIS:GetMouseLocation()).Magnitude
                    end

                    if dist < shortest and dist < FOV then
                        if isVisible(head) then
                            closest = p
                            shortest = dist
                        end
                    end
                end
            end
        end
    end
    return closest
end

---------------------------
-- Input Hold Detection
---------------------------
UIS.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Holding = true
        LockedTarget = getClosest()
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Holding = false
        LockedTarget = nil
    end
end)

---------------------------
-- Triggerbot Function
---------------------------
local mouse = LocalPlayer:GetMouse()
local function triggerbot()
    if GhostMode and Holding and LockedTarget and LockedTarget.Character and LockedTarget.Character:FindFirstChild("Head") then
        local head = LockedTarget.Character.Head
        if isVisible(head) then
            -- Fire event: simulate mouse click
            mouse1press()
            wait(0.02)
            mouse1release()
        end
    end
end

---------------------------
-- ESP Create & Remove
---------------------------
local function createESP(player)
    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Filled = false
    box.Transparency = 1
    box.Visible = ESP

    local outline = Drawing.new("Square")
    outline.Thickness = 4
    outline.Filled = false
    outline.Transparency = 0.5
    outline.Color = Color3.new(0, 0, 0)
    outline.Visible = ESP

    local tracer = Drawing.new("Line")
    tracer.Thickness = 1.5
    tracer.Transparency = 1
    tracer.Visible = ESP

    ESPBoxes[player] = box
    Tracers[player] = tracer
    Outlines[player] = outline

    table.insert(AllTracers, tracer)
end

local function removeESP(player)
    for _, t in pairs({ESPBoxes, Tracers, Outlines}) do
        if t[player] then
            t[player]:Remove()
        end
        t[player] = nil
    end
end

---------------------------
-- Cleanup Extra Tracers (every 5s)
---------------------------
spawn(function()
    while true do
        wait(5)
        local linkedTracers = {}
        for _, tracer in pairs(Tracers) do
            linkedTracers[tracer] = true
        end

        for i = #AllTracers, 1, -1 do
            local tracer = AllTracers[i]
            if not linkedTracers[tracer] then
                tracer:Remove()
                table.remove(AllTracers, i)
            end
        end
    end
end)

---------------------------
-- Main Loop
---------------------------
RunService.RenderStepped:Connect(function()
    local hue = tick() % 5 / 5
    local rainbow = Color3.fromHSV(hue, 1, 1)

    if not GhostMode then
        fovCircle.Color = rainbow
        fovCircle.Position = GhostMode and Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2) or UIS:GetMouseLocation()
        fovCircle.Radius = FOV
    else
        ghostFOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        ghostFOVCircle.Radius = 500
    end

    -- ESP Loop
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            if p.Team ~= LocalPlayer.Team then
                if not ESPBoxes[p] then createESP(p) end

                local char = p.Character
                local headPos, onScreen = Camera:WorldToViewportPoint(char.Head.Position)
                local root = char:FindFirstChild("HumanoidRootPart")

                if onScreen and root then
                    local scale = 3
                    local top = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, scale, 0))
                    local bottom = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, scale, 0))
                    local height = math.abs(top.Y - bottom.Y)
                    local width = height / 2
                    local boxPos = Vector2.new(headPos.X - width/2, headPos.Y - height/2)

                    ESPBoxes[p].Size = Vector2.new(width, height)
                    ESPBoxes[p].Position = boxPos
                    ESPBoxes[p].Color = rainbow
                    ESPBoxes[p].Visible = ESP

                    Outlines[p].Size = Vector2.new(width, height)
                    Outlines[p].Position = boxPos
                    Outlines[p].Visible = ESP

                    Tracers[p].From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                    Tracers[p].To = Vector2.new(headPos.X, headPos.Y)
                    Tracers[p].Color = rainbow
                    Tracers[p].Visible = ESP
                else
                    for _, t in pairs({ESPBoxes, Outlines, Tracers}) do
                        if t[p] then t[p].Visible = false end
                    end
                end
            else
                removeESP(p)
            end
        else
            removeESP(p)
        end
    end

    -- Aimlock Logic
    if Aimlock and Holding then
        if LockedTarget and LockedTarget.Character and LockedTarget.Character:FindFirstChild("Head") then
            local head = LockedTarget.Character.Head
            if not isVisible(head) then
                LockedTarget = getClosest()
            else
                local camPos = Camera.CFrame.Position
                local targetDir = (head.Position - camPos).Unit
                local targetCFrame = CFrame.new(camPos, camPos + targetDir)
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Smoothness)
            end
        else
            LockedTarget = getClosest()
        end
    end

    -- Triggerbot call (only in ghost mode)
    if GhostMode then
        triggerbot()
    end
end)
