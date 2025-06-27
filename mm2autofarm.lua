--// Services
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

--// Variables
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart", 10)
local alive = true
local active = false
local espEnabled = false

local coinEsp = {}

--// Settings
local nearbyDistance = 15 -- studs to consider coins "nearby"
local tweenSpeedMin = 10
local tweenSpeedMax = 15

--// Functions

-- Find all coins in workspace
local function findCoinsInWorkspace(parent)
    local coins = {}
    for _, obj in pairs(parent:GetChildren()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("coin") then
            table.insert(coins, obj)
        elseif obj:IsA("Folder") or obj:IsA("Model") then
            for _, subCoin in pairs(findCoinsInWorkspace(obj)) do
                table.insert(coins, subCoin)
            end
        end
    end
    return coins
end

-- Get random coin
local function getRandomCoin()
    local coins = findCoinsInWorkspace(workspace)
    if #coins == 0 then return nil end
    return coins[math.random(1, #coins)]
end

-- Get coins nearby a position
local function getNearbyCoins(originPos)
    local nearby = {}
    for _, coin in pairs(findCoinsInWorkspace(workspace)) do
        if (coin.Position - originPos).Magnitude <= nearbyDistance then
            table.insert(nearby, coin)
        end
    end
    return nearby
end

-- ESP
local function createEsp()
    for _, v in pairs(coinEsp) do
        v:Destroy()
    end
    table.clear(coinEsp)

    local coins = findCoinsInWorkspace(workspace)
    for _, coin in pairs(coins) do
        if coin:IsA("BasePart") and coin:IsDescendantOf(workspace) then
            local box = Instance.new("BoxHandleAdornment")
            box.Size = coin.Size + Vector3.new(0.2, 0.2, 0.2)
            box.Adornee = coin
            box.AlwaysOnTop = true
            box.ZIndex = 5
            box.Transparency = 0.4
            box.Color3 = Color3.fromRGB(255, 140, 0) -- Orange color
            box.Parent = coin
            table.insert(coinEsp, box)
        end
    end
end

local function removeEsp()
    for _, v in pairs(coinEsp) do
        v:Destroy()
    end
    table.clear(coinEsp)
end

-- Coin Farm Loop
local function collectCoins()
    while active do
        if not alive then
            wait(1)
            continue
        end

        if not hrp or not hrp.Parent then
            character = player.Character or player.CharacterAdded:Wait()
            hrp = character:WaitForChild("HumanoidRootPart", 10)
        end

        local mainCoin = getRandomCoin()
        if mainCoin then
            local coinQueue = getNearbyCoins(mainCoin.Position)
            table.insert(coinQueue, 1, mainCoin) -- Start with main coin

            for _, coin in ipairs(coinQueue) do
                if not coin or not coin.Parent then continue end

                local dist = (coin.Position - hrp.Position).Magnitude
                local speed = math.random(tweenSpeedMin, tweenSpeedMax)
                local time = math.clamp(dist / speed, 0.5, 3)

                local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Linear)
                local targetCFrame = coin.CFrame + Vector3.new(0, 3, 0)
                local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})

                local tweenCompleted = false
                tween.Completed:Connect(function()
                    tweenCompleted = true
                end)

                tween:Play()
                repeat wait() until tweenCompleted or not active or not alive

                if not active or not alive then break end
            end
        else
            wait(0.5)
        end

        if not active then break end
    end
end

-- Character Monitor
local function monitorCharacter()
    character = player.Character or player.CharacterAdded:Wait()
    hrp = character:WaitForChild("HumanoidRootPart", 10)
    local humanoid = character:WaitForChild("Humanoid", 10)

    if humanoid then
        alive = true
        humanoid.Died:Connect(function()
            alive = false
        end)
    end
end

player.CharacterAdded:Connect(function()
    monitorCharacter()
end)

monitorCharacter()

--// GUI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CoinFarmGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 120)
mainFrame.Position = UDim2.new(0, 20, 0, 100)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Dragging
local dragging, dragInput, dragStart, startPos

local function updatePosition(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                  startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updatePosition(input)
    end
end)

-- Buttons
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 180, 0, 40)
toggleButton.Position = UDim2.new(0, 20, 0, 10)
toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleButton.BorderSizePixel = 0
toggleButton.Text = "Start Coin Farm"
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 22
toggleButton.Parent = mainFrame

local espButton = Instance.new("TextButton")
espButton.Size = UDim2.new(0, 180, 0, 40)
espButton.Position = UDim2.new(0, 20, 0, 60)
espButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
espButton.BorderSizePixel = 0
espButton.Text = "ESP: Off"
espButton.TextColor3 = Color3.new(1, 1, 1)
espButton.Font = Enum.Font.SourceSansBold
espButton.TextSize = 22
espButton.Parent = mainFrame

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 20, 0, 20)
closeButton.Position = UDim2.new(1, -25, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 18
closeButton.Parent = mainFrame

-- Button Functions
closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    active = false
    removeEsp()
end)

toggleButton.MouseButton1Click:Connect(function()
    active = not active
    if active then
        toggleButton.Text = "Stop Coin Farm"
        spawn(collectCoins)
    else
        toggleButton.Text = "Start Coin Farm"
    end
end)

espButton.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    espButton.Text = "ESP: " .. (espEnabled and "On" or "Off")
    if espEnabled then
        createEsp()
    else
        removeEsp()
    end
end)

-- ESP Refresh
task.spawn(function()
    while true do
        if espEnabled then
            removeEsp()
            createEsp()
        end
        wait(1)
    end
end)
