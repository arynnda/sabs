if getgenv().__KAMI_APA_MAIN_RUNNING then return end
getgenv().__KAMI_APA_MAIN_RUNNING = true

task.wait(5)
repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer

getgenv().TARGET_LIST = getgenv().TARGET_LIST or {}
getgenv().FORGOTTEN_UNITS = {}
getgenv().UNIT_SPAWN_COUNT = {}
getgenv().SEEN_UNIT_INSTANCES = {}
getgenv().MAX_SPAWN_BEFORE_FORGET = 15

getgenv().GRAB_RADIUS = 10
getgenv().TARGET_TIMEOUT = 30
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

-- FIX: ambil BasePart secara aman
local function getTargetPart(model)
	if model.PrimaryPart then
		return model.PrimaryPart
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			return d
		end
	end
end

local function scanExistingTargets()
	for _, o in ipairs(workspace:GetDescendants()) do
		if o:IsA("Model") and isTarget(o) then
			if not getgenv().TARGET_SPAWN_TIME[o] then
				getgenv().TARGET_SPAWN_TIME[o] = tick()
				table.insert(getgenv().TARGET_QUEUE, o)
			end
		end
	end
end
scanExistingTargets()

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
	cashValue = stats:FindFirstChild("Cash") or stats:FindFirstChild("Money") or stats:FindFirstChild("Coins")
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
			local part = getTargetPart(tgt) -- FIX

			if hum and hrp and part then
				local spawnTime = getgenv().TARGET_SPAWN_TIME[tgt]
				if not spawnTime or tick() - spawnTime >= getgenv().CHASE_DELAY then
					local dist = (hrp.Position - part.Position).Magnitude

					if dist > 2 then -- FIX: jangan spam MoveTo
						hum:MoveTo(part.Position)
					end

					if dist <= getgenv().GRAB_RADIUS then
						setHoldE(true)
					else
						setHoldE(false)
					end

					if holdingE and tick() - holdStart >= MAX_HOLD_TIME then
						setHoldE(false)
						getgenv().currentTarget = nil
					end
				else
					setHoldE(false)
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
			for _ = 1,2 do
				VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.I, false, game)
				VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.I, false, game)
			end
			for _ = 1,2 do
				VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.O, false, game)
				VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.O, false, game)
			end
		end
		task.wait(360)
	end
end)

local function onCharacterAdded()
	task.wait(1)
	setHoldE(false)
	getgenv().currentTarget = nil
	getgenv().TARGET_QUEUE = {}
	getgenv().TARGET_SPAWN_TIME = {}
	scanExistingTargets()
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded()
end

if not getgenv().__KAMI_APA_AUTO_RESET_RUNNING then
	getgenv().__KAMI_APA_AUTO_RESET_RUNNING = true

	local AUTO_RESET_DELAY = 180

	task.spawn(function()
		while true do
			task.wait(AUTO_RESET_DELAY)
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				if not getgenv().currentTarget and #getgenv().TARGET_QUEUE == 0 then
					hum.Health = 0
				end
			end
		end
	end)
end
