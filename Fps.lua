if getgenv().__KAMI_BLACKSCREEN_RUNNING then return end
getgenv().__KAMI_BLACKSCREEN_RUNNING=true

repeat task.wait() until game:IsLoaded()
repeat task.wait() until game:GetService("Players").LocalPlayer

local Lighting=game:GetService("Lighting")
local OPTIMIZATION_ENABLED=true
local DISABLE_PARTICLES=true
local DISABLE_TEXTURES=true
local DISABLE_SHADOWS=true
local DISABLE_LIGHTING_EFFECTS=true

local function optimizeGraphicsQuality()
	if not OPTIMIZATION_ENABLED then return end
	pcall(function()
		local r=settings().Rendering
		r.QualityLevel=Enum.QualityLevel.Level01
		r.TextureQuality=Enum.TextureQuality.Level1
	end)
end

local function optimizeLighting()
	if not OPTIMIZATION_ENABLED then return end

	pcall(function()
		Lighting.GlobalShadows=false
		Lighting.FogEnd=1000000
		Lighting.Brightness=1
		Lighting.Ambient=Color3.fromRGB(50,50,50)
		Lighting.OutdoorAmbient=Color3.fromRGB(50,50,50)
		Lighting.EnvironmentDiffuseScale=0
		Lighting.EnvironmentSpecularScale=0
	end)

	if DISABLE_LIGHTING_EFFECTS then
		for _,effect in ipairs(Lighting:GetChildren()) do
			pcall(function()
				if effect:IsA("BloomEffect") or effect:IsA("BlurEffect")
				or effect:IsA("ColorCorrectionEffect") or effect:IsA("DepthOfFieldEffect")
				or effect:IsA("SunRaysEffect") then
					effect.Enabled=false
				elseif effect:IsA("Atmosphere") then
					effect.Density=0
					effect.Haze=0
					effect.Glare=0
				end
			end)
		end
	end
end

local function optimizeObject(obj)
	if not OPTIMIZATION_ENABLED then return end

	pcall(function()
		if obj:IsA("BasePart") then
			obj.LocalTransparencyModifier=1
			if DISABLE_SHADOWS then obj.CastShadow=false end
		end

		if DISABLE_PARTICLES and (
			obj:IsA("ParticleEmitter") or obj:IsA("Trail") or
			obj:IsA("Beam") or obj:IsA("Fire") or
			obj:IsA("Smoke") or obj:IsA("Sparkles")
		) then obj.Enabled=false end

		if DISABLE_TEXTURES and (
			obj:IsA("Decal") or obj:IsA("Texture")
		) then obj.Transparency=1 end
	end)
end

local function optimizeWorkspace()
	if not OPTIMIZATION_ENABLED then return end
	for _,obj in ipairs(workspace:GetDescendants()) do optimizeObject(obj) end
end

workspace.DescendantAdded:Connect(function(obj)
	if not OPTIMIZATION_ENABLED then return end
	task.defer(optimizeObject,obj)
end)

optimizeGraphicsQuality()
optimizeLighting()
optimizeWorkspace()
```
