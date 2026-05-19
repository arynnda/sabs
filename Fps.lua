local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer

pcall(function()
    CoreGui:FindFirstChild("BlackOverlay"):Destroy()
end)

local gui = Instance.new("ScreenGui")
gui.Name = "BlackOverlay"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(1, 0, 1, 0)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BorderSizePixel = 0
frame.Parent = gui

local text = Instance.new("TextLabel")
text.AnchorPoint = Vector2.new(0.5, 0.5)
text.Position = UDim2.new(0.5, 0, 0.5, 0)
text.Size = UDim2.new(0, 400, 0, 50)

text.BackgroundTransparency = 1

text.Text = player.Name

text.TextColor3 = Color3.fromRGB(255, 255, 255)
text.TextSize = 34
text.Font = Enum.Font.GothamBold

text.Parent = frame
