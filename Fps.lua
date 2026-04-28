local function setFPS(fps)
    pcall(function()
        if setfpscap then
            setfpscap(fps)
        end
    end)
end

if getgenv().__KAMI_BLACKSCREEN_RUNNING then return end
getgenv().__KAMI_BLACKSCREEN_RUNNING = true

repeat task.wait() until game:IsLoaded()
repeat task.wait() until game:GetService("Players").LocalPlayer

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer

getgenv().BlackScreenConfig = {
    enableBlackOverlay = true,
    toggleOverlayKey = Enum.KeyCode.F5,

    fpsOn = 15,
    fpsOff = 30
}

local overlayEnabled = getgenv().BlackScreenConfig.enableBlackOverlay or false

local gui, frame, button, fpsLabel

local function applySafeOptimizations(enable)
    pcall(function()
        if enable and settings and settings().Rendering then
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end
    end)

    pcall(function()
        Lighting.GlobalShadows = not enable
        Lighting.Brightness = enable and 0 or 1
    end)
end

local function ultraOptimize(enable)
    if enable then

        pcall(function()
            RunService:Set3dRenderingEnabled(false)
        end)

        pcall(function()
            for _,v in ipairs(workspace:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Trail") or 
                   v:IsA("Beam") or v:IsA("Fire") or 
                   v:IsA("Smoke") or v:IsA("Sparkles") then
                    v.Enabled = false
                end
            end
        end)

        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.Brightness = 0
            Lighting.FogEnd = 1e6
            Lighting.Ambient = Color3.new(0,0,0)
            Lighting.OutdoorAmbient = Color3.new(0,0,0)

            for _,e in ipairs(Lighting:GetChildren()) do
                if e:IsA("Atmosphere") or e:IsA("Sky") or 
                   e:IsA("BloomEffect") or e:IsA("BlurEffect") or
                   e:IsA("ColorCorrectionEffect") or e:IsA("SunRaysEffect") then
                    e:Destroy()
                end
            end
        end)

        pcall(function()
            for _,v in ipairs(workspace:GetDescendants()) do
                if v:IsA("Decal") or v:IsA("Texture") then
                    v:Destroy()
                end
            end
        end)

        pcall(function()
            for _,s in ipairs(game:GetDescendants()) do
                if s:IsA("Sound") then
                    s.Volume = 0
                    s:Stop()
                end
            end
            SoundService.Volume = 0
        end)

       
        setFPS(getgenv().BlackScreenConfig.fpsOn or 15)

    else
        
        pcall(function()
            RunService:Set3dRenderingEnabled(true)
        end)

        setFPS(getgenv().BlackScreenConfig.fpsOff or 60)

        pcall(function()
            Lighting.GlobalShadows = true
            Lighting.Brightness = 1
        end)

        pcall(function()
            SoundService.Volume = 1
        end)
    end
end

local function syncSystem()
    getgenv().BlackScreenConfig.enableBlackOverlay = overlayEnabled

    if frame then
        frame.Visible = overlayEnabled
    end

    if button then
        button.Text = overlayEnabled and "Black Screen: ON" or "Black Screen: OFF"
    end

    applySafeOptimizations(overlayEnabled)
    ultraOptimize(overlayEnabled)
end

local function toggleOverlay()
    overlayEnabled = not overlayEnabled
    syncSystem()
end

local function createUI()
    if gui then return end

    gui = Instance.new("ScreenGui")
    gui.Name = "KAMI•APA"
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999999
    gui.ResetOnSpawn = false
    gui.Parent = game:GetService("CoreGui")

    frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundColor3 = Color3.new(0,0,0)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local user = Instance.new("TextLabel")
    user.Size = UDim2.new(0,300,0,30)
    user.Position = UDim2.new(0.5,-150,0,10)
    user.BackgroundTransparency = 1
    user.TextColor3 = Color3.new(1,1,1)
    user.Font = Enum.Font.GothamBold
    user.TextSize = 22
    user.Text = LocalPlayer.Name
    user.Parent = gui

    fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.new(0,300,0,30)
    fpsLabel.Position = UDim2.new(0.5,-150,1,-40)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.TextColor3 = Color3.new(1,1,1)
    fpsLabel.Font = Enum.Font.GothamBold
    fpsLabel.TextSize = 22
    fpsLabel.Text = "FPS: 0"
    fpsLabel.Parent = gui

    button = Instance.new("TextButton")
    button.Size = UDim2.new(0,200,0,40)
    button.Position = UDim2.new(0.5,-100,0.9,0)
    button.BackgroundColor3 = Color3.fromRGB(25,25,25)
    button.TextColor3 = Color3.new(1,1,1)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 18
    button.Parent = gui

    button.MouseButton1Click:Connect(toggleOverlay)

    syncSystem()
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

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if input.KeyCode == getgenv().BlackScreenConfig.toggleOverlayKey then
        toggleOverlay()
    end
end)

createUI()
syncSystem()
