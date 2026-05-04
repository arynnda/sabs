task.wait(10)
if getgenv().__KAMI_APA_MAIN_RUNNING then return end
getgenv().__KAMI_APA_MAIN_RUNNING = true

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer

getgenv().TARGET_LIST = getgenv().TARGET_LIST or {}

getgenv().FORGOTTEN_UNITS = {}
getgenv().UNIT_SPAWN_COUNT = {}
getgenv().SEEN_UNIT_INSTANCES = {}

getgenv().MAX_SPAWN_BEFORE_FORGET = 12

getgenv().GRAB_RADIUS = 12
getgenv().TARGET_TIMEOUT = 50
getgenv().CHASE_DELAY = 0.5

getgenv().TARGET_QUEUE = {}
getgenv().currentTarget = nil
getgenv().targetStartTime = 0
getgenv().TARGET_SPAWN_TIME = {}

local RETRY_INTERVAL = 1

local function getUnitID(m)
	return m:GetAttribute("Index") or m.Name
end

local function canProcessUnit(m)

	if getgenv().SEEN_UNIT_INSTANCES[m] then
		return not getgenv().FORGOTTEN_UNITS[getUnitID(m)]
	end

	getgenv().SEEN_UNIT_INSTANCES[m] = true

	local id = getUnitID(m)

	getgenv().UNIT_SPAWN_COUNT[id] =
		(getgenv().UNIT_SPAWN_COUNT[id] or 0) + 1

	if getgenv().UNIT_SPAWN_COUNT[id] >= getgenv().MAX_SPAWN_BEFORE_FORGET then
		getgenv().FORGOTTEN_UNITS[id] = true
		return false
	end

	return true
end

local function isTarget(m)

	if getgenv().FORGOTTEN_UNITS[getUnitID(m)] then
		return false
	end

	local idx = m:GetAttribute("Index")
	if not idx then return false end

	for _,v in ipairs(getgenv().TARGET_LIST) do
		if idx == v then
			return canProcessUnit(m)
		end
	end

	return false
end

local function getTargetPart(model)

	if model.PrimaryPart then
		return model.PrimaryPart
	end

	for _,d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			return d
		end
	end

end

local function hasPurchasePrompt(model)

	for _,d in ipairs(model:GetDescendants()) do
		if d:IsA("ProximityPrompt") and d.ActionText == "Purchase" then
			return true
		end
	end

	return false
end

local function addTarget(unit)

	if getgenv().TARGET_SPAWN_TIME[unit] then return end

	getgenv().TARGET_SPAWN_TIME[unit] = tick()
	table.insert(getgenv().TARGET_QUEUE,unit)

end

local function scanExistingTargets()

	for _,o in ipairs(workspace:GetDescendants()) do
		if o:IsA("Model") and isTarget(o) then
			addTarget(o)
		end
	end

end

scanExistingTargets()

workspace.DescendantAdded:Connect(function(o)

	if o:IsA("Model") and isTarget(o) then
		addTarget(o)
	end

end)


ProximityPromptService.PromptShown:Connect(function(prompt)

	if prompt.ActionText ~= "Purchase" then return end

	local model = prompt:FindFirstAncestorOfClass("Model")
	if not model then return end

	if not isTarget(model) then return end

	task.wait(0.05)

	pcall(function()
		fireproximityprompt(prompt)
	end)

end)

task.spawn(function()

	while true do

		if not getgenv().currentTarget then

			repeat
				getgenv().currentTarget =
					table.remove(getgenv().TARGET_QUEUE,1)
			until not getgenv().currentTarget
				or getgenv().currentTarget.Parent

			getgenv().targetStartTime = tick()

		end

		local tgt = getgenv().currentTarget

		if tgt and tgt.Parent then

			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local part = getTargetPart(tgt)

			if hum and hrp and part then

				local spawnTime =
					getgenv().TARGET_SPAWN_TIME[tgt]

				if not spawnTime or
					tick() - spawnTime >= getgenv().CHASE_DELAY then

					local dist =
						(hrp.Position - part.Position).Magnitude

					if false then
						hum:MoveTo(part.Position)
					end

					if dist <= getgenv().GRAB_RADIUS then

						if not hasPurchasePrompt(tgt) then

							local id = getUnitID(tgt)

							getgenv().FORGOTTEN_UNITS[id] = true
							getgenv().TARGET_SPAWN_TIME[tgt] = nil
							getgenv().currentTarget = nil

						end

					end

				end

			end

			if tick() - getgenv().targetStartTime >= getgenv().TARGET_TIMEOUT then
				getgenv().currentTarget = nil
			end

		else

			getgenv().currentTarget = nil

		end

		task.wait(RETRY_INTERVAL)

	end

end)

