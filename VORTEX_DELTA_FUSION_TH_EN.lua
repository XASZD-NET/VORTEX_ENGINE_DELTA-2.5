local _version = "1.6.66"
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/download/" .. _version .. "/main.lua"))()

-- ธีมสีแดง (Red Theme)
WindUI:AddTheme({
    Name = "Red",
    Accent = Color3.fromHex("#991b1b"),
    Background = Color3.fromHex("#180909"),
    Outline = Color3.fromHex("#ef4444"),
    Text = Color3.fromHex("#fff5f5"),
    Placeholder = Color3.fromHex("#fca5a5"),
    Button = Color3.fromHex("#b91c1c"),
    Icon = Color3.fromHex("#f87171"),
})

-- ==========================================
-- [1] โค้ดฐานหลัก (Core Engine & Services)
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer

local ConfigData = {
    SpeedCap = 1.15,
    HopRatio = 1.515,
    HopMin = 40,
    HopGap = 0.06,
    HopGapMin = 0.06,
    HopGapMax = 0.2,
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
    EasyRatio = 1.3
}
local FpsCycle = { 60, 30, 0.15 }

local function safeRequire(getter)
    local ok, mod = pcall(function()
        return require(getter())
    end)
    return (ok and mod) or nil
end

-- โหลดโมดูลเฉพาะแมพแบบปลอดภัย (ไม่ Error ในแมพอื่น)
local Packages = ReplicatedStorage:FindFirstChild("Packages")
local Networking = Packages and Packages:FindFirstChild("Networking")
local EggState = safeRequire(function() return ReplicatedStorage.Client.EggState end)
local AssetsData = safeRequire(function() return ReplicatedStorage.Data.Assets end)
local MutationsMod = safeRequire(function() return ReplicatedStorage.Shared.Modules.Mutations end)

local function getNet(name)
    return Networking and Networking:FindFirstChild(name)
end

local function getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- ระบบ Clone Humanoid กันรีเซ็ต WalkSpeed (v15 - v25)
local HumState = { Original = nil, Clone = nil, Links = {}, Connection = nil, Added = nil }

local function getBaseSpeed()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local spd = (hum and hum.WalkSpeed) or 16
    if HumState.Original and HumState.Original.Health > 0 then
        spd = math.min(spd, HumState.Original.WalkSpeed)
    end
    local ok, customSpd = pcall(function()
        local ls = LocalPlayer:FindFirstChild("leaderstats")
        local spObj = ls and ls:FindFirstChild("Speed")
        local util = require(ReplicatedStorage.Shared.Util.TreadmillUtil)
        return (spObj and util.SpeedPowerToWalkSpeed(spObj.Value)) or nil
    end)
    if ok and type(customSpd) == "number" and customSpd > 0 then
        spd = math.min(spd, customSpd)
    end
    return spd
end

local function bindControls(hum)
    pcall(function()
        local ps = LocalPlayer:FindFirstChild("PlayerScripts")
        local pm = ps and ps:FindFirstChild("PlayerModule")
        if pm then
            local controls = require(pm):GetControls()
            if type(controls) == "table" then
                controls.humanoid = hum
            end
        end
    end)
end

local function resetAnimate(char)
    local anim = char and char:FindFirstChild("Animate")
    if anim and anim:IsA("LocalScript") then
        task.spawn(function()
            anim.Enabled = false
            task.wait()
            anim.Enabled = true
        end)
    end
end

local function clearHumLinks()
    for _, conn in ipairs(HumState.Links) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(HumState.Links)
end

local GroundedStates = {
    [Enum.HumanoidStateType.Running] = true,
    [Enum.HumanoidStateType.RunningNoPhysics] = true,
    [Enum.HumanoidStateType.Landed] = true
}

local function isGrounded(hum)
    if not hum or hum.Health <= 0 or hum.FloorMaterial == Enum.Material.Air then
        return false
    end
    return GroundedStates[hum:GetState()] == true
end

