pcall(function()
    if setfpscap then
        setfpscap(15)
    end
end)

if getgenv().__KAMI_BLACKSCREEN_RUNNING then return end
getgenv().__KAMI_BLACKSCREEN_RUNNING = true
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game:GetService("Players").LocalPlayer

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

getgenv().BlackScreenConfig = {
    enableBlackOverlay = true,
    toggleOverlayKey = Enum.KeyCode.F5
}

local overlayEnabled = getgenv().BlackScreenConfig.enableBlackOverlay or false

local overlayGui
local overlayFrame
local button
local fpsLabel

local function syncOverlay()
    -- update state global
    getgenv().BlackScreenConfig.enableBlackOverlay = overlayEnabled

    if overlayFrame then
        overlayFrame.Visible = overlayEnabled
    end

    if button then
        button.Text = overlayEnabled and "Black Screen: ON" or "Black Screen: OFF"
    end
end

local function toggleOverlay()
    overlayEnabled = not overlayEnabled
    syncOverlay()
end

local function applySafeOptimizations(enable)
    pcall(function()
        if enable and settings and settings().Rendering then
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end
    end)

    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e6
    end)
end

-- CREATE UI
local function createOverlay()
    if overlayGui then return end

    overlayGui = Instance.new("ScreenGui")
    overlayGui.Name = "KAMI•APA"
    overlayGui.IgnoreGuiInset = true
    overlayGui.ResetOnSpawn = false
    overlayGui.DisplayOrder = 999999
    overlayGui.Parent = game:GetService("CoreGui")

    overlayFrame = Instance.new("Frame")
    overlayFrame.Size = UDim2.new(1,0,1,0)
    overlayFrame.BackgroundColor3 = Color3.new(0,0,0)
    overlayFrame.BorderSizePixel = 0
    overlayFrame.Parent = overlayGui

    -- USERNAME
    local userLabel = Instance.new("TextLabel")
    userLabel.Size = UDim2.new(0,300,0,30)
    userLabel.Position = UDim2.new(0.5,-150,0,10)
    userLabel.BackgroundTransparency = 1
    userLabel.TextColor3 = Color3.new(1,1,1)
    userLabel.Font = Enum.Font.GothamBold
    userLabel.TextSize = 22
    userLabel.Text = LocalPlayer.Name
    userLabel.Parent = overlayGui

    -- FPS
    fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.new(0,300,0,30)
    fpsLabel.Position = UDim2.new(0.5,-150,1,-40)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.TextColor3 = Color3.new(1,1,1)
    fpsLabel.Font = Enum.Font.GothamBold
    fpsLabel.TextSize = 22
    fpsLabel.Text = "FPS: 0"
    fpsLabel.Parent = overlayGui

    -- BUTTON
    button = Instance.new("TextButton")
    button.Size = UDim2.new(0,200,0,40)
    button.Position = UDim2.new(0.5,-100,0.9,0)
    button.BackgroundColor3 = Color3.fromRGB(25,25,25)
    button.TextColor3 = Color3.new(1,1,1)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 18
    button.Parent = overlayGui

    button.MouseButton1Click:Connect(toggleOverlay)

    syncOverlay()
end

local frameCount = 0
local lastUpdate = tick()

RunService.RenderStepped:Connect(function()
    frameCount += 1
    local now = tick()

    if now - lastUpdate >= 1 then
        if fpsLabel then
            fpsLabel.Text = "FPS: " .. math.floor(frameCount / (now - lastUpdate))
        end
        frameCount = 0
        lastUpdate = now
    end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if input.KeyCode == getgenv().BlackScreenConfig.toggleOverlayKey then
        toggleOverlay()
    end
end)

applySafeOptimizations(true)
createOverlay()
