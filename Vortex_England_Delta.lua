--[[
  ==========================================================================
   File Name   : VORTEX_ENGINE_DELTA_540.txt
   Script Name : VORTEX ENGINE // DELTA EDITION (MAIN ENGINE + FULL LOOP)
   Author      : Upgraded by AI Collaborator (Original Base Adapted)
   Key Module  : External / Separated Key System (Key: ONFYB929)
   Mode        : Full-Screen Spring Loading + Full Data & Hop/Carry Execution
   Build       : 2026.11-DELTA-540-FULL
  ==========================================================================
]]

--// 1. Services & Core References
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

--// 2. External Key System Bridge (Separated from Main Engine)
local FALLBACK_KEY_REF = "ONFYB929"

local Config = {
	-- External Key Gate
	RequireExternalKey = true,
	AllowLocalFallback = true,

	-- Full-Screen Spring Loading Config
	FullScreenSpringLoader = true,
	SpringStiffness = 175,
	SpringDamping = 22,
	MinLoaderDuration = 0.8,

	-- Physics, Hop & Movement Tuning
	SpeedCap = 1.20,
	HopRatio = 1.515,
	HopMin = 40,
	HopGap = 0.06,
	HopGapMin = 0.06,
	HopGapMax = 0.20,
	HopRetries = 6,
	HopLift = 42,
	LandOffset = 14,
	LandSettle = 0.08,
	DropDelay = 0.05,
	GrabInterval = 0.03,
	RegrabFar = 40,
	Height = 70,
	ClimbShare = 0.5,
	CarryRatio = 0.9,
	EasyRatio = 1.3,
	ArriveRadius = 2.5,
	SafeZoneRadius = 20,
	StuckTimeout = 1.5,
	StuckThreshold = 3.0,

	-- Auto Cycle Settings
	AutoCycle = false,
	CycleInterval = 0.35,

	-- Upgraded Background Features
	AutoRegrab = true,
	SmartAvoid = true,
	AntiAFK = true,
	RigSyncEnabled = true,
	StuckRecovery = true,
	DebugLog = true,
	FpsPulse = { 60, 30, 0.15 },
	TargetFps = 240,
}

--// 3. Runtime State & Telemetry
local State = {
	Authorized = false,
	LoadedAll = false,
	LoadProgress = 0,
	Carrying = false,
	Uid = nil,
	Delivered = 0,
	DeliveredCount = 0,
	RegrabCount = 0,
	RecoveryCount = 0,
	Busy = false,
	Cancel = false,
	Mult = 1,
	PulledAt = 0,
	HeldSeen = 0,
	GuessedDrop = false,
	LastAction = "Initialized",
	StartTime = os.clock(),
	History = {},
}

local RigSync = {
	Original = nil,
	Clone = nil,
	VisualClone = nil,
	Links = {},
	Connection = nil,
	Added = nil,
}

--// 4. Logging & External Key Check
local function logInfo(msg, isWarn)
	if not Config.DebugLog and not isWarn then return end
	local prefix = "[VORTEX ENGINE] "
	if isWarn then
		warn(prefix .. tostring(msg))
	else
		print(prefix .. tostring(msg))
	end
end

local function recordEvent(kind, detail)
	State.LastAction = string.format("%s: %s", tostring(kind), tostring(detail or ""))
	State.History[#State.History + 1] = {
		Time = os.clock(),
		Kind = kind,
		Detail = detail,
	}
	if #State.History > 100 then
		table.remove(State.History, 1)
	end
end

local function checkExternalKeyGate()
	if not Config.RequireExternalKey then
		State.Authorized = true
		return true
	end

	local keyMod = getgenv and getgenv().VortexKeySystem
	if type(keyMod) == "table" and type(keyMod.IsAuthorized) == "function" then
		local ok = keyMod.IsAuthorized()
		State.Authorized = (ok == true)
		return State.Authorized
	end

	if Config.AllowLocalFallback then
		local provided = (getgenv and getgenv().VORTEX_KEY) or rawget(_G, "VORTEX_KEY") or rawget(_G, "SCRIPT_KEY")
		if tostring(provided or "") == FALLBACK_KEY_REF then
			State.Authorized = true
			return true
		end
	end

	State.Authorized = false
	return false
end

if not checkExternalKeyGate() then
	logInfo("Blocked by external key gate. Run VORTEX_KEY_SYSTEM.txt first.", true)
	return
end

--// 4B. Full-Screen Spring Loading Screen (ทับหน้าจอทั้งหมด + โหลดข้อมูลและรูปแบบการทำงานทั้งหมด)
local FullScreenLoader = {
	Gui = nil,
	Active = false,
	TargetProgress = 0,
	CurrentProgress = 0,
	Velocity = 0,
	StatusText = "กำลังเตรียมระบบ...",
}

local function getLoaderGuiParent()
	local ok, gui = pcall(function()
		return CoreGui
	end)
	if ok and gui then
		return gui
	end
	return LocalPlayer and LocalPlayer:WaitForChild("PlayerGui")
end

