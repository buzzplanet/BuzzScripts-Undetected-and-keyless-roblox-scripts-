local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GrowAGardenFakeGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

-- Main Window
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 400, 0, 380)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -190)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundTransparency = 0.2
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Draggable = true

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextScaled = true
Title.Text = "Grow a Garden | BuzzPlanet GUI"
Title.Parent = MainFrame

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 40, 0, 40)
CloseBtn.Position = UDim2.new(1, -45, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextScaled = true
CloseBtn.Text = "X"
CloseBtn.Parent = MainFrame

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Helper to create buttons
local function CreateButton(name, posY)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.8, 0, 0, 40)
    btn.Position = UDim2.new(0.1, 0, 0, posY)
    btn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextScaled = true
    btn.Text = name
    btn.Parent = MainFrame
    return btn
end

-- Buttons
local candySpawnerBtn = CreateButton("Candy Blossom Spawner", 60)
local dragonflySpawnerBtn = CreateButton("Dragonfly Spawner", 110)
local raccoonSpawnerBtn = CreateButton("Raccoon Spawner", 160)
local redFoxSpawnerBtn = CreateButton("Red Fox Spawner", 210)
local discoBeeSpawnerBtn = CreateButton("Disco Bee Spawner", 260)
local petDuperBtn = CreateButton("Pet Duper", 310)

-- Progress UI
local ProgressFrame = Instance.new("Frame")
ProgressFrame.Size = UDim2.new(0.9, 0, 0, 40)
ProgressFrame.Position = UDim2.new(0.05, 0, 1, -60)
ProgressFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
ProgressFrame.BorderSizePixel = 0
ProgressFrame.Parent = MainFrame
ProgressFrame.Visible = false

local ProgressBar = Instance.new("Frame")
ProgressBar.Size = UDim2.new(0,0,1,0)
ProgressBar.BackgroundColor3 = Color3.fromRGB(255,140,0)
ProgressBar.BorderSizePixel = 0
ProgressBar.Parent = ProgressFrame

local ProgressLabel = Instance.new("TextLabel")
ProgressLabel.Size = UDim2.new(1,0,1,0)
ProgressLabel.BackgroundTransparency = 1
ProgressLabel.TextColor3 = Color3.new(1,1,1)
ProgressLabel.Font = Enum.Font.GothamBold
ProgressLabel.TextScaled = true
ProgressLabel.Text = ""
ProgressLabel.Parent = ProgressFrame

-- Relaxing loop sound
local Sound = Instance.new("Sound", MainFrame)
Sound.SoundId = "rbxassetid://9118820573"
Sound.Looped = true
Sound.Volume = 0.15
Sound:Play()

-- Fake load function with callback
local function FakeLoad(actionName, callback)
    local duration = math.random(4,7)
    ProgressFrame.Visible = true
    ProgressBar.Size = UDim2.new(0,0,1,0)
    ProgressLabel.Text = actionName .. " - 0%"
    local startTime = tick()
    local conn
    conn = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        local progress = math.clamp(elapsed/duration, 0, 1)
        ProgressBar.Size = UDim2.new(progress, 0, 1, 0)
        ProgressLabel.Text = actionName .. " - " .. math.floor(progress*100) .. "%"
        if progress >= 1 then
            conn:Disconnect()
            ProgressLabel.Text = actionName .. " - Success!"
            if callback then
                callback()
            end
            wait(2)
            ProgressFrame.Visible = false
        end
    end)
end

-- Helper to rename pet with randomized stats
local function RenameWithStats(tool, petName)
    local weight = math.random(100,1000)/100 -- 1.00 to 10.00
    local age = math.random(1,80) -- 1 to 80 years
    local newName = string.format('%s [%.2f KG] [(Age) %d]', petName, weight, age)
    tool.Name = newName
    local handle = tool:FindFirstChild("Handle")
    if handle then
        handle.Name = newName
    end
end

-- Helper to create dummy tool if no tool held
local function CreateDummyTool(petName)
    local tool = Instance.new("Tool")
    tool.Name = petName
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1,1,1)
    handle.Parent = tool
    tool.RequiresHandle = true
    return tool
end

-- Spawn pet by cloning current tool or dummy, renaming it, and parenting to backpack
local function SpawnPet(petName)
    local tool = nil
    local charTool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if charTool then
        tool = charTool:Clone()
    else
        tool = CreateDummyTool(petName)
    end
    -- Candy Blossom exception: no stats added
    if petName == "Candy Blossom" then
        tool.Name = "Candy Blossom"
        local handle = tool:FindFirstChild("Handle")
        if handle then
            handle.Name = "Candy Blossom"
        end
    else
        RenameWithStats(tool, petName)
    end
    tool.Parent = LocalPlayer.Backpack
end

-- Button handlers
candySpawnerBtn.MouseButton1Click:Connect(function()
    FakeLoad("Spawning Candy Blossoms", function()
        SpawnPet("Candy Blossom")
    end)
end)

dragonflySpawnerBtn.MouseButton1Click:Connect(function()
    FakeLoad("Spawning Dragonflies", function()
        SpawnPet("Dragonfly")
    end)
end)

raccoonSpawnerBtn.MouseButton1Click:Connect(function()
    FakeLoad("Spawning Raccoons", function()
        SpawnPet("Raccoon")
    end)
end)

redFoxSpawnerBtn.MouseButton1Click:Connect(function()
    FakeLoad("Spawning Red Foxes", function()
        SpawnPet("Red Fox")
    end)
end)

discoBeeSpawnerBtn.MouseButton1Click:Connect(function()
    FakeLoad("Spawning Disco Bees", function()
        SpawnPet("Disco Bee")
    end)
end)

petDuperBtn.MouseButton1Click:Connect(function()
    FakeLoad("Duplicating Pets", function()
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then
            local clonedTool = tool:Clone()
            clonedTool.Parent = LocalPlayer.Backpack
        else
            warn("No tool equipped to duplicate!")
        end
    end)
end)
