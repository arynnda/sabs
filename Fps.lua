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
frame.Position = UDim2.new(0, 0, 0, 0)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

frame.BackgroundTransparency = 0

frame.BorderSizePixel = 0
frame.Parent = gui
