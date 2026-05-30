if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

pcall(function()
	if setfpscap then
		setfpscap(6)
	end
end)

for _,v in pairs(game:GetDescendants()) do
	pcall(function()

		if v:IsA("ParticleEmitter")
		or v:IsA("Trail")
		or v:IsA("Smoke")
		or v:IsA("Fire")
		or v:IsA("Sparkles")
		or v:IsA("Explosion") then
			v:Destroy()
		end

		if v:IsA("Decal")
		or v:IsA("Texture") then
			v.Transparency = 1
		end

		if v:IsA("BasePart") then
			v.Material = Enum.Material.SmoothPlastic
			v.Reflectance = 0
			v.CastShadow = false
		end

		if v:IsA("BlurEffect")
		or v:IsA("SunRaysEffect")
		or v:IsA("ColorCorrectionEffect")
		or v:IsA("BloomEffect")
		or v:IsA("DepthOfFieldEffect") then
			v.Enabled = false
		end

	end)
end


pcall(function()
	Lighting.GlobalShadows = false
	Lighting.FogEnd = 9e9
	Lighting.Brightness = 0
	Lighting.ClockTime = 14
end)

pcall(function()
	Terrain.WaterWaveSize = 0
	Terrain.WaterWaveSpeed = 0
	Terrain.WaterReflectance = 0
	Terrain.WaterTransparency = 1
end)

local sky = Instance.new("Sky")
sky.Parent = Lighting

Lighting.Ambient = Color3.fromRGB(255,255,255)
Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)

local cc = Instance.new("ColorCorrectionEffect")
cc.Parent = Lighting
cc.Brightness = 0.15
cc.Contrast = -0.1
cc.Saturation = -1
cc.TintColor = Color3.fromRGB(255,255,255)

local blur = Instance.new("BlurEffect")
blur.Parent = Lighting
blur.Size = 2

workspace.DescendantAdded:Connect(function(v)
	task.spawn(function()
		pcall(function()

			if v:IsA("ParticleEmitter")
			or v:IsA("Trail")
			or v:IsA("Smoke")
			or v:IsA("Fire")
			or v:IsA("Sparkles") then
				v:Destroy()
			end

			if v:IsA("BasePart") then
				v.Material = Enum.Material.SmoothPlastic
				v.CastShadow = false
			end

			if v:IsA("Decal")
			or v:IsA("Texture") then
				v.Transparency = 1
			end

		end)
	end)
end)

RunService:Set3dRenderingEnabled(true)
