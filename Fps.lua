if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local Terrain = workspace:FindFirstChildOfClass("Terrain")

pcall(function()
	local old = CoreGui:FindFirstChild("BlackOverlay")
	if old then
		old:Destroy()
	end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "BlackOverlay"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.Enabled = false
gui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(1, 0, 1, 0)
frame.Position = UDim2.new(0, 0, 0, 0)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BorderSizePixel = 0
frame.Parent = gui

local text = Instance.new("TextLabel")
text.AnchorPoint = Vector2.new(0.5, 0.5)
text.Position = UDim2.new(0.5, 0, 0.5, 0)
text.Size = UDim2.new(0, 500, 0, 60)

text.BackgroundTransparency = 1
text.Text = player.Name
text.TextColor3 = Color3.fromRGB(255, 255, 255)
text.TextSize = 40
text.Font = Enum.Font.GothamBold

text.Parent = frame

pcall(function()
	Lighting.GlobalShadows = false
	Lighting.FogEnd = 9e9
	Lighting.Brightness = 1
	Lighting.EnvironmentDiffuseScale = 0
	Lighting.EnvironmentSpecularScale = 0
end)

for _, v in pairs(Lighting:GetChildren()) do
	if v:IsA("BlurEffect")
	or v:IsA("SunRaysEffect")
	or v:IsA("BloomEffect")
	or v:IsA("ColorCorrectionEffect")
	or v:IsA("DepthOfFieldEffect")
	or v:IsA("Atmosphere") then
		v:Destroy()
	end
end

pcall(function()
	if Terrain then
		Terrain.WaterWaveSize = 0
		Terrain.WaterWaveSpeed = 0
		Terrain.WaterReflectance = 0
		Terrain.WaterTransparency = 1
	end
end)

for _, obj in pairs(workspace:GetDescendants()) do
	pcall(function()

		if obj:IsA("BasePart") then
			obj.Material = Enum.Material.Plastic
			obj.Reflectance = 0
			obj.CastShadow = false
		end

		if obj:IsA("Decal")
		or obj:IsA("Texture") then
			obj.Transparency = 1
		end

		if obj:IsA("ParticleEmitter")
		or obj:IsA("Trail")
		or obj:IsA("Smoke")
		or obj:IsA("Fire")
		or obj:IsA("Sparkles") then
			obj.Enabled = false
		end

		if obj:IsA("Explosion") then
			obj.BlastPressure = 0
			obj.BlastRadius = 0
		end
	end)
end

pcall(function()
	settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
end)

getgenv().BlackScreenOn = function()
	if gui then
		gui.Enabled = true
	end
end

getgenv().BlackScreenOff = function()
	if gui then
		gui.Enabled = false
	end
end