local function createSpringLoadingScreen()
	if not Config.FullScreenSpringLoader then
		return
	end
	local parent = getLoaderGuiParent()
	if not parent then
		return
	end

	local old = parent:FindFirstChild("VortexFullScreenSpringLoader")
	if old then
		old:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "VortexFullScreenSpringLoader"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 10000
	screenGui.Parent = parent

	local backdrop = Instance.new("Frame")
	backdrop.Name = "FullScreenBackdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.Position = UDim2.fromScale(0, 0)
	backdrop.BackgroundColor3 = Color3.fromRGB(7, 9, 15)
	backdrop.BackgroundTransparency = 0
	backdrop.BorderSizePixel = 0
	backdrop.Active = true
	backdrop.Parent = screenGui

	local centerCard = Instance.new("Frame")
	centerCard.Name = "SpringCenterPanel"
	centerCard.AnchorPoint = Vector2.new(0.5, 0.5)
	centerCard.Position = UDim2.fromScale(0.5, 0.5)
	centerCard.Size = UDim2.fromOffset(420, 190)
	centerCard.BackgroundColor3 = Color3.fromRGB(15, 19, 30)
	centerCard.BorderSizePixel = 0
	centerCard.Parent = backdrop

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 16)
	cardCorner.Parent = centerCard

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = Color3.fromRGB(72, 145, 255)
	cardStroke.Thickness = 1.5
	cardStroke.Parent = centerCard

	local springBadge = Instance.new("Frame")
	springBadge.Name = "SpringBadge"
	springBadge.AnchorPoint = Vector2.new(0.5, 0)
	springBadge.Position = UDim2.new(0.5, 0, 0, 20)
	springBadge.Size = UDim2.fromOffset(44, 44)
	springBadge.BackgroundColor3 = Color3.fromRGB(48, 122, 255)
	springBadge.BorderSizePixel = 0
	springBadge.Parent = centerCard

	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(1, 0)
	badgeCorner.Parent = springBadge

	local badgeLabel = Instance.new("TextLabel")
	badgeLabel.Size = UDim2.fromScale(1, 1)
	badgeLabel.BackgroundTransparency = 1
	badgeLabel.Font = Enum.Font.GothamBold
	badgeLabel.TextSize = 14
	badgeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	badgeLabel.Text = "VX"
	badgeLabel.Parent = springBadge

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -32, 0, 24)
	titleLabel.Position = UDim2.fromOffset(16, 72)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 15
	titleLabel.TextColor3 = Color3.fromRGB(240, 246, 255)
	titleLabel.Text = "VORTEX ENGINE // LOADING ALL SYSTEMS"
	titleLabel.Parent = centerCard

	local detailLabel = Instance.new("TextLabel")
	detailLabel.Name = "DetailLabel"
	detailLabel.Size = UDim2.new(1, -32, 0, 20)
	detailLabel.Position = UDim2.fromOffset(16, 98)
	detailLabel.BackgroundTransparency = 1
	detailLabel.Font = Enum.Font.Gotham
	detailLabel.TextSize = 12
	detailLabel.TextColor3 = Color3.fromRGB(155, 175, 210)
	detailLabel.Text = "กำลังโหลดข้อมูลและรูปแบบการทำงานทั้งหมด..."
	detailLabel.Parent = centerCard

	local barBg = Instance.new("Frame")
	barBg.Name = "ProgressBarBg"
	barBg.Size = UDim2.new(1, -48, 0, 10)
	barBg.Position = UDim2.fromOffset(24, 132)
	barBg.BackgroundColor3 = Color3.fromRGB(24, 30, 46)
	barBg.BorderSizePixel = 0
	barBg.Parent = centerCard

	local barBgCorner = Instance.new("UICorner")
	barBgCorner.CornerRadius = UDim.new(1, 0)
	barBgCorner.Parent = barBg

	local barFill = Instance.new("Frame")
	barFill.Name = "ProgressBarFill"
	barFill.Size = UDim2.new(0, 0, 1, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(76, 154, 255)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg

	local barFillCorner = Instance.new("UICorner")
	barFillCorner.CornerRadius = UDim.new(1, 0)
	barFillCorner.Parent = barFill

	local percentLabel = Instance.new("TextLabel")
	percentLabel.Name = "PercentLabel"
	percentLabel.Size = UDim2.new(1, -48, 0, 18)
	percentLabel.Position = UDim2.fromOffset(24, 150)
	percentLabel.BackgroundTransparency = 1
	percentLabel.Font = Enum.Font.Code
	percentLabel.TextSize = 12
	percentLabel.TextColor3 = Color3.fromRGB(185, 205, 240)
	percentLabel.Text = "0%"
	percentLabel.Parent = centerCard

	FullScreenLoader.Gui = screenGui
	FullScreenLoader.Active = true
	FullScreenLoader.TargetProgress = 0.05
	FullScreenLoader.CurrentProgress = 0
	FullScreenLoader.Velocity = 0

	task.spawn(function()
		while FullScreenLoader.Active and screenGui and screenGui.Parent do
			local dt = math.min(RunService.RenderStepped:Wait(), 0.05)
			local disp = FullScreenLoader.TargetProgress - FullScreenLoader.CurrentProgress
			local accel = (disp * Config.SpringStiffness) - (FullScreenLoader.Velocity * Config.SpringDamping)
			FullScreenLoader.Velocity += accel * dt
			FullScreenLoader.CurrentProgress = math.clamp(FullScreenLoader.CurrentProgress + (FullScreenLoader.Velocity * dt), 0, 1)

			State.LoadProgress = FullScreenLoader.CurrentProgress
			barFill.Size = UDim2.new(FullScreenLoader.CurrentProgress, 0, 1, 0)
			percentLabel.Text = string.format("%d%%", math.floor(FullScreenLoader.CurrentProgress * 100 + 0.5))

			local badgeScale = 1 + math.clamp(disp * 0.35, -0.12, 0.22)
			springBadge.Size = UDim2.fromOffset(math.floor(44 * badgeScale + 0.5), math.floor(44 * badgeScale + 0.5))
		end
	end)
end

local function updateSpringLoader(progress, statusText)
	FullScreenLoader.TargetProgress = math.clamp(progress, 0, 1)
	if statusText then
		FullScreenLoader.StatusText = statusText
		if FullScreenLoader.Gui then
			local panel = FullScreenLoader.Gui:FindFirstChild("FullScreenBackdrop")
			local card = panel and panel:FindFirstChild("SpringCenterPanel")
			local detail = card and card:FindFirstChild("DetailLabel")
			if detail then
				detail.Text = statusText
			end
		end
	end
end

local function finishSpringLoader()
	updateSpringLoader(1, "โหลดข้อมูลและรูปแบบการทำงานทั้งหมดเสร็จสมบูรณ์")
	local started = os.clock()
	while FullScreenLoader.Active and (FullScreenLoader.CurrentProgress < 0.995 or (os.clock() - started) < Config.MinLoaderDuration) do
		task.wait(0.03)
	end
	FullScreenLoader.Active = false
	State.LoadedAll = true
	if FullScreenLoader.Gui then
		pcall(function()
			FullScreenLoader.Gui:Destroy()
		end)
		FullScreenLoader.Gui = nil
	end
end

createSpringLoadingScreen()
updateSpringLoader(0.12, "กำลังโหลดโมดูลข้อมูลและระบบเครือข่าย...")

--// 5. Safe Module & Networking Utilities
local function safeRequire(getter)
	local ok, res = pcall(function()
		return require(getter())
	end)
	return ok and res or nil
end

local Networking = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Networking")
local EggState = safeRequire(function() return ReplicatedStorage.Client.EggState end)
local AssetsData = safeRequire(function() return ReplicatedStorage.Data.Assets end)
local MutationsMod = safeRequire(function() return ReplicatedStorage.Shared.Modules.Mutations end)

local function getRemote(name)
	return Networking:FindFirstChild(name)
end

local function getCharacter()
	return LocalPlayer.Character
end

local function getHumanoid(char)
	local c = char or getCharacter()
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function getHRP(char)
	local c = char or getCharacter()
	return c and c:FindFirstChild("HumanoidRootPart")
end

--// 6. Speed & Stat Calculation
local function getBaseWalkSpeed()
	local char = getCharacter()
	local hum = getHumanoid(char)
	local speed = (hum and hum.WalkSpeed) or 16

	if RigSync.Original and RigSync.Original.Health > 0 then
		speed = math.min(speed, RigSync.Original.WalkSpeed)
	end

	local ok, treadSpeed = pcall(function()
		local stats = LocalPlayer:FindFirstChild("leaderstats")
		local speedStat = stats and stats:FindFirstChild("Speed")
		local treadUtil = require(ReplicatedStorage.Shared.Util.TreadmillUtil)
		return (speedStat and treadUtil.SpeedPowerToWalkSpeed(speedStat.Value)) or nil
	end)

	if ok and type(treadSpeed) == "number" and treadSpeed > 0 then
		speed = math.min(speed, treadSpeed)
	end

	return math.max(speed, 1)
end

local function getEffectiveMoveSpeed()
	local baseSpd = getBaseWalkSpeed()
	local capped = math.max(baseSpd * Config.SpeedCap, 8)
	if State.Carrying and State.Mult and State.Mult > 0 then
		capped = capped * math.min(Config.CarryRatio, State.Mult)
	end
	return capped
end

--// 7. Humanoid Sync & Animation Mirroring Engine
local function syncPlayerControls(hum)
	pcall(function()
		local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
		local playerModule = playerScripts and playerScripts:FindFirstChild("PlayerModule")
		if playerModule then
			local controls = require(playerModule):GetControls()
			if type(controls) == "table" then
				controls.humanoid = hum
			end
		end
	end)
end

local function refreshAnimateScript(char)
	local anim = char and char:FindFirstChild("Animate")
	if anim and anim:IsA("LocalScript") then
		task.spawn(function()
			anim.Enabled = false
			task.wait()
			anim.Enabled = true
		end)
	end
end

local function clearRigLinks()
	for _, conn in ipairs(RigSync.Links) do
		pcall(function() conn:Disconnect() end)
	end
	table.clear(RigSync.Links)
end

local GroundedStates = {
	[Enum.HumanoidStateType.Running] = true,
	[Enum.HumanoidStateType.RunningNoPhysics] = true,
	[Enum.HumanoidStateType.Landed] = true,
}

local function isGrounded(hum)
	if not hum or hum.Health <= 0 or hum.FloorMaterial == Enum.Material.Air then
		return false
	end
	return GroundedStates[hum:GetState()] == true
end

local function applyHumanoidCloneSync()
	if not Config.RigSyncEnabled then return end
	local char = getCharacter()
	local hum = getHumanoid(char)
	if not hum or hum.Health <= 0 then return end
	if RigSync.Clone and RigSync.Clone.Parent == char then return end
	if not isGrounded(hum) then return end

	local cloned = hum:Clone()
	hum.Parent = nil
	cloned.Parent = char

	if Workspace.CurrentCamera then
		Workspace.CurrentCamera.CameraSubject = cloned
	end

	syncPlayerControls(cloned)
	refreshAnimateScript(char)

	RigSync.Original = hum
	RigSync.Clone = cloned

	table.insert(RigSync.Links, hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		if cloned.Parent ~= nil then
			cloned.WalkSpeed = hum.WalkSpeed
		end
	end))

	local origAnim = hum:FindFirstChildOfClass("Animator")
	local cloneAnim = cloned:FindFirstChildOfClass("Animator")
	if origAnim and cloneAnim then
		table.insert(RigSync.Links, origAnim.AnimationPlayed:Connect(function(track)
			local animObj = track.Animation
			if not animObj or cloned.Parent == nil then return end
			local ok, loaded = pcall(function()
				return cloneAnim:LoadAnimation(animObj)
			end)
			if not ok or not loaded then return end
			pcall(function()
				loaded.Priority = track.Priority
				loaded.Looped = track.Looped
				loaded:Play(0.05, math.max(track.WeightTarget, 0.01), track.Speed)
			end)
			local stopConn
			stopConn = track.Stopped:Connect(function()
				if stopConn then stopConn:Disconnect() end
				pcall(function() loaded:Stop(0.1) end)
			end)
		end))
	end

	table.insert(RigSync.Links, cloned.Died:Connect(function()
		clearRigLinks()
		RigSync.Original, RigSync.Clone = nil, nil
		local currentChar = getCharacter()
		if currentChar and hum.Parent == nil then
			hum.Parent = currentChar
			if Workspace.CurrentCamera then
				Workspace.CurrentCamera.CameraSubject = hum
			end
			syncPlayerControls(hum)
		end
		pcall(function() cloned:Destroy() end)
		hum.Health = 0
	end))