local TARGETS = {
	Vector3.new(-410.9753, -6.50, 71.84),
	Vector3.new(-436.8611, -6.25, 64.40),
	Vector3.new(-412.4242, -6.50, 60.97),
}

local ARRIVE_DISTANCE = 3
local MOVE_TIMEOUT = 5
local WAIT_AT_LAST = 20 

getgenv().__SESSION_ID = 0

local function getChar()
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid")
	local root = char:WaitForChild("HumanoidRootPart")
	return hum, root
end

local function moveTo(hum, root, target)
	local goal = Vector3.new(target.X, root.Position.Y, target.Z)
	hum:MoveTo(goal)

	local start = tick()

	while tick() - start < MOVE_TIMEOUT do
		if (root.Position - goal).Magnitude <= ARRIVE_DISTANCE then
			return true
		end
		if hum.Health <= 0 then
			return false
		end
		task.wait(0.1)
	end

	return false
end

local function startSystem()
	getgenv().__SESSION_ID += 1
	local mySession = getgenv().__SESSION_ID

	task.spawn(function()
		local hum, root = getChar()

		for i, target in ipairs(TARGETS) do
			if hum.Health <= 0 or mySession ~= getgenv().__SESSION_ID then return end

			print("🎯 Target", i)
			local reached = moveTo(hum, root, target)

			if not reached then return end
		end

		local lastTarget = TARGETS[3]

		local startWait = tick()

		while tick() - startWait < WAIT_AT_LAST do
			if hum.Health <= 0 or mySession ~= getgenv().__SESSION_ID then return end

			local goal = lastTarget

			if (root.Position - goal).Magnitude > ARRIVE_DISTANCE then
				hum:MoveTo(goal)
			end

			task.wait(0.5)
		end

		if hum.Health > 0 and mySession == getgenv().__SESSION_ID then
			hum.Health = 0
		end
	end)
end

startSystem()

player.CharacterAdded:Connect(function()
	task.wait(0.5)
	startSystem()
end)

if not getgenv().__KAMI_APA_AUTO_SPEED_COIL then
	getgenv().__KAMI_APA_AUTO_SPEED_COIL = true

	local function equipSpeedCoil()

		local char = player.Character
		if not char then return end

		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then return end

		local backpack = player:FindFirstChildOfClass("Backpack")
		if not backpack then return end

		for _,tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") and string.find(string.lower(tool.Name),"speed") then
				hum:EquipTool(tool)
				break
			end
		end

	end

	player.CharacterAdded:Connect(function()
		task.wait(1)
		equipSpeedCoil()
	end)

	if player:FindFirstChildOfClass("Backpack") then
		player.Backpack.ChildAdded:Connect(function(tool)
			task.wait(0.2)
			equipSpeedCoil()
		end)
	end

	task.spawn(function()
		while true do
			equipSpeedCoil()
			task.wait(1)
		end
	end)

end

if not getgenv().__KAMI_APA_AUTO_BUY_FIX then
	getgenv().__KAMI_APA_AUTO_BUY_FIX = true

	task.spawn(function()
		while true do

			local tgt = getgenv().currentTarget

			if tgt and tgt.Parent then
				for _,v in ipairs(tgt:GetDescendants()) do
					if v:IsA("ProximityPrompt") 
					and v.Enabled 
					and v.ActionText == "Purchase" then
						
						pcall(function()
							fireproximityprompt(v, 2)
						end)

						task.wait(0.2)
					end
				end
			end

			task.wait(0.3)
		end
	end)
end

if getgenv().AUTO_E then return end
getgenv().AUTO_E = true

local ProximityPromptService = game:GetService("ProximityPromptService")
task.wait(0)
print("AUTO E ACTIVE")

ProximityPromptService.PromptShown:Connect(function(prompt)
	if prompt.ActionText == "Open" or string.find(prompt.ObjectText or "", "Open") then
		task.wait(0.1)
		pcall(function()
			fireproximityprompt(prompt)
		end)
	end
end)
