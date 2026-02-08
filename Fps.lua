setfpscap(15)
task.spawn(function()
    repeat task.wait() until game:IsLoaded()
    repeat task.wait() until game:GetService("Players").LocalPlayer
end)

getgenv().BlackModeConfig = {
    enableBlackOverlay = true,
    overlayZIndex = 100000,
    overlayTransparency = 0,
    reduceGraphics = true,
    minimalQualityLevel = 1,
    toggleOverlayKey = Enum.KeyCode.F5,
    toggleBoosterKey = Enum.KeyCode.F6
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

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
    if getgenv()._CicaOverlayCreated then return end
    getgenv()._CicaOverlayCreated = true

    local gui = Instance.new("ScreenGui")
    gui.Name = "KAMI•APABlackModeGUI"
    gui.DisplayOrder = 999999
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Parent = game:GetService("CoreGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundColor3 = Color3.new(0,0,0)
    frame.BackgroundTransparency = getgenv().BlackModeConfig.overlayTransparency or 0
    frame.BorderSizePixel = 0
    frame.ZIndex = getgenv().BlackModeConfig.overlayZIndex or 100000
    frame.Parent = gui

    local usernameLabel = Instance.new("TextLabel")
    usernameLabel.Size = UDim2.new(0,300,0,35)
    usernameLabel.Position = UDim2.new(0.5,-150,0,10)
    usernameLabel.BackgroundTransparency = 1
    usernameLabel.TextColor3 = Color3.new(1,1,1)
    usernameLabel.Font = Enum.Font.SourceSansBold
    usernameLabel.TextSize = 26
    usernameLabel.Text = LocalPlayer.Name
    usernameLabel.ZIndex = frame.ZIndex + 1
    usernameLabel.Parent = gui

    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.new(0,300,0,35)
    fpsLabel.Position = UDim2.new(0.5,-150,1,-50)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.TextColor3 = Color3.new(1,1,1)
    fpsLabel.Font = Enum.Font.SourceSansBold
    fpsLabel.TextSize = 26
    fpsLabel.Text = "FPS: 0"
    fpsLabel.ZIndex = frame.ZIndex + 1
    fpsLabel.Parent = gui

    local mainLabel = Instance.new("TextLabel")
    mainLabel.Size = UDim2.new(0,400,0,60)
    mainLabel.Position = UDim2.new(0.5,-200,0.5,-60)
    mainLabel.BackgroundTransparency = 1
    mainLabel.TextColor3 = Color3.fromRGB(0,255,255)
    mainLabel.Font = Enum.Font.SourceSansBold
    mainLabel.TextSize = 30
    mainLabel.Text = "👁️ KAMI•APA 👁️"
    mainLabel.ZIndex = frame.ZIndex + 1
    mainLabel.Parent = gui


    local promoLabel = Instance.new("TextLabel")
    promoLabel.Size = UDim2.new(0,400,0,30)
    promoLabel.Position = UDim2.new(0.5,-200,0.5,-25)
    promoLabel.BackgroundTransparency = 1
    promoLabel.TextColor3 = Color3.fromRGB(255,255,255)
    promoLabel.Font = Enum.Font.SourceSansItalic
    promoLabel.TextSize = 18
    promoLabel.Text = "Buy Item Roblox In Here"
    promoLabel.ZIndex = frame.ZIndex + 1
    promoLabel.Parent = gui

    local discordLabel = Instance.new("TextLabel")
    discordLabel.Size = UDim2.new(0,400,0,30)
    discordLabel.Position = UDim2.new(0.5,-200,0.5,5)
    discordLabel.BackgroundTransparency = 1
    discordLabel.TextColor3 = Color3.fromRGB(180,180,180)
    discordLabel.Font = Enum.Font.SourceSans
    discordLabel.TextSize = 20
    discordLabel.Text = "discord.gg/kamiapa"
    discordLabel.ZIndex = frame.ZIndex + 1
    discordLabel.Parent = gui

    local controlGui = Instance.new("ScreenGui")
    controlGui.Name = "KAMI•APAToggleGUI"
    controlGui.DisplayOrder = 1000000
    controlGui.IgnoreGuiInset = true
    controlGui.ResetOnSpawn = false
    controlGui.Parent = game:GetService("CoreGui")

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 200, 0, 40)
    button.Position = UDim2.new(0.5, -100, 0.9, 0)
    button.Text = "🔘 Black Screen: ON"
    button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 20
    button.ZIndex = controlGui.DisplayOrder + 1
    button.Parent = controlGui

    button.MouseButton1Click:Connect(function()
        getgenv().BlackModeConfig.enableBlackOverlay = not getgenv().BlackModeConfig.enableBlackOverlay
        frame.Visible = getgenv().BlackModeConfig.enableBlackOverlay
        button.Text = getgenv().BlackModeConfig.enableBlackOverlay and "🔘 Black Screen: ON" or "⚪ Black Screen: OFF"
    end)

    local RunService = game:GetService("RunService")
    local frameCount, lastUpdate = 0, tick()
    RunService.RenderStepped:Connect(function()
        frameCount += 1
        local now = tick()
        if now - lastUpdate >= 1 then
            local fps = math.floor(frameCount / (now - lastUpdate))
            fpsLabel.Text = "FPS: " .. fps
            frameCount = 0
            lastUpdate = now
        end
    end)
end

local overlayOn = false
local boosterOn = false

local function toggleOverlay()
    overlayOn = not overlayOn
    if overlayOn then
        createOverlay()
    else
        local mainGui = game:GetService("CoreGui"):FindFirstChild("KAMI•APABlackModeGUI")
        if mainGui then mainGui:Destroy() end
        getgenv()._CicaOverlayCreated = nil
    end
end

local function toggleBooster()
    boosterOn = not boosterOn
    applySafeOptimizations(boosterOn)
end

applySafeOptimizations(true)
boosterOn = true
if getgenv().BlackModeConfig.enableBlackOverlay then
    toggleOverlay()
end

game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == getgenv().BlackModeConfig.toggleOverlayKey then
        toggleOverlay()
    elseif input.KeyCode == getgenv().BlackModeConfig.toggleBoosterKey then
        toggleBooster()
    end
end)