end

local function restoreOriginalHumanoid()
	clearRigLinks()
	local char = getCharacter()
	local orig, cloned = RigSync.Original, RigSync.Clone
	RigSync.Original, RigSync.Clone = nil, nil
	if orig and cloned and char and orig.Parent == nil and cloned.Parent == char then
		orig.Parent = char
		if Workspace.CurrentCamera then
			Workspace.CurrentCamera.CameraSubject = orig
		end
		syncPlayerControls(orig)
		pcall(function() cloned:Destroy() end)
		refreshAnimateScript(char)
	end
end

local function startRigSyncLoop()
	if RigSync.Connection then return end
	applyHumanoidCloneSync()
	local acc = 0
	RigSync.Connection = RunService.Heartbeat:Connect(function(dt)
		acc += dt
		local char = getCharacter()
		local missing = not (RigSync.Clone and char and RigSync.Clone.Parent == char)
		local interval = missing and 0.25 or 3
		if acc >= interval then
			acc = 0
			applyHumanoidCloneSync()
		end
	end)

	RigSync.Added = LocalPlayer.CharacterAdded:Connect(function(newChar)
		clearRigLinks()
		RigSync.Original, RigSync.Clone = nil, nil
		task.spawn(function()
			newChar:WaitForChild("Humanoid", 10)
			task.wait(1)
			if RigSync.Connection and LocalPlayer.Character == newChar then
				applyHumanoidCloneSync()
			end
		end)
	end)
