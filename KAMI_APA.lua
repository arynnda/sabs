task.delay(10, function()
getgenv().TARGET_LIST = getgenv().TARGET_LIST or {}


	if getgenv().KAMI_APA_INIT then return end
	getgenv().KAMI_APA_INIT = true
	print("KAMI•APA?")

	if getgenv().AUTO_GRAB_ACTIVE then return end
	getgenv().AUTO_GRAB_ACTIVE = true

	repeat task.wait(1) until game:IsLoaded()

	local Players = game:GetService("Players")
	local ProximityPromptService = game:GetService("ProximityPromptService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local VirtualInputManager = game:GetService("VirtualInputManager")

	local player = Players.LocalPlayer
	local camera = workspace.CurrentCamera

	getgenv().FORGOTTEN_UNITS = {}
	getgenv().UNIT_SPAWN_COUNT = {}
	getgenv().SEEN_UNIT_INSTANCES = {}
	getgenv().MAX_SPAWN_BEFORE_FORGET = 10
	getgenv().GRAB_RADIUS = 8
	getgenv().HOLD_TIME = 2.5
	getgenv().TARGET_TIMEOUT = 10
	getgenv().TARGET_QUEUE = {}
	getgenv().currentTarget = nil
	getgenv().promptBusy = false
	getgenv().targetStartTime = 0

	local function getUnitID(model)
		return model:GetAttribute("Index") or model.Name
	end

	local function canProcessUnit(model)
		if getgenv().SEEN_UNIT_INSTANCES[model] then
			return not getgenv().FORGOTTEN_UNITS[getUnitID(model)]
		end
		getgenv().SEEN_UNIT_INSTANCES[model] = true
		local id = getUnitID(model)
		getgenv().UNIT_SPAWN_COUNT[id] = (getgenv().UNIT_SPAWN_COUNT[id] or 0) + 1
		if getgenv().UNIT_SPAWN_COUNT[id] >= getgenv().MAX_SPAWN_BEFORE_FORGET then
			getgenv().FORGOTTEN_UNITS[id] = true
			return false
		end
		return true
	end

	local function isTarget(model)
		if getgenv().FORGOTTEN_UNITS[getUnitID(model)] then return false end
		local idx = model:GetAttribute("Index")
		if not idx then return false end
		for _, n in ipairs(getgenv().TARGET_LIST) do
			if idx == n then
				return canProcessUnit(model)
			end
		end
		return false
	end

	workspace.DescendantAdded:Connect(function(obj)
		if obj:IsA("Model") and isTarget(obj) then
			table.insert(getgenv().TARGET_QUEUE, obj)
		end
	end)

	ProximityPromptService.PromptShown:Connect(function(prompt)
		if not getgenv().currentTarget then return end
		if getgenv().promptBusy then return end
		if not prompt:IsDescendantOf(getgenv().currentTarget) then return end
		getgenv().promptBusy = true
		task.delay(0.25, function()
			pcall(function()
				fireproximityprompt(prompt, getgenv().HOLD_TIME)
			end)
			task.delay(getgenv().HOLD_TIME + 0.3, function()
				getgenv().promptBusy = false
			end)
		end)
	end)

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
					getgenv().currentTarget = nil
					getgenv().promptBusy = false
				else
					local part = tgt:FindFirstChildWhichIsA("BasePart")
					local char = player.Character
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					local hrp = char and char:FindFirstChild("HumanoidRootPart")
					if part and hum and hrp then
						if (hrp.Position - part.Position).Magnitude > getgenv().GRAB_RADIUS then
							hum:MoveTo(part.Position)
						end
					end
				end
			end
			task.wait(0.6)
		end
	end)

	local TARGETS = {
		Vector3.new(-410.11822509765625, -6.4036846, 167.416473),
		Vector3.new(-408.23968505859374, -6.4036846, 95.5442123),
		Vector3.new(-407.6501159667969, -6.4036846, 82.0257492),
		Vector3.new(-418.2996520996094, -6.4036850, 81.5518341)
	}

	task.spawn(function()
		while true do
			local char = player.Character or player.CharacterAdded:Wait()
			local hum = char:WaitForChild("Humanoid")
			local root = char:WaitForChild("HumanoidRootPart")
			for _, target in ipairs(TARGETS) do
				if hum.Health <= 0 then break end
				local goal = Vector3.new(target.X, root.Position.Y, target.Z)
				hum:MoveTo(goal)
				local start = tick()
				while tick() - start < 5 do
					if (root.Position - goal).Magnitude <= 3 then break end
					task.wait(0.2)
				end
				task.wait(0.5)
			end
			task.wait(10)
		end
	end)

	local Packages = ReplicatedStorage:WaitForChild("Packages")
	local Net = require(Packages:WaitForChild("Net"))
	local SpinEvent = Net:RemoteEvent("CursedEventService/Spin")

	task.spawn(function()
		while true do
			SpinEvent:FireServer()
			task.wait(30)
		end
	end)

	task.spawn(function()
		while true do
			local char = player.Character or player.CharacterAdded:Wait()
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				for i = 1,2 do
					VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.I, false, game)
					task.wait(0.2)
					VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.I, false, game)
					task.wait(0.2)
				end
				for i = 1,2 do
					VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.O, false, game)
					task.wait(0.2)
					VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.O, false, game)
					task.wait(0.2)
				end
			end
			task.wait(300)
		end
	end)
end)
