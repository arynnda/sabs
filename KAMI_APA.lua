task.delay(5, function()
	getgenv().TARGET_LIST = getgenv().TARGET_LIST or {}

	if getgenv().KAMI_APA_INIT then return end
	getgenv().KAMI_APA_INIT = true
	if getgenv().AUTO_GRAB_ACTIVE then return end
	getgenv().AUTO_GRAB_ACTIVE = true

	repeat task.wait() until game:IsLoaded()

	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local VirtualInputManager = game:GetService("VirtualInputManager")

	local player = Players.LocalPlayer

	getgenv().FORGOTTEN_UNITS = {}
	getgenv().UNIT_SPAWN_COUNT = {}
	getgenv().SEEN_UNIT_INSTANCES = {}
	getgenv().MAX_SPAWN_BEFORE_FORGET = 8
	getgenv().GRAB_RADIUS = 8
	getgenv().HOLD_TIME = 2.5
	getgenv().TARGET_TIMEOUT = 12
	getgenv().TARGET_QUEUE = {}
	getgenv().currentTarget = nil
	getgenv().promptBusy = false
	getgenv().targetStartTime = 0
	getgenv().TARGET_SPAWN_TIME = {}
	getgenv().CHASE_DELAY = 5

	local PRESS_TIME = 0.12
	local PRESS_DELAY = 0.4

	local function getUnitID(m)
		return m:GetAttribute("Index") or m.Name
	end

	local function canProcessUnit(m)
		if getgenv().SEEN_UNIT_INSTANCES[m] then
			return not getgenv().FORGOTTEN_UNITS[getUnitID(m)]
		end
		getgenv().SEEN_UNIT_INSTANCES[m] = true
		local id = getUnitID(m)
		getgenv().UNIT_SPAWN_COUNT[id] = (getgenv().UNIT_SPAWN_COUNT[id] or 0) + 1
		if getgenv().UNIT_SPAWN_COUNT[id] >= getgenv().MAX_SPAWN_BEFORE_FORGET then
			getgenv().FORGOTTEN_UNITS[id] = true
			return false
		end
		return true
	end

	local function isTarget(m)
		if getgenv().FORGOTTEN_UNITS[getUnitID(m)] then return false end
		local idx = m:GetAttribute("Index")
		if not idx then return false end
		for _, v in ipairs(getgenv().TARGET_LIST) do
			if idx == v then
				return canProcessUnit(m)
			end
		end
		return false
	end

	workspace.DescendantAdded:Connect(function(o)
		if o:IsA("Model") and isTarget(o) then
			getgenv().TARGET_SPAWN_TIME[o] = tick()
			table.insert(getgenv().TARGET_QUEUE, o)
		end
	end)

	local function pressEForTarget()
		pcall(function()
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
			task.wait(PRESS_TIME)
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
		end)
	end

	local function tryGrabTarget(tgt)
		if getgenv().promptBusy then return end
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local prompt = tgt:FindFirstChildWhichIsA("ProximityPrompt", true)

		if prompt and prompt.Enabled then
			if (hrp.Position - prompt.Parent.Position).Magnitude <= prompt.MaxActivationDistance then
				getgenv().promptBusy = true
				pcall(function()
					fireproximityprompt(prompt, getgenv().HOLD_TIME)
				end)
				task.delay(getgenv().HOLD_TIME + 0.3, function()
					getgenv().promptBusy = false
				end)
			end
		end
	end

	task.spawn(function()
		while true do
			if not getgenv().currentTarget and #getgenv().TARGET_QUEUE > 0 then
				getgenv().currentTarget = table.remove(getgenv().TARGET_QUEUE, 1)
				getgenv().targetStartTime = tick()
			end

			local tgt = getgenv().currentTarget
			if tgt then
				if not tgt.Parent or tick() - getgenv().targetStartTime > getgenv().TARGET_TIMEOUT then
					getgenv().SEEN_UNIT_INSTANCES[tgt] = nil
					getgenv().TARGET_SPAWN_TIME[tgt] = nil
					getgenv().currentTarget = nil
					getgenv().promptBusy = false
				else
					local char = player.Character
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					local hrp = char and char:FindFirstChild("HumanoidRootPart")
					local part = tgt:FindFirstChildWhichIsA("BasePart")
					local spawnTime = getgenv().TARGET_SPAWN_TIME[tgt]

					if hum and hrp and part and spawnTime and tick() - spawnTime >= getgenv().CHASE_DELAY then
						if (hrp.Position - part.Position).Magnitude > getgenv().GRAB_RADIUS then
							hum:MoveTo(part.Position)
						else
							tryGrabTarget(tgt)
							pressEForTarget()
							task.wait(PRESS_DELAY)
						end
					end
				end
			end
			task.wait(0.8)
		end
	end)

	local HOME_POS = Vector3.new(-411.2308654785165, -6.501978874206543, 232.30792236328125)
	local RETURN_DISTANCE = 25

	task.spawn(function()
		while true do
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if hum and root and hum.Health > 0 then
				local target = Vector3.new(HOME_POS.X, root.Position.Y, HOME_POS.Z)
				if (root.Position - target).Magnitude >= RETURN_DISTANCE then
					hum:MoveTo(target)
				end
			end
			task.wait(30)
		end
	end)

	local Packages = ReplicatedStorage:WaitForChild("Packages")
	local Net = require(Packages:WaitForChild("Net"))
	local SpinEvent = Net:RemoteEvent("CursedEventService/Spin")

	task.spawn(function()
		while true do
			SpinEvent:FireServer()
			task.wait(45)
		end
	end)

	task.spawn(function()
		while true do
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				for i = 1,2 do
					VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.I, false, game)
					VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.I, false, game)
				end
				for i = 1,2 do
					VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.O, false, game)
					VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.O, false, game)
				end
			end
			task.wait(360)
		end
	end)
end)