end

local function stopRigSyncLoop()
	if RigSync.Connection then
		RigSync.Connection:Disconnect()
		RigSync.Connection = nil
	end
	if RigSync.Added then
		RigSync.Added:Disconnect()
		RigSync.Added = nil
	end
	restoreOriginalHumanoid()
end

--// 8. Visual Decoy Clone & Camera / FPS Helpers
local function destroyVisualClone()
	local decoy = RigSync.VisualClone
	RigSync.VisualClone = nil
	if decoy then
		pcall(function() decoy:Destroy() end)
	end
end

local function spawnVisualClone()
	destroyVisualClone()
	local char = getCharacter()
	if not char then return nil end
	local oldArch = char.Archivable
	char.Archivable = true
	local decoy = char:Clone()
	char.Archivable = oldArch
	if decoy then
		for _, desc in ipairs(decoy:GetDescendants()) do
			if desc:IsA("LuaSourceContainer") or desc:IsA("Humanoid") then
				pcall(function() desc:Destroy() end)
			elseif desc:IsA("BasePart") then
				desc.Anchored = true
				desc.CanCollide = false
				desc.CanTouch = false
				desc.CanQuery = false
			end
		end
		decoy.Name = "VortexDecoyClone"
		decoy.Parent = Workspace
		RigSync.VisualClone = decoy
	end
	return decoy
end

local function lockCameraTemporarily()
	local cam = Workspace.CurrentCamera
	if not cam then return function() end end
	local prevType = cam.CameraType
	local prevCF = cam.CFrame
	pcall(function()
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = prevCF
	end)
	return function()
		pcall(function()
			cam.CameraType = prevType
		end)
	end
end

local fpsToken = 0
local function startFpsPulse()
	if typeof(setfpscap) ~= "function" then return end
	fpsToken += 1
	local token = fpsToken
	task.spawn(function()
		local toggle = true
		local started = os.clock()
		while fpsToken == token and (os.clock() - started) < 60 do
			local cap = toggle and Config.FpsPulse[1] or Config.FpsPulse[2]
			pcall(setfpscap, cap)
			toggle = not toggle
			task.wait(Config.FpsPulse[3])
		end
	end)
end

local function restoreFpsCap()
	fpsToken += 1
	if typeof(setfpscap) == "function" then
		pcall(setfpscap, Config.TargetFps)
	end
end

updateSpringLoader(0.32, "กำลังโหลดข้อมูลแผนที่และ Snapshot ของสนาม...")

--// 9. World Landmarks & Field Egg Snapshot System
local function getSeparationLine()
	local root = Workspace:FindFirstChild("World") or Workspace:FindFirstChild("__OBJECTS")
	local areas = root and root:FindFirstChild("Areas")
	local line = areas and areas:FindFirstChild("SeparationLine")
	if line and line:IsA("BasePart") then
		return line.Position.X, line.Position.Y
	end
	return 552.2, 67.67
end

local function getSafeTransitionPoint()
	local candidates = {
		{ { "GearGiver_Slap", "Podium" }, Vector3.new(-16.415, 21.072, -6.106) },
		{ { "World", "Machines", "RiftMachine", "Rift", "Meshes/VoidPortal_Cube.003" }, Vector3.new(-26.776, 1.75, 18.665) },
		{ { "__OBJECTS", "Machines", "RiftMachine", "Rift", "Meshes/VoidPortal_Cube.003" }, Vector3.new(-26.776, 1.75, 18.665) },
	}
	for _, entry in ipairs(candidates) do
		local cur = Workspace
		for _, seg in ipairs(entry[1]) do
			cur = cur and cur:FindFirstChild(seg) or nil
		end
		if cur and cur:IsA("BasePart") then
			return cur.CFrame:PointToWorldSpace(entry[2])
		end
	end
	return Vector3.new(528.7, 70.57, -364.11)
end

