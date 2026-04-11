if getgenv().__KAMI_APA_MAIN_RUNNING then return end
getgenv().__KAMI_APA_MAIN_RUNNING = true

task.wait(10)
repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer

getgenv().TARGET_LIST = getgenv().TARGET_LIST or {}

getgenv().FORGOTTEN_UNITS = {}
getgenv().UNIT_SPAWN_COUNT = {}
getgenv().SEEN_UNIT_INSTANCES = {}

getgenv().MAX_SPAWN_BEFORE_FORGET = 15

getgenv().GRAB_RADIUS = 30
getgenv().TARGET_TIMEOUT = 20
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

local lastCash
local cashValue

local function setupCashWatcher()

	local stats = player:FindFirstChild("leaderstats")
	if not stats then return end

	cashValue =
		stats:FindFirstChild("Cash")
		or stats:FindFirstChild("Money")
		or stats:FindFirstChild("Coins")

	if not cashValue then return end

	lastCash = cashValue.Value

	cashValue:GetPropertyChangedSignal("Value"):Connect(function()

		if not getgenv().currentTarget then
			lastCash = cashValue.Value
			return
		end

		if cashValue.Value < lastCash then

			local tgt = getgenv().currentTarget

			if tgt then
				getgenv().FORGOTTEN_UNITS[getUnitID(tgt)] = true
			end

			getgenv().currentTarget = nil

		end

		lastCash = cashValue.Value

	end)

end

task.spawn(function()

	repeat task.wait(1) until player:FindFirstChild("leaderstats")
	setupCashWatcher()

end)

ProximityPromptService.PromptShown:Connect(function(prompt)

	if prompt.ActionText ~= "Purchase" then return end

	local model = prompt:FindFirstAncestorOfClass("Model")
	if not model then return end

	if model ~= getgenv().currentTarget then return end

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

					if dist > 2 then
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

task.wait(10)

local TARGETS = {
	Vector3.new(-348.0880126953125, -7.00197696685791, 200.22195434570312),
	Vector3.new(-317.9670104980469, -7.00197696685791, 173.2742462158203),
	Vector3.new(-351.6064453125, -7.00197696685791, 140.5575408935547),
	Vector3.new(-473.55859375, -7.00197696685791, 190.71792602539062),
	Vector3.new(-508.02239990234375, -7.001977443695068, 172.8726348876953),
	Vector3.new(-468.2983093261719, -7.001977443695068, 143.89483642578125),
	Vector3.new(-467.0907287597656, -7.00197696685791, 81.65995788574219),
	Vector3.new(-509.8305969238281, -7.001977443695068, 60.71058654785156),
	Vector3.new(-472.07244873046875, -7.001977443695068, 36.392723083496094),
	Vector3.new(-469.87548828125, -7.00197696685791, -15.740150451660156),
	Vector3.new(-344.73223876953125, -7.00197696685791, -17.095312118530273),
	Vector3.new(-348.09686279296875, -7.00197696685791, 38.18037033081055),
	Vector3.new(-303.9809875488281, -7.00197696685791, 66.93953704833984),
	Vector3.new(-350.02508544921875, -7.00197696685791, 80.84918975830078),
	Vector3.new(-351.5947570800781, -7.00197696685791, -22.45192527770996),
	Vector3.new(-313.3937072753906, -7.0019755363464355, -41.653873443603516),
	Vector3.new(-348.0111083984375, -7.00197696685791, -75.82738494873047),
	Vector3.new(-478.1455383300781, -7.00197696685791, -26.706602096557617),
	Vector3.new(-518.7659301757812, -7.00197696685791, -46.07236099243164),
	Vector3.new(-471.6510009765625, -7.00197696685791, -69.66283416748047),
	Vector3.new(-465.0112609863281, -7.001976490020752, -129.6852264404297),
	Vector3.new(-346.22027587890625, -7.00197696685791, -123.08599853515625),
	Vector3.new(-434.94287109375,-6.627068042755127,62.77268600463867),
}

local ARRIVE_DISTANCE = 3
local MOVE_TIMEOUT = 5
local TARGET_DELAY = 0.4
local LOOP_IDLE = 30

local function getChar()
	local char = player.Character or player.CharacterAdded:Wait()
	return char:WaitForChild("Humanoid"), char:WaitForChild("HumanoidRootPart")
end

task.spawn(function()

while true do
	local humanoid, root = getChar()

	for i, target in ipairs(TARGETS) do
		if humanoid.Health <= 0 then break end

		print("🎯 Target", i)

		local goal = Vector3.new(target.X, root.Position.Y, target.Z)
		humanoid:MoveTo(goal)

		local start = tick()
		while tick() - start < MOVE_TIMEOUT do
			if (root.Position - goal).Magnitude <= ARRIVE_DISTANCE then
				break
			end
			task.wait(0.1)
		end

		task.wait(TARGET_DELAY)
	end

	task.wait(LOOP_IDLE)
end

end)
task.spawn(function()

	while true do

		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")

		if hum and hum.Health > 0 then

			for _=1,2 do
				VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.I,false,game)
				VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.I,false,game)
			end

			for _=1,2 do
				VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.O,false,game)
				VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.O,false,game)
			end

		end

		task.wait(360)

	end

end)

if not getgenv().__KAMI_APA_AUTO_RESET_RUNNING then

	getgenv().__KAMI_APA_AUTO_RESET_RUNNING = true
	local AUTO_RESET_DELAY = 600

	task.spawn(function()

		while true do

			task.wait(AUTO_RESET_DELAY)

			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")

			if hum and hum.Health > 0 then
				if not getgenv().currentTarget
					and #getgenv().TARGET_QUEUE == 0 then
					hum.Health = 0
				end
			end

		end

	end)

end

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
		player.Backpack.ChildAdded:Connect(function()
			task.wait(0.2)
			equipSpeedCoil()
		end)
	end

	task.spawn(function()
		while true do
			equipSpeedCoil()
			task.wait(0)
		end
	end)
end