local function cloneHumanoid()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    if HumState.Clone and HumState.Clone.Parent == char then return end
    if not isGrounded(hum) then return end

    local cloned = hum:Clone()
    hum.Parent = nil
    cloned.Parent = char
    workspace.CurrentCamera.CameraSubject = cloned
    bindControls(cloned)
    resetAnimate(char)

    HumState.Original = hum
    HumState.Clone = cloned

    table.insert(HumState.Links, hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if cloned.Parent ~= nil then
            cloned.WalkSpeed = hum.WalkSpeed
        end
    end))

    local origAnim = hum:FindFirstChildOfClass("Animator")
    local cloneAnim = cloned:FindFirstChildOfClass("Animator")
    if origAnim and cloneAnim then
        table.insert(HumState.Links, origAnim.AnimationPlayed:Connect(function(track)
            local animObj = track.Animation
            if not animObj or cloned.Parent == nil then return end
            local ok, loaded = pcall(function() return cloneAnim:LoadAnimation(animObj) end)
            if not ok or not loaded then return end
            pcall(function()
                loaded.Priority = track.Priority
                loaded.Looped = track.Looped
                loaded:Play(0.05, math.max(track.WeightTarget, 0.01), track.Speed)
            end)
            local stopConn
            stopConn = track.Stopped:Connect(function()
                stopConn:Disconnect()
                pcall(function() loaded:Stop(0.1) end)
            end)
        end))
    end

    table.insert(HumState.Links, cloned.Died:Connect(function()
        clearHumLinks()
        HumState.Original, HumState.Clone = nil, nil
        local c = LocalPlayer.Character
        if c and hum.Parent == nil then
            hum.Parent = c
            workspace.CurrentCamera.CameraSubject = hum
            bindControls(hum)
        end
        pcall(function() cloned:Destroy() end)
        hum.Health = 0
    end))
end

local function restoreHumanoid()
    clearHumLinks()
    local char = LocalPlayer.Character
    local orig, cloned = HumState.Original, HumState.Clone
    HumState.Original, HumState.Clone = nil, nil
    if orig and cloned and char and orig.Parent == nil and cloned.Parent == char then
        orig.Parent = char
        workspace.CurrentCamera.CameraSubject = orig
        bindControls(orig)
        pcall(function() cloned:Destroy() end)
        resetAnimate(char)
    end
end

local function enableHumBypass()
    cloneHumanoid()
    local elapsed = 0
    HumState.Connection = RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        local char = LocalPlayer.Character
        local missing = not (HumState.Clone and char and HumState.Clone.Parent == char)
        if ((missing and 0.25) or 3) <= elapsed then
            elapsed = 0
            cloneHumanoid()
        end
    end)
    HumState.Added = LocalPlayer.CharacterAdded:Connect(function(char)
        clearHumLinks()
        HumState.Original, HumState.Clone = nil, nil
        task.spawn(function()
            char:WaitForChild("Humanoid", 10)
            task.wait(1)
            if HumState.Connection and LocalPlayer.Character == char then
                cloneHumanoid()
            end
        end)
    end)
end

local function disableHumBypass()
    if HumState.Connection then HumState.Connection:Disconnect(); HumState.Connection = nil end
    if HumState.Added then HumState.Added:Disconnect(); HumState.Added = nil end
    restoreHumanoid()
end

-- ระบบ Egg & Auto Carry (v26 - v34)
local CarryState = {
    Carrying = false,
    Uid = nil,
    Delivered = 0,
    Busy = false,
    Cancel = false,
    Mult = 1,
    PulledAt = 0,
    HeldSeen = 0,
    GuessedDrop = false
}

if type(EggState) == "table" and type(EggState.CarryChanged) == "table" then
    pcall(function()
        EggState.CarryChanged:Connect(function(data)
            local isCarry = type(data) == "table" and data.IsCarrying == true
            if isCarry and data.GuardDisabled == true then
                isCarry = false
            end
            CarryState.GuessedDrop = false
            if isCarry then
                CarryState.HeldSeen = os.clock()
            end
            if isCarry and type(data.Uid) == "string" then
                CarryState.Uid = data.Uid
                local mult = tonumber(data.SpeedMultiplier)
                if mult and mult > 0 then
                    CarryState.Mult = mult
                end
            end
            CarryState.Carrying = isCarry
        end)
    end)
