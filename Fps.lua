setfpscap(12)
if getgenv().__KAMI_BLACKSCREEN_RUNNING then return end
getgenv().__KAMI_BLACKSCREEN_RUNNING = true

repeat task.wait() until game:IsLoaded()
repeat task.wait() until game:GetService("Players").LocalPlayer

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

getgenv().BlackScreenConfig = {
    enableBlackOverlay = false,
    overlayZIndex = 100000,
    overlayTransparency = 0,
    reduceGraphics = true,
    minimalQualityLevel = 1,
    toggleOverlayKey = Enum.KeyCode.F5,
    toggleBoosterKey = Enum.KeyCode.F6
}

local overlayGui
local overlayFrame
local fpsLabel
local overlayEnabled = getgenv().BlackScreenConfig.enabled

local function applySafeOptimizations(enable)
    pcall(function()
        if enable and settings and settings().Rendering then
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            settings().Rendering.TextureQuality = Enum.TextureQuality.Level1
        end
    end)

    local Lighting = game:GetService("Lighting")
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e6
        Lighting.Brightness = 1
        Lighting.Ambient = Color3.fromRGB(50,50,50)
        Lighting.OutdoorAmbient = Color3.fromRGB(50,50,50)
        for _, eff in pairs(Lighting:GetChildren()) do
            pcall(function()
                if typeof(eff.Enabled) == "boolean" then
                    eff.Enabled = not enable and eff.Enabled or false
                elseif eff:IsA("Atmosphere") then
                    eff.Density = enable and 0 or eff.Density
                end
            end)
        end
    end)

    for _, obj in ipairs(workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("BasePart") then
                if typeof(obj.LocalTransparencyModifier) == "number" then
                    obj.LocalTransparencyModifier = enable and 1 or 0
                else
                    obj.Transparency = enable and 1 or 0
                end
                obj.CastShadow = not enable and obj.CastShadow or false
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Fire") or obj:IsA("Smoke") then
                obj.Enabled = not enable and obj.Enabled or false
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = enable and 1 or 0
            end
        end)
    end

    if LocalPlayer:FindFirstChild("PlayerGui") then
        for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
            pcall(function()
                if gui:IsA("ScreenGui") then
                    gui.Enabled = not enable and gui.Enabled or false
                else
                    if typeof(gui.Visible) == "boolean" then
                        gui.Visible = not enable and gui.Visible or false
                    end
                end
            end)
        end
    end
end

workspace.DescendantAdded:Connect(function(obj)
    pcall(function()
        if obj:IsA("BasePart") then
            if typeof(obj.LocalTransparencyModifier) == "number" then
                obj.LocalTransparencyModifier = 1
            else
                obj.Transparency = 1
            end
            obj.CastShadow = false
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Fire") or obj:IsA("Smoke") then
            obj.Enabled = false
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = 1
        end
    end)
end)

local function createOverlay()

    overlayGui = Instance.new("ScreenGui")
    overlayGui.Name = "KAMI•APA"
    overlayGui.IgnoreGuiInset = true
    overlayGui.ResetOnSpawn = false
    overlayGui.DisplayOrder = 999999
    overlayGui.Parent = game:GetService("CoreGui")

    overlayFrame = Instance.new("Frame")
    overlayFrame.Size = UDim2.new(1,0,1,0)
    overlayFrame.BackgroundColor3 = Color3.new(0,0,0)
    overlayFrame.BackgroundTransparency = 0
    overlayFrame.BorderSizePixel = 0
    overlayFrame.Active = false -- PENTING (tidak tangkap input)
    overlayFrame.Selectable = false
    overlayFrame.Parent = overlayGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0,400,0,50)
    title.Position = UDim2.new(0.5,-200,0.5,-40)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(0,255,255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 28
    title.Text = "👁️ KAMI•APA 👁️"
    title.Parent = overlayGui


    local userLabel = Instance.new("TextLabel")
    userLabel.Size = UDim2.new(0,300,0,30)
    userLabel.Position = UDim2.new(0.5,-150,0,10)
    userLabel.BackgroundTransparency = 1
    userLabel.TextColor3 = Color3.new(1,1,1)
    userLabel.Font = Enum.Font.GothamBold
    userLabel.TextSize = 22
    userLabel.Text = LocalPlayer.Name
    userLabel.Parent = overlayGui


    fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.new(0,300,0,30)
    fpsLabel.Position = UDim2.new(0.5,-150,1,-40)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.TextColor3 = Color3.new(1,1,1)
    fpsLabel.Font = Enum.Font.GothamBold
    fpsLabel.TextSize = 22
    fpsLabel.Text = "FPS: 0"
    fpsLabel.Parent = overlayGui


    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0,200,0,40)
    button.Position = UDim2.new(0.5,-100,0.9,0)
    button.BackgroundColor3 = Color3.fromRGB(25,25,25)
    button.TextColor3 = Color3.new(1,1,1)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 18
    button.Text = overlayEnabled and "Black Screen: ON" or "Black Screen: OFF"
    button.Parent = overlayGui

    button.MouseButton1Click:Connect(function()
        overlayEnabled = not overlayEnabled
        overlayFrame.Visible = overlayEnabled
        button.Text = overlayEnabled and "Black Screen: ON" or "Black Screen: OFF"
    end)

    overlayFrame.Visible = overlayEnabled
end


local frameCount = 0
local lastUpdate = tick()

RunService.RenderStepped:Connect(function()
    frameCount += 1
    local now = tick()
    if now - lastUpdate >= 1 then
        local fps = math.floor(frameCount / (now - lastUpdate))
        if fpsLabel then
            fpsLabel.Text = "FPS: " .. fps
        end
        frameCount = 0
        lastUpdate = now
    end
end)


UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == getgenv().BlackScreenConfig.toggleKey then
        overlayEnabled = not overlayEnabled
        if overlayFrame then
            overlayFrame.Visible = overlayEnabled
        end
    end
end)

-- START
createOverlay()


