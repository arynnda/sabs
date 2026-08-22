if getgenv().__KAMI_BLACKSCREEN_RUNNING then return end
getgenv().__KAMI_BLACKSCREEN_RUNNING = true

repeat task.wait() until game:IsLoaded()
repeat task.wait() until game:GetService("Players").LocalPlayer

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().BlackScreenConfig = {
    enableBlackOverlay = false,
    reduceGraphics = true,
    minimalQualityLevel = 1,
    overlayTransparency = 0,
    overlayZIndex = 100000,
    showFPS = true,
    disableParticles = true,
    disableTextures = true,
    disableShadows = true,
    disableLightingEffects = true
}

local overlayGui, overlayFrame, fpsLabel, statusLabel
local overlayEnabled = getgenv().BlackScreenConfig.enableBlackOverlay
local optimizationEnabled = getgenv().BlackScreenConfig.reduceGraphics

local function optimizeGraphicsQuality()
    if not optimizationEnabled then return end
    pcall(function()
        local renderSettings = settings().Rendering
        renderSettings.QualityLevel = Enum.QualityLevel.Level01
        renderSettings.TextureQuality = Enum.TextureQuality.Level1
    end)
end

local function optimizeLighting()
    if not optimizationEnabled then return end

    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1000000
        Lighting.Brightness = 1
        Lighting.Ambient = Color3.fromRGB(50, 50, 50)
        Lighting.OutdoorAmbient = Color3.fromRGB(50, 50, 50)
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
    end)

    if getgenv().BlackScreenConfig.disableLightingEffects then
        for _, effect in ipairs(Lighting:GetChildren()) do
            pcall(function()
                if effect:IsA("BloomEffect")
                    or effect:IsA("BlurEffect")
                    or effect:IsA("ColorCorrectionEffect")
                    or effect:IsA("DepthOfFieldEffect")
                    or effect:IsA("SunRaysEffect") then
                    effect.Enabled = false
                elseif effect:IsA("Atmosphere") then
                    effect.Density = 0
                    effect.Haze = 0
                    effect.Glare = 0
                end
            end)
        end
    end
end

local function optimizeObject(obj)
    if not optimizationEnabled then return end

    pcall(function()
        if obj:IsA("BasePart") then
            obj.LocalTransparencyModifier = 1
            if getgenv().BlackScreenConfig.disableShadows then
                obj.CastShadow = false
            end
        end

        if getgenv().BlackScreenConfig.disableParticles then
            if obj:IsA("ParticleEmitter")
                or obj:IsA("Trail")
                or obj:IsA("Beam")
                or obj:IsA("Fire")
                or obj:IsA("Smoke")
                or obj:IsA("Sparkles") then
                obj.Enabled = false
            end
        end

        if getgenv().BlackScreenConfig.disableTextures then
            if obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = 1
            end
        end
    end)
end

local function optimizeWorkspace()
    if not optimizationEnabled then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        optimizeObject(obj)
    end
end

workspace.DescendantAdded:Connect(function(obj)
    if not optimizationEnabled then return end
    task.defer(function()
        optimizeObject(obj)
    end)
end)

local function optimizePlayerGui()
    pcall(function()
        local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not PlayerGui then return end

        for _, gui in ipairs(PlayerGui:GetChildren()) do
            pcall(function()
                if gui:IsA("ScreenGui") and gui.Name ~= "KAMI•APA" then
                    gui.Enabled = false
                end
            end)
        end
    end)
end

local function applyOptimization()
    if not optimizationEnabled then return end
    optimizeGraphicsQuality()
    optimizeLighting()
    optimizeWorkspace()
    optimizePlayerGui()
end

local function createOverlay()
    pcall(function()
        local old = CoreGui:FindFirstChild("KAMI•APA")
        if old then old:Destroy() end
    end)

    overlayGui = Instance.new("ScreenGui")
    overlayGui.Name = "KAMI•APA"
    overlayGui.IgnoreGuiInset = true
    overlayGui.ResetOnSpawn = false
    overlayGui.DisplayOrder = getgenv().BlackScreenConfig.overlayZIndex
    overlayGui.Parent = CoreGui

    overlayFrame = Instance.new("Frame")
    overlayFrame.Name = "BlackScreen"
    overlayFrame.Size = UDim2.new(1, 0, 1, 0)
    overlayFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    overlayFrame.BackgroundTransparency = getgenv().BlackScreenConfig.overlayTransparency
    overlayFrame.BorderSizePixel = 0
    overlayFrame.Active = false
    overlayFrame.Selectable = false
    overlayFrame.ZIndex = 1
    overlayFrame.Parent = overlayGui

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0, 400, 0, 50)
    title.Position = UDim2.new(0.5, -200, 0.5, -50)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(0, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 28
    title.Text = "👁️ KAMI•APA 👁️"
    title.ZIndex = 5
    title.Parent = overlayGui

    local userLabel = Instance.new("TextLabel")
    userLabel.Name = "Username"
    userLabel.Size = UDim2.new(0, 400, 0, 30)
    userLabel.Position = UDim2.new(0.5, -200, 0, 10)
    userLabel.BackgroundTransparency = 1
    userLabel.TextColor3 = Color3.new(1, 1, 1)
    userLabel.Font = Enum.Font.GothamBold
    userLabel.TextSize = 22
    userLabel.Text = LocalPlayer.Name
    userLabel.ZIndex = 5
    userLabel.Parent = overlayGui

    fpsLabel = Instance.new("TextLabel")
    fpsLabel.Name = "FPS"
    fpsLabel.Size = UDim2.new(0, 300, 0, 30)
    fpsLabel.Position = UDim2.new(0.5, -150, 1, -45)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.TextColor3 = Color3.new(1, 1, 1)
    fpsLabel.Font = Enum.Font.GothamBold
    fpsLabel.TextSize = 22
    fpsLabel.Text = "FPS: 0"
    fpsLabel.ZIndex = 5
    fpsLabel.Visible = getgenv().BlackScreenConfig.showFPS
    fpsLabel.Parent = overlayGui

    statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.new(0, 400, 0, 25)
    statusLabel.Position = UDim2.new(0.5, -200, 0.5, 5)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 15
    statusLabel.Text = optimizationEnabled and "FPS Optimizer: ON" or "FPS Optimizer: OFF"
    statusLabel.ZIndex = 5
    statusLabel.Parent = overlayGui

    local button = Instance.new("TextButton")
    button.Name = "ToggleButton"
    button.Size = UDim2.new(0, 220, 0, 40)
    button.Position = UDim2.new(0.5, -110, 0.9, 0)
    button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    button.BorderSizePixel = 0
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 18
    button.Text = overlayEnabled and "Black Screen: ON" or "Black Screen: OFF"
    button.ZIndex = 10
    button.Parent = overlayGui

    button.MouseButton1Click:Connect(function()
        overlayEnabled = not overlayEnabled
        overlayFrame.Visible = overlayEnabled
        button.Text = overlayEnabled and "Black Screen: ON" or "Black Screen: OFF"
    end)

    overlayFrame.Visible = overlayEnabled
end

local frameCount, lastUpdate = 0, tick()

RunService.RenderStepped:Connect(function()
    frameCount += 1
    local now = tick()

    if now - lastUpdate >= 1 then
        local fps = math.floor(frameCount / (now - lastUpdate))
        if fpsLabel then fpsLabel.Text = "FPS: " .. fps end
        frameCount, lastUpdate = 0, now
    end
end)

applyOptimization()
createOverlay()