local function getFieldEggSnapshot()
	local recordsOut = {}
	local ok, res = pcall(function()
		local rf = getRemote("RF/EggWorld/AskFieldEggSnapshot")
		return rf and rf:InvokeServer() or nil
	end)
	local raw = (ok and type(res) == "table" and res.Records) or nil
	if type(raw) ~= "table" then return recordsOut end

	for _, rec in pairs(raw) do
		if type(rec) == "table"
			and type(rec.Uid) == "string"
			and (rec.State == "Slot" or rec.State == "Dropped")
			and typeof(rec.BottomCFrame) == "CFrame" then
			recordsOut[#recordsOut + 1] = rec
		end
	end
	return recordsOut
end

local function findEggPositionByUid(uid)
	for _, rec in ipairs(getFieldEggSnapshot()) do
		if rec.Uid == uid then
			return rec.BottomCFrame.Position
		end
	end
	return nil
end

local function resolveLiveEggPosition(uid, cache)
	local model = Workspace:FindFirstChild(uid)
	local clientSlots = Workspace:FindFirstChild("AreaEggSlotsClient")
	model = model or (clientSlots and clientSlots:FindFirstChild(uid))
	if model then
		local ok, pivot = pcall(function() return model:GetPivot().Position end)
		if ok and pivot then
			cache.Pos, cache.At = pivot, os.clock()
			return pivot
		end
	end
	if (os.clock() - (cache.At or 0)) >= 0.5 then
		cache.At = os.clock()
		cache.Pos = findEggPositionByUid(uid) or cache.Pos
	end
	return cache.Pos
end

local function findNearestCarryPrompt(origin, maxDist)
	local bestPrompt, bestDist = nil, maxDist
	for _, obj in ipairs(Workspace:GetChildren()) do
		if obj.Name == "SmartPromptPart" and obj:IsA("BasePart") then
			local prompt = obj:FindFirstChild("CarryAreaEgg")
			if prompt and prompt:IsA("ProximityPrompt") then
				local dist = (obj.Position - origin).Magnitude
				if dist < bestDist then
					bestPrompt, bestDist = prompt, dist
				end
			end
		end
	end
	return bestPrompt
end

local function isEggWeldedToChar(uid)
	local char = getCharacter()
	if type(uid) ~= "string" or not char then return false end
	local eggModel = Workspace:FindFirstChild(uid)
	if not eggModel then return false end

	for _, desc in ipairs(eggModel:GetDescendants()) do
		if desc:IsA("WeldConstraint") or desc:IsA("JointInstance") then
			local ok, p0, p1 = pcall(function() return desc.Part0, desc.Part1 end)
			if ok and ((p0 and p0:IsDescendantOf(char)) or (p1 and p1:IsDescendantOf(char))) then
				return true
			end
		end
	end
	return false
end

--// 10. Value Valuation & Egg Ranking System
local function computeEggValue(record)
	local dir = (type(AssetsData) == "table" and AssetsData.Directory) or nil
	local entry = (type(dir) == "table" and dir[tostring(record.AssetCategory)]) or nil
	local info = {
		Uid = record.Uid,
		State = record.State,
		Position = record.BottomCFrame.Position,
		Category = tostring(record.AssetCategory),
		Name = tostring(record.AssetCategory),
		Icon = "",
		Rarity = 0,
		Scale = tonumber(record.AssetScale) or 1,
		Value = 0,
	}

	if type(entry) == "table" then
		info.Name = tostring(entry.DisplayName or record.AssetCategory)
		local icon = entry.Icon
		if icon ~= nil and tostring(icon) ~= "" then
			local s = tostring(icon)
			info.Icon = tonumber(s) and ("rbxassetid://" .. s) or s
		end
		if type(entry.Rarity) == "table" then
			info.Rarity = tonumber(entry.Rarity.RarityNumber or entry.Rarity.Rank) or 0
		end
		local scale = info.Scale
		local scaleMult = (scale > 5) and (((scale / 5) ^ 1.2) * 19.637875755794113) or (scale ^ 1.85)
		local mutMult = 1
		if type(MutationsMod) == "table" and type(MutationsMod.EarningsFor) == "function" then
			local ok, val = pcall(MutationsMod.EarningsFor, (type(record.Mutations) == "table" and record.Mutations) or {})
			if ok and type(val) == "number" then
				mutMult = val
			end
		end
		info.Value = (tonumber(entry.EarningRate) or 0) * scaleMult * mutMult
	end

	return info
end

local function formatRate(num)
	local tiers = {
		{ 999999995904, "T" },
		{ 1000000000, "B" },
		{ 1000000, "M" },
		{ 1000, "K" },
	}
	for _, tier in ipairs(tiers) do
		if num >= tier[1] then
			return string.format("$%.2f%s/s", num / tier[1], tier[2])
		end
	end
	return string.format("$%d/s", math.floor(num + 0.5))
end

local function scanAllFieldEggsRanked()
	local ranked = {}
	for _, rec in ipairs(getFieldEggSnapshot()) do
		ranked[#ranked + 1] = computeEggValue(rec)
	end
	table.sort(ranked, function(a, b)
		return a.Value > b.Value
	end)
	return ranked
end

local function getBestFieldEgg()
	local ranked = scanAllFieldEggsRanked()
	return ranked[1]
end

--// 11. Hazard / Portal Avoidance & Ground Raycast
local cachedBoxes, lastBoxScan = {}, 0
local function getHazardBoxes()
	if not Config.SmartAvoid then return {} end
	if (os.clock() - lastBoxScan) < 1 then return cachedBoxes end
	lastBoxScan = os.clock()

	local boxes = {}
	local function addBox(obj)
		local ok, cf, size = pcall(function()
			if obj:IsA("Model") then return obj:GetBoundingBox()
			elseif obj:IsA("BasePart") then return obj.CFrame, obj.Size end
		end)
		if ok and cf and size then
			local half = Vector3.new(math.abs(size.X), 0, math.abs(size.Z)) * 0.5
			local worldHalf = (cf - cf.Position):VectorToWorldSpace(half)
			local rx = math.max(math.abs(worldHalf.X), half.X, half.Z)
			local rz = math.max(math.abs(worldHalf.Z), half.X, half.Z)
			boxes[#boxes + 1] = {
				MinX = cf.Position.X - rx,
				MaxX = cf.Position.X + rx,
				MinZ = cf.Position.Z - rz,
				MaxZ = cf.Position.Z + rz,
			}
		end
	end

	local function isHazardName(name)
		if name == "ScrambleLocalVisuals" or name == "DrScrambleEvent" then return false end
		local low = string.lower(name)
		return string.find(low, "portal", 1, true)
			or string.find(low, "teleport", 1, true)
			or string.find(low, "mech", 1, true)
			or string.find(low, "arena", 1, true)
			or string.find(low, "scramble", 1, true)
	end

	for _, child in ipairs(Workspace:GetChildren()) do
		if (child:IsA("Model") or child:IsA("BasePart") or child:IsA("Folder")) and isHazardName(child.Name) then
			if child:IsA("Folder") then
				for _, sub in ipairs(child:GetChildren()) do addBox(sub) end
			else
				addBox(child)
			end
		end
	end

	local worldFolder = Workspace:FindFirstChild("World")
	local buildFolder = worldFolder and worldFolder:FindFirstChild("Build")
	if buildFolder then
		for _, child in ipairs(buildFolder:GetChildren()) do
			if isHazardName(child.Name) then
				for _, sub in ipairs(child:GetChildren()) do addBox(sub) end
			end
		end
	end

	cachedBoxes = boxes
	return boxes
end

local function steerAroundHazards(origin, target)
	if not Config.SmartAvoid then return target end
	for _, box in ipairs(getHazardBoxes()) do
		local minX, maxX = box.MinX - 12, box.MaxX + 12
		local minZ, maxZ = box.MinZ - 12, box.MaxZ + 12
		local inside = (origin.X >= minX and origin.X <= maxX and origin.Z >= minZ and origin.Z <= maxZ)
		if not inside then
			local t0, t1, hit = 0, 1, true
			for _, axis in ipairs({
				{ origin.X, target.X - origin.X, minX, maxX },
				{ origin.Z, target.Z - origin.Z, minZ, maxZ },
			}) do
				local p, d, lo, hi = axis[1], axis[2], axis[3], axis[4]
				if math.abs(d) < 1e-6 then
					if p < lo or p > hi then hit = false end
				else
					local s1, s2 = (lo - p) / d, (hi - p) / d
					if s1 > s2 then s1, s2 = s2, s1 end
					t0, t1 = math.max(t0, s1), math.min(t1, s2)
					if t0 > t1 then hit = false end
				end
			end
			if hit then
				local z1, z2 = minZ - 2, maxZ + 2
				local pickZ = (math.abs(origin.Z - z1) <= math.abs(origin.Z - z2)) and z1 or z2
				if pickZ < -440 or pickZ > -290 then
					pickZ = (pickZ == z1) and z2 or z1
				end
				local pickX = (math.abs(origin.X - minX) <= math.abs(origin.X - maxX)) and minX or maxX
				if math.abs(origin.Z - pickZ) < 3 then
					pickX = (math.abs(target.X - minX) <= math.abs(target.X - maxX)) and minX or maxX
				end
				return Vector3.new(pickX, target.Y, pickZ)
			end
		end
	end
	return target
end

local function resolveGroundY(pos, fallbackY)
	local resolved = fallbackY
	pcall(function()
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { getCharacter() }
		params.IgnoreWater = true
		local hit = Workspace:Raycast(pos + Vector3.new(0, 60, 0), Vector3.new(0, -140, 0), params)
		if hit and hit.Material ~= Enum.Material.Water and math.abs(hit.Position.Y - fallbackY) < 40 then
			resolved = hit.Position.Y + 3.5
		end
	end)
	return resolved
end

updateSpringLoader(0.56, "กำลังโหลดระบบเคลื่อนที่ Hop/Climb การจับวัตถุ และการกู้คืน...")

--// 12. Movement, Hop/Climb, Carry, Grab & Recovery Engine
local function triggerCarry(uid)
	if type(uid) == "string" and type(EggState) == "table" and type(EggState.CarryFieldEgg) == "function" then
		pcall(EggState.CarryFieldEgg, uid)
	end
end

local function triggerDrop()
	if type(EggState) == "table" and type(EggState.DropFieldEgg) == "function" then
		pcall(EggState.DropFieldEgg, "PlayerRequest")
	end
end

local function safeTeleport(pos)
	local hrp = getHRP()
	if not hrp then return end
	pcall(function()
		hrp.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(90), 0)
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end)
end

local function hopTraverse(targetPos, maxSteps)
	local hrp = getHRP()
	if not hrp then return false end
	local steps = maxSteps or Config.HopRetries
	for attempt = 1, steps do
		if State.Cancel then return false end
		hrp = getHRP()
		if not hrp then return false end

		local current = hrp.Position
		local delta = targetPos - current
		local flat = Vector3.new(delta.X, 0, delta.Z)
		if flat.Magnitude <= Config.ArriveRadius and math.abs(delta.Y) <= Config.LandOffset then
			return true
		end

		local stepDist = math.clamp(flat.Magnitude * (1 / math.max(Config.HopRatio, 1.05)), Config.HopMin, Config.Height)
		local dir = (flat.Magnitude > 0.01) and flat.Unit or Vector3.zero
		local climbY = math.clamp(delta.Y * Config.ClimbShare, -Config.HopLift, Config.HopLift)
		local groundY = resolveGroundY(current + dir * math.min(flat.Magnitude, stepDist), current.Y + climbY)
		local nextPos = Vector3.new(
			current.X + dir.X * math.min(flat.Magnitude, stepDist),
			math.max(groundY, current.Y + climbY * 0.5),
			current.Z + dir.Z * math.min(flat.Magnitude, stepDist)
		)
		nextPos = steerAroundHazards(current, nextPos)

		safeTeleport(nextPos + Vector3.new(0, 2.5, 0))
		task.wait(Config.LandSettle)
		local gap = math.clamp(Config.HopGap, Config.HopGapMin, Config.HopGapMax)
		task.wait(gap)
	end
	return false
end

local function navigateToEgg(uid, targetPos)
	local sepX = getSeparationLine()
	local safePt = getSafeTransitionPoint()
	local char = getCharacter()
	local hum = getHumanoid(char)
	if hum then
		hum.PlatformStand = false
		if char:FindFirstChildWhichIsA("Tool") then
			pcall(function() hum:UnequipTools() end)
		end
	end

	local hrp = getHRP()
	if not hrp then return false end

	local phase = "field"
	if hrp.Position.X < (sepX - 2) and Vector3.new(hrp.Position.X - safePt.X, 0, hrp.Position.Z - safePt.Z).Magnitude > Config.SafeZoneRadius then
		phase = "safe"
	end

	local startClock = os.clock()
	local stuckClock = os.clock()
	local lastPos = hrp.Position
	local lastGrabTry = 0

	recordEvent("Navigate", uid)
	while (os.clock() - startClock) < 120 and not State.Cancel do
		hrp = getHRP()
		if not hrp then return false end

		local flatDist = Vector3.new(targetPos.X - hrp.Position.X, 0, targetPos.Z - hrp.Position.Z)
		if phase == "field" and flatDist.Magnitude <= Config.ArriveRadius then
			break
		end

		local waypoint = targetPos
		if phase == "safe" then
			if Vector3.new(safePt.X - hrp.Position.X, 0, safePt.Z - hrp.Position.Z).Magnitude <= 6 then
				phase = "field"
			else
				waypoint = safePt
			end
		end

		local steered = steerAroundHazards(hrp.Position, waypoint)
		local stepVec = Vector3.new(steered.X - hrp.Position.X, 0, steered.Z - hrp.Position.Z)
		local dir = (stepVec.Magnitude > 0.01) and stepVec.Unit or Vector3.zero
		local moveSpeed = math.max(getBaseWalkSpeed() * Config.SpeedCap, 8)
		local vel = dir * math.min(moveSpeed, stepVec.Magnitude / 0.05)

		pcall(function()
			hrp.AssemblyLinearVelocity = Vector3.new(vel.X, hrp.AssemblyLinearVelocity.Y, vel.Z)
			if hum and dir.Magnitude > 0 then
				hum:Move(dir, false)
			end
		end)

		if Config.StuckRecovery and (os.clock() - stuckClock) >= Config.StuckTimeout then
			if (hrp.Position - lastPos).Magnitude < Config.StuckThreshold and hum and flatDist.Magnitude > 15 then
				State.RecoveryCount += 1
				pcall(function() hum.Jump = true end)
				if flatDist.Magnitude > Config.HopMin then
					hopTraverse(steered, 2)
				end
			end
			lastPos, stuckClock = hrp.Position, os.clock()
		end

		if phase == "field" and flatDist.Magnitude <= 9 and (os.clock() - lastGrabTry) > 0.1 then
			lastGrabTry = os.clock()
			triggerCarry(uid)
		end

		RunService.Heartbeat:Wait()
	end

	hrp = getHRP()
	if hrp then
		pcall(function()
			hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
			if hum then hum:Move(Vector3.zero, false) end
		end)
	end

	return State.Carrying or (hrp ~= nil and Vector3.new(targetPos.X - hrp.Position.X, 0, targetPos.Z - hrp.Position.Z).Magnitude <= 6)
end

local function grabEggLoop(uid, timeout)
	local posCache = { At = 0, Pos = nil }
	local elapsed, tickAcc = 0, 1
	recordEvent("GrabLoop", uid)

	while not State.Carrying and elapsed < timeout and not State.Cancel do
		local hrp = getHRP()
		local targetPos = resolveLiveEggPosition(uid, posCache)
		local dt = math.max(RunService.Heartbeat:Wait(), 1 / 240)
		elapsed += dt
		tickAcc += dt

		if hrp and targetPos then
			local steered = steerAroundHazards(hrp.Position, targetPos)
			local delta = steered - hrp.Position
			if delta.Magnitude > 2 then
				local maxSpd = math.max(getBaseWalkSpeed() * Config.SpeedCap, 16)
				local vel = delta / math.max(0.08, dt)
				if vel.Magnitude > maxSpd then
					vel = vel.Unit * maxSpd
				end
				pcall(function()
					hrp.AssemblyLinearVelocity = vel + Vector3.new(0, Workspace.Gravity * dt * 0.5, 0)
					hrp.AssemblyAngularVelocity = Vector3.zero
				end)
			end

			if tickAcc >= Config.GrabInterval then
				tickAcc = 0
				local prompt = findNearestCarryPrompt(targetPos - Vector3.new(0, 3, 0), 10)
				if prompt and typeof(fireproximityprompt) == "function" then
					pcall(function() prompt.HoldDuration = 0 end)
					pcall(fireproximityprompt, prompt)
				end
				task.spawn(triggerCarry, uid)
			end
		end
	end

	local hrp = getHRP()
	if hrp then
		pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end)
	end
	return State.Carrying and (State.Uid == uid)
