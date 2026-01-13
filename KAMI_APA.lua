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

	getgenv().GRAB_RADIUS = 10
	getgenv().TARGET_TIMEOUT = 14
	getgenv().HOLD_TIME = 3

	getgenv().TARGET_QUEUE = {}
	getgenv().currentTarget = nil
	getgenv().targetStartTime = 0
	getgenv().TARGET_SPAWN_TIME = {}

	getgenv().CHASE_DELAY = 0

	local holdingE = false
	local holdStart = 0
	local MAX_HOLD_TIME = 6
	local RETRY_INTERVAL = 0.25

	local function setHoldE(state)
		if state and not holdingE then
			holdingE = true
			holdStart = tick()
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
		elseif not state and holdingE then
			holdingE = false
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
		end
	end

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

	local lastCash
	local cashValue

	local function setupCashWatcher()
		local stats = player:FindFirstChild("leaderstats")
		if not stats then return end

		cashValue =
			stats:FindFirstChild("Cash")
			or stats:FindFirstChild("Money")
			or stats:FindFirstChild("Coins")

		if not cashValue or not cashValue:IsA("NumberValue") then return end
		lastCash = cashValue.Value

		cashValue:GetPropertyChangedSignal("Value"):Connect(function()
			if not getgenv().currentTarget then
				lastCash = cashValue.Value
				return
			end

			if cashValue.Value < lastCash then
				setHoldE(false)
				getgenv().currentTarget = nil
			end

			lastCash = cashValue.Value
		end)
	end

	task.spawn(function()
		repeat task.wait(1) until player:FindFirstChild("leaderstats")
		setupCashWatcher()
	end)

	task.spawn(function()
		while true do
			if not getgenv().currentTarget and #getgenv().TARGET_QUEUE > 0 then
				getgenv().currentTarget = table.remove(getgenv().TARGET_QUEUE, 1)
				getgenv().targetStartTime = tick()
			end

			local tgt = getgenv().currentTarget
			if tgt and tgt.Parent then
				local char = player.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				local part = tgt:FindFirstChildWhichIsA("BasePart")

				if hum and hrp and part then
					local dist = (hrp.Position - part.Position).Magnitude
					hum:MoveTo(part.Position)

					if dist <= getgenv().GRAB_RADIUS then
						setHoldE(true)
					else
						setHoldE(false)
					end

					if holdingE and tick() - holdStart >= MAX_HOLD_TIME then
						setHoldE(false)
						getgenv().currentTarget = nil
					end
				end

				if tick() - getgenv().targetStartTime >= getgenv().TARGET_TIMEOUT then
					setHoldE(false)
					getgenv().currentTarget = nil
				end
			else
				setHoldE(false)
				getgenv().currentTarget = nil
			end

			task.wait(RETRY_INTERVAL)
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
