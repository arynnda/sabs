if getgenv().__KAMI_APA_MAIN_RUNNING then return end
getgenv().__KAMI_APA_MAIN_RUNNING = true

task.wait(5)
repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ProximityPromptService = game:GetService("ProximityPromptService")
local PathfindingService = game:GetService("PathfindingService")

local player = Players.LocalPlayer
local currentCharacter = player.Character or player.CharacterAdded:Wait()
local char = currentCharacter


player.CharacterAdded:Connect(function(c)
	currentCharacter = c
end)

local STUCK_TIME = 2
local STUCK_DISTANCE = 5
local TELEPORT_DISTANCE = 120

getgenv().TARGET_LIST = getgenv().TARGET_LIST or { }

getgenv().FORGOTTEN_UNITS = {}
getgenv().UNIT_SPAWN_COUNT = {}
getgenv().SEEN_UNIT_INSTANCES = {}
getgenv().MAX_SPAWN_BEFORE_FORGET = 12

getgenv().GRAB_RADIUS = 20
getgenv().TARGET_TIMEOUT = 30
getgenv().CHASE_DELAY = 0.5

getgenv().TARGET_QUEUE = {}
getgenv().currentTarget = nil
getgenv().targetStartTime = 0
getgenv().TARGET_SPAWN_TIME = {}

local RETRY_INTERVAL = 1

local lastPos = nil
local lastMoveTime = tick()

local function isStuck(root)
	if not root then return false end
	
	if not lastPos then
		lastPos = root.Position
		lastMoveTime = tick()
		return false
	end
	
	local dist = (root.Position - lastPos).Magnitude
	
	if dist > STUCK_DISTANCE then
		lastPos = root.Position
		lastMoveTime = tick()
		return false
	end
	
	if tick() - lastMoveTime >= STUCK_TIME then
		return true
	end
	
	return false
end

local function smartMove(hum, root, targetPos)
	if not hum or not root then return end

	hum:MoveTo(targetPos)

	task.delay(1, function()
		if not hum or hum.Health <= 0 then return end

		if isStuck(root) then
			local path = PathfindingService:CreatePath()

			local ok = pcall(function()
				path:ComputeAsync(root.Position, targetPos)
			end)

			if ok and path.Status == Enum.PathStatus.Success then
				for _,waypoint in ipairs(path:GetWaypoints()) do
					if getgenv().currentTarget == nil then return end
					hum:MoveTo(waypoint.Position)
					hum.MoveToFinished:Wait()
				end
			else
				if (root.Position - targetPos).Magnitude <= TELEPORT_DISTANCE then
					root.CFrame = CFrame.new(targetPos + Vector3.new(0,3,0))
				end
			end
		end
	end)
end


getgenv().resetPath = function()
	lastPos = nil
	lastMoveTime = tick()
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
	if model.PrimaryPart then return model.PrimaryPart end
	for _,d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then return d end
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
		task.wait(3)

		local char = currentCharacter
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")

		if hum and root and hum.Health > 0 then
			if isStuck(root) then
				if getgenv().currentTarget then
					local part = getTargetPart(getgenv().currentTarget)
					if part then
						smartMove(hum, root, part.Position)
					end
				else
					if scanPoints and scanPoints[scanIndex] then
						smartMove(hum, root, scanPoints[scanIndex])
					end
				end
			end
		end
	end
end)

task.spawn(function()
	while true do

		if not getgenv().currentTarget then
			repeat
				getgenv().currentTarget = table.remove(getgenv().TARGET_QUEUE,1)
			until not getgenv().currentTarget or getgenv().currentTarget.Parent

			getgenv().targetStartTime = tick()
		end

		local tgt = getgenv().currentTarget

		if tgt and tgt.Parent then

			local char = currentCharacter
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local part = getTargetPart(tgt)

			if hum and hrp and part then

				local spawnTime = getgenv().TARGET_SPAWN_TIME[tgt]

				if not spawnTime or tick() - spawnTime >= getgenv().CHASE_DELAY then

					local dist = (hrp.Position - part.Position).Magnitude

					if dist > 2 then
						smartMove(hum, hrp, part.Position)
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

task.spawn(function()
	while true do

		local char = currentCharacter
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

local scanPoints = {}
local scanIndex = 1
local SCAN_RADIUS = 800

local function shuffle(t)
	for i = #t,2,-1 do
		local j = math.random(i)
		t[i],t[j] = t[j],t[i]
	end
end

local function createScan(center)
	scanPoints = {}
	scanIndex = 1

	for i=1,120 do
		local x = center.X + math.random(-SCAN_RADIUS,SCAN_RADIUS)
		local z = center.Z + math.random(-SCAN_RADIUS,SCAN_RADIUS)
		table.insert(scanPoints,Vector3.new(x,center.Y,z))
	end

	shuffle(scanPoints)
end

local function moveToPoint(hum,root,pos)
	local path = PathfindingService:CreatePath()

	local ok = pcall(function()
		path:ComputeAsync(root.Position,pos)
	end)

	if not ok or path.Status ~= Enum.PathStatus.Success then return end

	for _,waypoint in ipairs(path:GetWaypoints()) do
		if getgenv().currentTarget then return end
		hum:MoveTo(waypoint.Position)
		hum.MoveToFinished:Wait()
	end
end


local lastPos = nil
local lastMoveTime = tick()

getgenv().resetPath = function()
	lastPos = nil
	lastMoveTime = tick()
end


player.CharacterAdded:Connect(function(char)

	currentCharacter = char

	repeat task.wait() until char:FindFirstChild("HumanoidRootPart")

	getgenv().currentTarget = nil


	scanPoints = {}
	scanIndex = 1

	local root = char:FindFirstChild("HumanoidRootPart")
	if root then
		createScan(root.Position)
	end


	if getgenv().resetPath then
		getgenv().resetPath()
	end

end)


task.spawn(function()
	while true do

		if getgenv().currentTarget then
			task.wait(0.2)
			continue
		end

		local char = currentCharacter
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")

		if not char or not hum or not root then
			task.wait(1)
			continue
		end

		if hum.Health > 0 then

			if #scanPoints == 0 then
				createScan(root.Position)
			end

			if scanIndex > #scanPoints then
				createScan(root.Position)
				scanIndex = 1
			end

			local point = scanPoints[scanIndex]

			if point then
				moveToPoint(hum,root,point)
			end

			scanIndex += 1

		end

		task.wait(3)
	end
end)

player.CharacterAdded:Connect(function(char)

	currentCharacter = char

	repeat task.wait() until char:FindFirstChild("HumanoidRootPart")

	getgenv().currentTarget = nil

	if getgenv().resetPath then
		getgenv().resetPath()
	end

	local root = char:FindFirstChild("HumanoidRootPart")
	if root then
		createScan(root.Position)
		lastPos = nil
		lastMoveTime = tick()
	end

end)