end

pcall(function()
    local re = getNet("RE/EggWorld/FieldEggRedeemVerdict")
    if re then re.OnClientEvent:Connect(function() CarryState.Delivered = os.clock() end) end
end)

pcall(function()
    local re = getNet("RE/RigSync/Refresh")
    if re then
        re.OnClientEvent:Connect(function(data)
            if type(data) == "table" and data.Action == "Relocate" then
                CarryState.PulledAt = os.clock()
            end
        end)
    end
end)

local function carryEgg(uid)
    if type(uid) == "string" and type(EggState) == "table" and type(EggState.CarryFieldEgg) == "function" then
        pcall(EggState.CarryFieldEgg, uid)
    end
end

local function dropEgg()
    if type(EggState) == "table" and type(EggState.DropFieldEgg) == "function" then
        pcall(EggState.DropFieldEgg, "PlayerRequest")
    end
end

local function findNearestPrompt(pos, maxDist)
    local bestPrompt, bestDist = nil, maxDist
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == "SmartPromptPart" and obj:IsA("BasePart") then
            local prompt = obj:FindFirstChild("CarryAreaEgg")
            if prompt and prompt:IsA("ProximityPrompt") then
                local dist = (obj.Position - pos).Magnitude
                if dist < bestDist then
                    bestPrompt, bestDist = prompt, dist
                end
            end
        end
    end
    return bestPrompt
end

