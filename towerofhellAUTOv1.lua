--// Services
local TweenService = game:GetService("TweenService")
local Players       = game:GetService("Players")
local workspace     = game:GetService("Workspace")
local player        = Players.LocalPlayer

--// Finish Coordinates
local finishPos = Vector3.new(52.19, 778.00, 2.17)

--// Settings
local tweenSpeed    = 60    -- studs/sec
local startUpHeight = 200   -- initial safe altitude
local heightStep    = 50    -- how much to bump up each try
local maxChecks     = 10    -- max altitude adjustments

--// Detect kill parts by name or red color
local function isKillPart(part)
    if not part:IsA("BasePart") then return false end
    local n = part.Name:lower()
    if n:find("kill") or n:find("death") then return true end
    local c = part.Color
    return (math.abs(c.R-1) < 0.01 and math.abs(c.G) < 0.01 and math.abs(c.B) < 0.01)
end

--// Test a given altitude for both kill-part and wall collisions
local function altitudeIsSafe(startXZ, endXZ, alt)
    -- downward ray to check kill parts under your path midpoint
    local midXZ = (startXZ + endXZ) * 0.5
    local downOrigin = Vector3.new(midXZ.X, alt + 500, midXZ.Z)
    local downRes    = workspace:Raycast(downOrigin, Vector3.new(0, -1, 0)*1000)
    if downRes and isKillPart(downRes.Instance) then
        return false
    end

    -- horizontal ray to check walls between start and end at altitude
    local horizOrigin = Vector3.new(startXZ.X, alt, startXZ.Z)
    local dir = (Vector3.new(endXZ.X, alt, endXZ.Z) - horizOrigin)
    local horizRes = workspace:Raycast(horizOrigin, dir, RaycastParams.new())
    if horizRes then
        -- hit something: if that part is a kill part, we already checked above
        return false
    end

    return true
end

--// Find the lowest altitude that passes both tests
local function findSafeAltitude(startXZ, endXZ)
    local h = startUpHeight
    for i = 1, maxChecks do
        if altitudeIsSafe(startXZ, endXZ, h) then
            return h
        end
        h += heightStep
    end
    return startUpHeight + heightStep*maxChecks
end

--// Main tween routine: up → across → down
local function startTween()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart")

    local startPos = hrp.Position
    local startXZ  = Vector3.new(startPos.X, 0, startPos.Z)
    local endXZ    = Vector3.new(finishPos.X, 0, finishPos.Z)

    -- pick a safe altitude
    local safeY = findSafeAltitude(startXZ, endXZ)

    -- waypoints
    local waypoints = {
        Vector3.new(startPos.X, safeY, startPos.Z),      -- climb up
        Vector3.new(finishPos.X, safeY, finishPos.Z),    -- move across
        finishPos                                        -- descend
    }

    for _, point in ipairs(waypoints) do
        local dist = (hrp.Position - point).Magnitude
        local t    = math.clamp(dist / tweenSpeed, 1, 12)
        local info = TweenInfo.new(t, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(hrp, info, {CFrame = CFrame.new(point)})
        tween:Play()
        tween.Completed:Wait()
        if not hrp.Parent then return end  -- stop if you died
    end
end

--// GUI Setup
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "TOHTweenGui"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size            = UDim2.new(0, 220, 0, 100)
frame.Position        = UDim2.new(0.5, -110, 0.5, -50)
frame.BackgroundColor3= Color3.fromRGB(25, 25, 25)
frame.Active          = true
frame.Draggable       = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel", frame)
title.Size             = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
title.Text             = "Tower of Hell Tweener"
title.TextColor3       = Color3.new(1, 1, 1)
title.Font             = Enum.Font.GothamBold
title.TextSize         = 16

local tweenBtn = Instance.new("TextButton", frame)
tweenBtn.Size             = UDim2.new(0, 180, 0, 40)
tweenBtn.Position         = UDim2.new(0, 20, 0, 35)
tweenBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
tweenBtn.Text             = "Tween to Finish"
tweenBtn.TextColor3       = Color3.new(1, 1, 1)
tweenBtn.Font             = Enum.Font.Gotham
tweenBtn.TextSize         = 14
Instance.new("UICorner", tweenBtn).CornerRadius = UDim.new(0, 8)

local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size             = UDim2.new(0, 25, 0, 25)
closeBtn.Position         = UDim2.new(1, -30, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
closeBtn.Text             = "X"
closeBtn.TextColor3       = Color3.new(1, 1, 1)
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.TextSize         = 14
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

tweenBtn.MouseButton1Click:Connect(startTween)
closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)
