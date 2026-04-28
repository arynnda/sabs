local function setFPS(fps)
    pcall(function()
        if setfpscap then
            setfpscap(fps)
        end
    end)
end

setFPS(15)

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
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")


local overlayOn = false
local boosterOn = false
local lastInputTime = tick()

UIS.InputBegan:Connect(function()
    lastInputTime = tick()
end)

task.spawn(function()
    while true do
        task.wait(2)

        local idleTime = tick() - lastInputTime

        if boosterOn then
            if idleTime > 10 then

                setFPS(15)
            else

                setFPS(18)
            end
        else

            setFPS(20)
        end
    end
end)

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
            if typeof(eff.Enabled) == "boolean" then
                eff.Enabled = not enable and eff.Enabled or false
            elseif eff:IsA("Atmosphere") then
                eff.Density = enable and 0 or eff.Density
            end
        end
    end)

    for _, obj in ipairs(workspace:GetDescendants()) do
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
    end

    if LocalPlayer:FindFirstChild("PlayerGui") then
        for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                gui.Enabled = not enable and gui.Enabled or false
            elseif typeof(gui.Visible) == "boolean" then
                gui.Visible = not enable and gui.Visible or false
            end
        end
    end
end

workspace.DescendantAdded:Connect(function(obj)
    if not boosterOn then return end

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
    frame.BackgroundTransparency = 0
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.new(0,200,0,30)
    fpsLabel.Position = UDim2.new(0.5,-100,1,-40)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.TextColor3 = Color3.new(1,1,1)
    fpsLabel.Text = "FPS: 0"
    fpsLabel.Parent = gui

    local frameCount, lastUpdate = 0, tick()

    RunService.RenderStepped:Connect(function()
        frameCount += 1
        local now = tick()

        if now - lastUpdate >= 1 then
            fpsLabel.Text = "FPS: " .. math.floor(frameCount / (now - lastUpdate))
            frameCount = 0
            lastUpdate = now
        end
    end)
end

local function toggleOverlay()
    overlayOn = not overlayOn

    if overlayOn then
        createOverlay()
    else
        local gui = game:GetService("CoreGui"):FindFirstChild("KAMI•APABlackModeGUI")
        if gui then gui:Destroy() end
        getgenv()._CicaOverlayCreated = nil
    end
end

local function toggleBooster()
    boosterOn = not boosterOn
    applySafeOptimizations(boosterOn)

    if boosterOn then
        setFPS(15)
    else
        setFPS(20)
    end
end

applySafeOptimizations(true)
boosterOn = true

if getgenv().BlackModeConfig.enableBlackOverlay then
    toggleOverlay()
end

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if input.KeyCode == getgenv().BlackModeConfig.toggleOverlayKey then
        toggleOverlay()

    elseif input.KeyCode == getgenv().BlackModeConfig.toggleBoosterKey then
        toggleBooster()
    end
end)
