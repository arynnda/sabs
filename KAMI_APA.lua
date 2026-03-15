if getgenv().__KAMI_APA_MAIN_RUNNING then return end
getgenv().__KAMI_APA_MAIN_RUNNING = true

task.wait(5)
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

task.wait(30)

local TARGETS = {
	Vector3.new(-434.94287109375,-6.627068042755127,62.77268600463867),
	Vector3.new(-423.8445739746094,-7.02985143661499,-45.90609550476074),
	Vector3.new(-464.0876159667969,-7.02985143661499,-16.276538848876953),
	Vector3.new(-517.69921875,-7.02985143661499,-37.940185546875),
	Vector3.new(-467.0399169921875,-7.02985143661499,-74.67424774169922),
	Vector3.new(-467.6302490234375,-7.02985143661499,-47.24452590942383),
	Vector3.new(-371.7828063964844,-7.02985143661499,-86.44377899169922),
	Vector3.new(-321.6971130371094,-7.029850959777832,-56.411224365234375),
	Vector3.new(-318.7573547363281,-7.02985143661499,-30.5594482421875),
	Vector3.new(-362.0663146972656,-7.02985143661499,-22.298091888427734),
	Vector3.new(-367.6721496582031,-7.02985143661499,-44.765235900878906),
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
	local AUTO_RESET_DELAY = 120

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

if getgenv().AUTO_E then return end
getgenv().AUTO_E = true

local ProximityPromptService = game:GetService("ProximityPromptService")
task.wait(0.1)
print("AUTO E ACTIVE")

ProximityPromptService.PromptShown:Connect(function(prompt)
	if prompt.ActionText == "Open" or string.find(prompt.ObjectText or "", "Spin") then
		task.wait(0.1)
		pcall(function()
			fireproximityprompt(prompt)
		end)
	end
end)

if not getgenv().__KAMI_APA_AUTO_LEFT_CLICK then
	getgenv().__KAMI_APA_AUTO_LEFT_CLICK = true

	local VIM = game:GetService("VirtualInputManager")
	task.wait(30)
	local CLICK_POS = Vector2.new(476,412)

	task.spawn(function()
		while getgenv().__KAMI_APA_AUTO_LEFT_CLICK do
			VIM:SendMouseButtonEvent(CLICK_POS.X,CLICK_POS.Y,0,true,game,0)
			task.wait(20)
			VIM:SendMouseButtonEvent(CLICK_POS.X,CLICK_POS.Y,0,false,game,0)
			task.wait(60)
		end
	end)
end