end

local function recoverDroppedEgg(uid)
	if not Config.AutoRegrab then return false end
	if State.Carrying then return true end

	local hrp = getHRP()
	local eggPos = findEggPositionByUid(uid)
	State.RegrabCount += 1

	if hrp and eggPos and Vector3.new(hrp.Position.X - eggPos.X, 0, hrp.Position.Z - eggPos.Z).Magnitude > Config.RegrabFar then
		logInfo("Egg fell far behind, teleporting onto it")
		recordEvent("WarpRegrab", uid)
		safeTeleport(eggPos + Vector3.new(0, 3, 0))
	else
		logInfo("Egg fell close, taking it back")
		recordEvent("QuickRegrab", uid)
	end

	return grabEggLoop(uid, 3)
end

local function executeBestEggCycle()
	if State.Busy then return false end
	State.Busy = true
	State.Cancel = false

	local ok, result = pcall(function()
		local best = getBestFieldEgg()
		if not best then
			recordEvent("Idle", "No field eggs available")
			return false
		end

		recordEvent("TargetEgg", string.format("%s (%s)", best.Name, formatRate(best.Value)))
		local reached = navigateToEgg(best.Uid, best.Position)
		if not reached then
			return false
		end

		local grabbed = grabEggLoop(best.Uid, 5)
		if not grabbed then
			return false
		end

		-- เดินทางกลับจุดปลอดภัย / เส้นแบ่งเขตพร้อมถือไข่
		local safePt = getSafeTransitionPoint()
		navigateToEgg(best.Uid, safePt)
		task.wait(Config.DropDelay)
		triggerDrop()
		return true
	end)

	State.Busy = false
	if not ok then
		logInfo("Cycle error: " .. tostring(result), true)
		return false
	end
	return result == true
