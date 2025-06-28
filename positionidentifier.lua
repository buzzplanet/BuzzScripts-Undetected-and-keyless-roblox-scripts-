local Players = game:GetService("Players")
local player = Players.LocalPlayer
local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart") or player.CharacterAdded:Wait():WaitForChild("HumanoidRootPart")

--// GUI Setup
local gui = Instance.new("ScreenGui")
gui.Name = "PositionIdentifier"
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 150)
frame.Position = UDim2.new(0.7, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Parent = gui
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
title.Text = "Position Identifier"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = frame
title.BorderSizePixel = 0

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 25, 0, 25)
close.Position = UDim2.new(1, -30, 0, 5)
close.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
close.Text = "X"
close.TextColor3 = Color3.new(1, 1, 1)
close.Font = Enum.Font.GothamBold
close.TextSize = 14
close.Parent = frame
close.BorderSizePixel = 0
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)
close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 260, 0, 40)
button.Position = UDim2.new(0, 20, 0, 40)
button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
button.Text = "Get Current Position"
button.TextColor3 = Color3.new(1, 1, 1)
button.Font = Enum.Font.Gotham
button.TextSize = 14
button.Parent = frame
Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)

local textbox = Instance.new("TextBox")
textbox.Size = UDim2.new(0, 260, 0, 40)
textbox.Position = UDim2.new(0, 20, 0, 90)
textbox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
textbox.Text = "X: 0, Y: 0, Z: 0"
textbox.TextColor3 = Color3.new(1, 1, 1)
textbox.Font = Enum.Font.Gotham
textbox.TextSize = 14
textbox.ClearTextOnFocus = false
textbox.Parent = frame
Instance.new("UICorner", textbox).CornerRadius = UDim.new(0, 6)

--// Functionality
button.MouseButton1Click:Connect(function()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        textbox.Text = "Character not found."
        return
    end

    local pos = player.Character.HumanoidRootPart.Position
    local formatted = string.format("X: %.2f, Y: %.2f, Z: %.2f", pos.X, pos.Y, pos.Z)
    textbox.Text = formatted
end)