local function getEggSnapshots()
    local list = {}
    local rf = getNet("RF/EggWorld/AskFieldEggSnapshot")
    if not rf then return list end
    local ok, res = pcall(function() return rf:InvokeServer() end)
    local records = (ok and type(res) == "table" and res.Records) or nil
    if type(records) ~= "table" then return list end
    for _, rec in pairs(records) do
        if type(rec) == "table" and type(rec.Uid) == "string" and (rec.State == "Slot" or rec.State == "Dropped") and typeof(rec.BottomCFrame) == "CFrame" then
            list[#list + 1] = rec
        end
    end
    return list
end

local function parseEggInfo(rec)
    local dir = (type(AssetsData) == "table" and AssetsData.Directory) or nil
    local item = (type(dir) == "table" and dir[tostring(rec.AssetCategory)]) or nil
    local info = {
        Uid = rec.Uid,
        Category = tostring(rec.AssetCategory),
        Name = tostring(rec.AssetCategory),
        Value = 0
    }
    if type(item) == "table" then
        info.Name = tostring(item.DisplayName or rec.AssetCategory)
        local scale = tonumber(rec.AssetScale) or 1
        local scaleMult = (scale > 5 and (((scale / 5) ^ 1.2) * 19.637875755794113)) or (scale ^ 1.85)
        local mutMult = 1
        if type(MutationsMod) == "table" and type(MutationsMod.EarningsFor) == "function" then
            local ok, mVal = pcall(MutationsMod.EarningsFor, (type(rec.Mutations) == "table" and rec.Mutations) or {})
            if ok and type(mVal) == "number" then
                mutMult = mVal
            end
        end
        info.Value = (tonumber(item.EarningRate) or 0) * scaleMult * mutMult
    end
    return info
end

local function formatRate(val)
    local units = { { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
    for _, u in ipairs(units) do
        if val >= u[1] then
            return string.format("$%.2f%s/s", val / u[1], u[2])
        end
    end
    return string.format("$%d/s", math.floor(val + 0.5))
end

-- ระบบ FPS Toggle & Visual Clone (v37 - v42)
local fpsToken = 0
local function startFpsToggle()
    if typeof(setfpscap) ~= "function" then return end
    fpsToken += 1
    local myToken = fpsToken
    task.spawn(function()
        local high = true
        local start = os.clock()
        while fpsToken == myToken and (os.clock() - start) < 60 do
            pcall(setfpscap, (high and FpsCycle[1]) or FpsCycle[2])
            high = not high
            task.wait(FpsCycle[3])
        end
    end)
end

local function stopFpsToggle()
    fpsToken += 1
    if typeof(setfpscap) == "function" then
        pcall(setfpscap, 240)
    end
end

local decoyClone = nil
local function clearDecoy()
    if decoyClone then
        pcall(function() decoyClone:Destroy() end)
        decoyClone = nil
    end
end

local function spawnDecoy()
    clearDecoy()
    local char = LocalPlayer.Character
    if not char then return end
    local prevArch = char.Archivable
    char.Archivable = true
    local cloned = char:Clone()
    char.Archivable = prevArch
    if cloned then
        for _, d in ipairs(cloned:GetDescendants()) do
            if d:IsA("LuaSourceContainer") or d:IsA("Humanoid") then
                pcall(function() d:Destroy() end)
            elseif d:IsA("BasePart") then
                d.Anchored = true
                d.CanCollide = false
                d.CanTouch = false
                d.CanQuery = false
            end
        end
        cloned.Name = "VortexClone"
        cloned.Parent = workspace
        decoyClone = cloned
    end
end

-- ระบบหลบสิ่งกีดขวาง & เคลื่อนที่อัตโนมัติ (v43 - v54)
local function getSafeZonePos()
    for _, entry in ipairs({
        { { "GearGiver_Slap", "Podium" }, Vector3.new(-16.415, 21.072, -6.106) },
        { { "World", "Machines", "RiftMachine", "Rift", "Meshes/VoidPortal_Cube.003" }, Vector3.new(-26.776, 1.75, 18.665) },
        { { "__OBJECTS", "Machines", "RiftMachine", "Rift", "Meshes/VoidPortal_Cube.003" }, Vector3.new(-26.776, 1.75, 18.665) }
    }) do
        local obj = workspace
        for _, childName in ipairs(entry[1]) do
            obj = obj and obj:FindFirstChild(childName)
        end
        if obj and obj:IsA("BasePart") then
            return obj.CFrame:PointToWorldSpace(entry[2])
        end
    end
    return Vector3.new(528.7, 70.57, -364.11)
end

local function tpToPos(targetPos)
    local hrp = getHRP()
    if not hrp then return end
    pcall(function()
        hrp.CFrame = CFrame.new(targetPos) * CFrame.Angles(0, math.rad(90), 0)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)
end

-- ==========================================
-- [2] ระบบ 2 ภาษา (TH / EN) & สถานะฟังก์ชัน
-- ==========================================
local LangData = {
    TH = {
        MainTab = "หลักและคอร์ส",
        EggTab = "ระบบฟาร์ม / Egg",
        UniversalTab = "ฟังก์ชันทุกแมพ",
        ConfigTab = "ตั้งค่าและโปรไฟล์",
        SectionCore = "ระบบคอร์สหลัก (Core Engine)",
        HumBypass = "Clone Humanoid (กันรีเซ็ตความเร็ว)",
        FpsFluctuate = "สลับ FPS 60/30 (Bypass)",
        SpawnDecoy = "สร้างร่างโคลนจำลอง (Decoy)",
        ClearDecoy = "ลบร่างโคลนจำลอง",
        TpSafe = "วาร์ปไปจุดปลอดภัย (Safe Zone)",
        AutoEgg = "ออโต้เก็บไข่/ไอเทมมูลค่าสูงสุด",
        DropEgg = "วางไอเทมที่ถืออยู่ (Drop)",
        ScanBest = "สแกนไอเทมแพงสุดในแมพ",
        WalkSpeedToggle = "เปิดใช้งานวิ่งไว (WalkSpeed)",
        JumpPowerToggle = "เปิดใช้งานกระโดดสูง (Jump)",
        NoclipToggle = "เดินทะลุกำแพง (Noclip)",
        InfJumpToggle = "กระโดดไม่จำกัด (Infinite Jump)",
        FullBrightToggle = "สว่างทั้งแมพ (Fullbright)",
        AutoPromptToggle = "กดปุ่ม E อัตโนมัติ (Auto Prompt)",
    },
    EN = {
        MainTab = "Main & Core",
        EggTab = "Egg / Auto Farm",
        UniversalTab = "Universal Cheats",
        ConfigTab = "Config & Settings",
        SectionCore = "Core Engine Controls",
        HumBypass = "Humanoid Clone Bypass",
        FpsFluctuate = "FPS 60/30 Fluctuate",
        SpawnDecoy = "Spawn Visual Decoy",
        ClearDecoy = "Clear Visual Decoy",
        TpSafe = "Teleport to Safe Zone",
        AutoEgg = "Auto Collect Best Egg",
        DropEgg = "Drop Carried Egg",
        ScanBest = "Scan Best Egg Value",
        WalkSpeedToggle = "Enable WalkSpeed",
        JumpPowerToggle = "Enable JumpPower",
        NoclipToggle = "Noclip",
        InfJumpToggle = "Infinite Jump",
        FullBrightToggle = "Fullbright",
        AutoPromptToggle = "Auto ProximityPrompt",
    }
}

local currentLang = "TH"
local Flags = {
    AutoEgg = false,
    WalkSpeed = false,
    JumpPower = false,
    Noclip = false,
    InfJump = false,
    AutoPrompt = false,
    SpeedVal = 36,
    JumpVal = 85,
}

-- ==========================================
-- [3] สร้างหน้าต่าง WindUI (VORTEX//DELTA-2.5 HUB)
-- ==========================================
local Window = WindUI:CreateWindow({
    Title = "VORTEX//DELTA-2.5 HUB",
    Icon = "https://cdn.phototourl.com/member/2026-11-19-362b148f-bee1-4c27-8e11-c371a003573e.jpg",
    Author = "by VORTEX_ENGINE_DELTA-2.5",
    Theme = "Red",
})

-- แถบ 1: คอร์สหลัก
local TabCore = Window:Tab({
    Title = LangData[currentLang].MainTab,
    Icon = "cpu",
})

local SectionCore = TabCore:Section({
    Title = LangData[currentLang].SectionCore,
})

local HumBypassToggle = TabCore:Toggle({
    Title = LangData[currentLang].HumBypass,
    Flag = "core_hum_bypass",
    Value = false,
    Callback = function(state)
        if state then
            enableHumBypass()
        else
            disableHumBypass()
        end
    end
})

local FpsToggle = TabCore:Toggle({
    Title = LangData[currentLang].FpsFluctuate,
    Flag = "core_fps_toggle",
    Value = false,
    Callback = function(state)
        if state then
            startFpsToggle()
        else
            stopFpsToggle()
        end
    end
})

local SpawnDecoyBtn = TabCore:Button({
    Title = LangData[currentLang].SpawnDecoy,
    Callback = function()
        spawnDecoy()
    end
})

local ClearDecoyBtn = TabCore:Button({
    Title = LangData[currentLang].ClearDecoy,
    Callback = function()
        clearDecoy()
    end
})

local TpSafeBtn = TabCore:Button({
    Title = LangData[currentLang].TpSafe,
    Callback = function()
        tpToPos(getSafeZonePos())
    end
})

-- แถบ 2: ระบบ Egg & Auto Farm (จากคอร์สหลัก)
local TabEgg = Window:Tab({
    Title = LangData[currentLang].EggTab,
    Icon = "egg",
})

local BestEggLabel = TabEgg:Paragraph({
    Title = "Best Target Info",
    Desc = "Waiting for scan..."
})

local AutoEggToggle = TabEgg:Toggle({
    Title = LangData[currentLang].AutoEgg,
    Flag = "core_auto_egg",
    Value = false,
    Callback = function(state)
        Flags.AutoEgg = state
        CarryState.Cancel = not state
    end
})

local ScanEggBtn = TabEgg:Button({
    Title = LangData[currentLang].ScanBest,
    Callback = function()
        local snaps = getEggSnapshots()
        local bestInfo = nil
        for _, rec in ipairs(snaps) do
            local info = parseEggInfo(rec)
            if not bestInfo or info.Value > bestInfo.Value then
                bestInfo = info
            end
        end
        if bestInfo then
            BestEggLabel:SetDesc(bestInfo.Name .. " | " .. formatRate(bestInfo.Value))
        else
            BestEggLabel:SetDesc("No EggWorld records found in this map.")
        end
    end
})

local DropEggBtn = TabEgg:Button({
    Title = LangData[currentLang].DropEgg,
    Callback = function()
        dro