end

updateSpringLoader(0.78, "กำลังเชื่อมต่อ Event Listeners, RigSync และ Watchdog...")

--// 13. Remote & Carry State Listeners
if type(EggState) == "table" and type(EggState.CarryChanged) == "table" and type(EggState.CarryChanged.Connect) == "function" then
	EggState.CarryChanged:Connect(function(payload)
		local carrying = (type(payload) == "table") and (payload.IsCarrying == true)
		if carrying and payload.GuardDisabled == true then
			carrying = false
		end
		State.GuessedDrop = false
		if carrying then
			State.HeldSeen = os.clock()
		end
		if carrying and type(payload.Uid) == "string" then
			State.Uid = payload.Uid
			local mult = tonumber(payload.SpeedMultiplier)
			if mult and mult > 0 then
				State.Mult = mult
			end
			recordEvent("CarryStart", payload.Uid)
		elseif not carrying and State.Carrying then
			recordEvent("CarryEnd", State.Uid)
		end
		State.Carrying = carrying
	end)
end

pcall(function()
	local redeemRemote = getRemote("RE/EggWorld/FieldEggRedeemVerdict")
	if redeemRemote then
		redeemRemote.OnClientEvent:Connect(function()
			State.Delivered = os.clock()
			State.DeliveredCount += 1
			recordEvent("Redeem", State.Uid)
		end)
	end
end)

pcall(function()
	local syncRemote = getRemote("RE/RigSync/Refresh")
	if syncRemote then
		syncRemote.OnClientEvent:Connect(function(payload)
			if type(payload) == "table" and payload.Action == "Relocate" then
				State.PulledAt = os.clock()
				recordEvent("Relocate", payload.Action)
			end
		end)
	end
end)

--// 14. Background Watchdog, AutoCycle & Anti-AFK Threads
task.spawn(function()
	while true do
		task.wait(0.2)
		if not State.Carrying then
			if State.GuessedDrop and isEggWeldedToChar(State.Uid) then
				State.GuessedDrop, State.Carrying, State.HeldSeen = false, true, os.clock()
			end
		elseif isEggWeldedToChar(State.Uid) then
			State.HeldSeen = os.clock()
		elseif (os.clock() - State.HeldSeen) > 0.8 then
			State.Carrying, State.GuessedDrop = false, true
			if Config.AutoRegrab and State.Uid then
				task.spawn(recoverDroppedEgg, State.Uid)
			end
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(Config.CycleInterval)
		if Config.AutoCycle and State.LoadedAll and State.Authorized and not State.Busy then
			executeBestEggCycle()
		end
	end
end)

LocalPlayer.Idled:Connect(function()
	if not Config.AntiAFK then return end
	pcall(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
end)

startRigSyncLoop()

--// 15. Public Engine API (Preserves Existing UI)
local VortexAPI = {}
VortexAPI.Name = "VORTEX ENGINE // DELTA EDITION"
VortexAPI.Author = "Upgraded by AI Collaborator (Original Base Adapted)"
VortexAPI.KeySystemRef = "VortexKeySystem"
VortexAPI.Config = Config
VortexAPI.State = State

function VortexAPI.IsAuthorized()
	return checkExternalKeyGate()
end

function VortexAPI.GetAllEggs()
	return scanAllFieldEggsRanked()
end

function VortexAPI.GetBestEgg()
	return getBestFieldEgg()
end

function VortexAPI.FormatRate(val)
	return formatRate(val)
end

function VortexAPI.GrabEgg(uid, timeout)
	return grabEggLoop(uid, timeout or 5)
end

function VortexAPI.NavigateToEgg(uid)
	local pos = findEggPositionByUid(uid)
	if not pos then return false end
	return navigateToEgg(uid, pos)
end

function VortexAPI.HopTo(pos, maxSteps)
	return hopTraverse(pos, maxSteps)
end

function VortexAPI.RecoverEgg(uid)
	return recoverDroppedEgg(uid or State.Uid)
end

function VortexAPI.DropEgg()
	triggerDrop()
end

function VortexAPI.ExecuteCycle()
	return executeBestEggCycle()
end

function VortexAPI.SetAutoCycle(enabled)
	Config.AutoCycle = enabled and true or false
end

function VortexAPI.CancelCycle()
	State.Cancel = true
end

function VortexAPI.TeleportSafe(pos)
	safeTeleport(pos)
end

function VortexAPI.ResolveGround(pos, fallbackY)
	return resolveGroundY(pos, fallbackY or 0)
end

function VortexAPI.SpawnDecoy()
	return spawnVisualClone()
end

function VortexAPI.DestroyDecoy()
	destroyVisualClone()
end

function VortexAPI.LockCamera()
	return lockCameraTemporarily()
end

function VortexAPI.PulseFps()
	startFpsPulse()
end

function VortexAPI.ResetFps()
	restoreFpsCap()
end

function VortexAPI.SetRigSync(enabled)
	Config.RigSyncEnabled = enabled and true or false
	if Config.RigSyncEnabled then
		startRigSyncLoop()
	else
		stopRigSyncLoop()
	end
end

function VortexAPI.GetSummary()
	local best = getBestFieldEgg()
	local uptime = math.floor(os.clock() - State.StartTime)
	return {
		Script = VortexAPI.Name,
		Author = VortexAPI.Author,
		Authorized = State.Authorized,
		LoadedAll = State.LoadedAll,
		UptimeSec = uptime,
		DeliveredCount = State.DeliveredCount,
		RegrabCount = State.RegrabCount,
		RecoveryCount = State.RecoveryCount,
		BestEgg = best and string.format("%s (%s)", best.Name, formatRate(best.Value)) or "None",
		LastAction = State.LastAction,
	}
end

getgenv().VortexDelta = VortexAPI

updateSpringLoader(0.95, "กำลังซิงค์ข้อมูลและเปิดใช้งาน VortexDelta API...")
finishSpringLoader()

logInfo("Main engine online (540+ lines). Key system separated.")
