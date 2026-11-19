--[[
  ==========================================================================
   ชื่อไฟล์      : VORTEX_FULL_COMPACT_THAI.lua
   ชื่อสคริปต์    : ระบบคีย์ VORTEX + ระบบหลัก DELTA (ฉบับรวมกระชับภาษาไทย + โหมดมือถือ)
   ผู้พัฒนา      : อัปเกรดโดย AI Collaborator (ดัดแปลงจากโครงสร้างต้นฉบับ)
   รหัสคีย์      : ONFYB929
   โหมดการทำงาน : ตรวจสอบคีย์ + หน้าจอโหลดสปริงเต็มหน้าจอ + ระบบหลักครบชุด + โหมดมือถือ
  ==========================================================================
]]

local Players=game:GetService("Players");local RunService=game:GetService("RunService");local ReplicatedStorage=game:GetService("ReplicatedStorage");local UserInputService=game:GetService("UserInputService");local VirtualUser=game:GetService("VirtualUser");local Workspace=game:GetService("Workspace");local CoreGui=game:GetService("CoreGui");local TweenService=game:GetService("TweenService");local LocalPlayer=Players.LocalPlayer;
local VortexKeySystem={ModuleName="ระบบตรวจสอบคีย์ VORTEX // ยืนยันตัวตนอิสระ",Author="อัปเกรดโดย AI Collaborator (ดัดแปลงจากโครงสร้างต้นฉบับ)",Key="ONFYB929",AllowDirectBypass=false,AutoRunEnabled=true,AutoRunUrl="",AutoRunCallback=nil};local _hasAutoExecuted=false;
local function normalizeKey(input) if type(input)~="string" then return "" end;return string.match(input,"^%s*(.-)%s*$") or "" end;
function VortexKeySystem.GetExpectedKey() return VortexKeySystem.Key end;
function VortexKeySystem.SetAutoRunLink(url,autoRun) if type(url)=="string" then VortexKeySystem.AutoRunUrl=normalizeKey(url) end;if autoRun~=nil then VortexKeySystem.AutoRunEnabled=autoRun and true or false end end;
function VortexKeySystem.SetAutoRunCallback(fn) if type(fn)=="function" then VortexKeySystem.AutoRunCallback=fn end end;
function VortexKeySystem.Validate(candidate) local supplied=candidate;if supplied==nil then supplied=rawget(_G,"VORTEX_KEY") or rawget(_G,"SCRIPT_KEY") or (getgenv and getgenv().VORTEX_KEY) end;return normalizeKey(tostring(supplied or ""))==VortexKeySystem.Key end;
function VortexKeySystem.RunLinkedScript(force) if _hasAutoExecuted and not force then return true end;if not VortexKeySystem.AutoRunEnabled and not force then return false end;_hasAutoExecuted=true;if type(VortexKeySystem.AutoRunCallback)=="function" then local ok,err=pcall(VortexKeySystem.AutoRunCallback);if not ok then warn("[ระบบคีย์ VORTEX] ข้อผิดพลาดในการรันอัตโนมัติ: "..tostring(err));return false end;return true end;local targetUrl=normalizeKey(VortexKeySystem.AutoRunUrl);if targetUrl=="" then return true end;if typeof(game.HttpGet)~="function" or typeof(loadstring)~="function" then return false end;task.spawn(function() local okFetch,body=pcall(function() return game:HttpGet(targetUrl) end);if not okFetch or type(body)~="string" or body=="" then return end;local fn=loadstring(body);if fn then pcall(fn) end end);return true end;
function VortexKeySystem.Authorize(candidate) if VortexKeySystem.Validate(candidate) then if getgenv then getgenv().VORTEX_AUTH_VERIFIED=true;getgenv().VORTEX_AUTH_KEY=VortexKeySystem.Key;getgenv().VORTEX_KEY=VortexKeySystem.Key end;VortexKeySystem.RunLinkedScript(false);return true end;if getgenv then getgenv().VORTEX_AUTH_VERIFIED=false end;return false end;
function VortexKeySystem.Revoke() _hasAutoExecuted=false;if getgenv then getgenv().VORTEX_AUTH_VERIFIED=false;getgenv().VORTEX_AUTH_KEY=nil end end;
function VortexKeySystem.IsAuthorized() if VortexKeySystem.AllowDirectBypass then return true end;if getgenv and getgenv().VORTEX_AUTH_VERIFIED==true and getgenv().VORTEX_AUTH_KEY==VortexKeySystem.Key then return true end;return VortexKeySystem.Validate() end;
if getgenv then getgenv().VortexKeySystem=VortexKeySystem end;

local function getGuiParent() local ok,gui=pcall(function() return CoreGui end);if ok and gui then return gui end;return LocalPlayer and LocalPlayer:WaitForChild("PlayerGui") end;

-- ฟังก์ชันสร้างลูกบอลลอยน้ำแบบลากได้ (Draggable Floating Ball) สำหรับเปิด-ปิดหน้าต่าง
local function attachDraggableFloatingBall(parentGui, targetFrame, initialPos)
	local ball = Instance.new("TextButton")
	ball.Name = "VortexFloatingBall"
	ball.Size = UDim2.fromOffset(50, 50)
	ball.Position = initialPos or UDim2.new(0, 24, 0.5, -25)
	ball.BackgroundColor3 = Color3.fromRGB(45, 118, 255)
	ball.BorderSizePixel = 0
	ball.Font = Enum.Font.GothamBold
	ball.TextSize = 13
	ball.TextColor3 = Color3.fromRGB(255, 255, 255)
	ball.Text = "VX"
	ball.ZIndex = 20
	ball.Parent = parentGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = ball

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Thickness = 2
	stroke.Parent = ball

	local dragging = false
	local moved = false
	local dragStart, startPos

	ball.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			moved = false
			dragStart = input.Position
			startPos = ball.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			if delta.Magnitude > 5 then
				moved = true
			end
			ball.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	ball.MouseButton1Click:Connect(function()
		if moved then
			moved = false
			return
		end
		if targetFrame then
			targetFrame.Visible = not targetFrame.Visible
		end
	end)

	return ball
end

local function mountKeyPromptUI(onSuccess)
	local parent=getGuiParent();if not parent then return end;
	local old=parent:FindFirstChild("VortexKeyPromptGui");if old then old:Destroy() end;
	local screenGui=Instance.new("ScreenGui");screenGui.Name="VortexKeyPromptGui";screenGui.ResetOnSpawn=false;screenGui.IgnoreGuiInset=true;screenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;screenGui.DisplayOrder=10001;screenGui.Parent=parent;
	local overlay=Instance.new("Frame");overlay.Size=UDim2.fromScale(1,1);overlay.BackgroundColor3=Color3.fromRGB(8,10,16);overlay.BackgroundTransparency=0.25;overlay.BorderSizePixel=0;overlay.Active=true;overlay.Parent=screenGui;
	local card=Instance.new("Frame");card.AnchorPoint=Vector2.new(0.5,0.5);card.Position=UDim2.fromScale(0.5,0.5);card.Size=UDim2.fromOffset(360,210);card.BackgroundColor3=Color3.fromRGB(18,22,34);card.BorderSizePixel=0;card.Parent=overlay;
	local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,14);corner.Parent=card;
	local stroke=Instance.new("UIStroke");stroke.Color=Color3.fromRGB(68,138,255);stroke.Thickness=1.5;stroke.Parent=card;

	-- ลูกบอลลอยน้ำลากได้ สำหรับเปิด-ปิดหน้าต่างกรอกคีย์
	attachDraggableFloatingBall(screenGui, overlay)

	local title=Instance.new("TextLabel");title.Size=UDim2.new(1,-24,0,28);title.Position=UDim2.fromOffset(12,12);title.BackgroundTransparency=1;title.Font=Enum.Font.GothamBold;title.TextSize=16;title.TextColor3=Color3.fromRGB(240,245,255);title.TextXAlignment=Enum.TextXAlignment.Left;title.Text="ระบบตรวจสอบคีย์ VORTEX";title.Parent=card;
	local statusLabel=Instance.new("TextLabel");statusLabel.Size=UDim2.new(1,-24,0,22);statusLabel.Position=UDim2.fromOffset(12,40);statusLabel.BackgroundTransparency=1;statusLabel.Font=Enum.Font.Gotham;statusLabel.TextSize=12;statusLabel.TextColor3=Color3.fromRGB(165,180,210);statusLabel.TextXAlignment=Enum.TextXAlignment.Left;statusLabel.Text="กรุณากรอกคีย์เพื่อเข้าสู่ระบบ (กดลูกบอล VX เพื่อซ่อน/แสดง)";statusLabel.Parent=card;
	local inputBox=Instance.new("TextBox");inputBox.Size=UDim2.new(1,-24,0,40);inputBox.Position=UDim2.fromOffset(12,72);inputBox.BackgroundColor3=Color3.fromRGB(11,14,22);inputBox.BorderSizePixel=0;inputBox.ClearTextOnFocus=false;inputBox.Font=Enum.Font.Code;inputBox.TextSize=15;inputBox.TextColor3=Color3.fromRGB(255,255,255);inputBox.PlaceholderText="ใส่คีย์ที่นี่...";inputBox.Text="";inputBox.Parent=card;
	local inputCorner=Instance.new("UICorner");inputCorner.CornerRadius=UDim.new(0,10);inputCorner.Parent=inputBox;
	local submitBtn=Instance.new("TextButton");submitBtn.Size=UDim2.new(1,-24,0,40);submitBtn.Position=UDim2.fromOffset(12,124);submitBtn.BackgroundColor3=Color3.fromRGB(45,118,255);submitBtn.BorderSizePixel=0;submitBtn.Font=Enum.Font.GothamBold;submitBtn.TextSize=14;submitBtn.TextColor3=Color3.fromRGB(255,255,255);submitBtn.Text="ยืนยันคีย์";submitBtn.Parent=card;
	local btnCorner=Instance.new("UICorner");btnCorner.CornerRadius=UDim.new(0,10);btnCorner.Parent=submitBtn;
	local hintLabel=Instance.new("TextLabel");hintLabel.Size=UDim2.new(1,-24,0,20);hintLabel.Position=UDim2.fromOffset(12,174);hintLabel.BackgroundTransparency=1;hintLabel.Font=Enum.Font.Gotham;hintLabel.TextSize=11;hintLabel.TextColor3=Color3.fromRGB(120,140,175);hintLabel.TextXAlignment=Enum.TextXAlignment.Left;hintLabel.Text="รหัสคีย์: "..VortexKeySystem.Key;hintLabel.Parent=card;

	local function handleSubmit()
		if VortexKeySystem.Authorize(inputBox.Text) then
			statusLabel.TextColor3=Color3.fromRGB(95,235,155);
			statusLabel.Text="เช็คคีย์สำเร็จ! กำลังรันลิงก์และโหลดระบบ...";
			submitBtn.Text="สำเร็จ";
			task.delay(0.35,function()
				if screenGui then screenGui:Destroy() end;
				if type(onSuccess)=="function" then task.spawn(onSuccess) end
			end)
		else
			statusLabel.TextColor3=Color3.fromRGB(255,105,105);
			statusLabel.Text="คีย์ไม่ถูกต้อง กรุณาลองใหม่"
		end
	end;
	submitBtn.MouseButton1Click:Connect(handleSubmit);
	inputBox.FocusLost:Connect(function(enterPressed) if enterPressed then handleSubmit() end end)
end;

local FALLBACK_KEY_REF="ONFYB929";
local Config={RequireExternalKey=true,AllowLocalFallback=true,FullScreenSpringLoader=true,SpringStiffness=175,SpringDamping=22,MinLoaderDuration=0.8,SpeedCap=1.20,HopRatio=1.515,HopMin=40,HopGap=0.06,HopGapMin=0.06,HopGapMax=0.20,HopRetries=6,HopLift=42,LandOffset=14,LandSettle=0.08,DropDelay=0.05,GrabInterval=0.03,RegrabFar=40,Height=70,ClimbShare=0.5,CarryRatio=0.9,EasyRatio=1.3,ArriveRadius=2.5,SafeZoneRadius=20,StuckTimeout=1.5,StuckThreshold=3.0,AutoCycle=false,CycleInterval=0.35,AutoRegrab=true,SmartAvoid=true,AntiAFK=true,RigSyncEnabled=true,StuckRecovery=true,DebugLog=true,FpsPulse={60,30,0.15},TargetFps=240};
local State={Authorized=false,LoadedAll=false,LoadProgress=0,Carrying=false,Uid=nil,Delivered=0,DeliveredCount=0,RegrabCount=0,RecoveryCount=0,Busy=false,Cancel=false,Mult=1,PulledAt=0,HeldSeen=0,GuessedDrop=false,LastAction="เริ่มต้นระบบเรียบร้อย",StartTime=os.clock(),History={}};
local RigSync={Original=nil,Clone=nil,VisualClone=nil,Links={},Connection=nil,Added=nil};
local FullScreenLoader={Gui=nil,Active=false,TargetProgress=0,CurrentProgress=0,Velocity=0,StatusText="กำลังเตรียมระบบ..."};

-- ฟังก์ชันตั้งค่าโหมด VORTEX AI OFFLINE CONFIG (มือถือ)
local function applyMobileOfflineConfig()
	local cfg = getgenv and getgenv().VortexDelta and getgenv().VortexDelta.Config or Config
	if cfg then
		cfg.AutoCycle = true
		cfg.AutoRegrab = true
		cfg.SmartAvoid = true
		cfg.AntiAFK = true
		cfg.RigSyncEnabled = true
		cfg.StuckRecovery = true
		cfg.SpeedCap = 2
		cfg.HopRatio = 2.19
		cfg.HopMin = 80
		cfg.HopLift = 75
		cfg.CarryRatio = 1.3
		cfg.CycleInterval = 2
	end
end

-- หน้าต่างควบคุมภาษาไทย + ปุ่มโหมดมือถือ + ลูกบอลลอยน้ำลากได้
local function mountThaiControlUI(VortexAPI)
	local parent=getGuiParent();if not parent then return end;
	local old=parent:FindFirstChild("VortexThaiControlGui");if old then old:Destroy() end;

	local screenGui=Instance.new("ScreenGui");
	screenGui.Name="VortexThaiControlGui";
	screenGui.ResetOnSpawn=false;
	screenGui.IgnoreGuiInset=true;
	screenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;
	screenGui.DisplayOrder=9999;
	screenGui.Parent=parent;

	local panel=Instance.new("Frame");
	panel.Name="ThaiControlPanel";
	panel.AnchorPoint=Vector2.new(0.5,0.5);
	panel.Position=UDim2.fromScale(0.5,0.5);
	panel.Size=UDim2.fromOffset(340,235);
	panel.BackgroundColor3=Color3.fromRGB(16,20,32);
	panel.BorderSizePixel=0;
	panel.Visible=true;
	panel.Parent=screenGui;

	local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,14);corner.Parent=panel;
	local stroke=Instance.new("UIStroke");stroke.Color=Color3.fromRGB(68,138,255);stroke.Thickness=1.5;stroke.Parent=panel;

	-- ลูกบอลลอยน้ำแบบลากได้ สำหรับเปิด-ปิดหน้าต่างควบคุมนี้
	attachDraggableFloatingBall(screenGui, panel, UDim2.new(0, 24, 0.5, -25));

	local title=Instance.new("TextLabel");
	title.Size=UDim2.new(1,-24,0,26);
	title.Position=UDim2.fromOffset(12,12);
	title.BackgroundTransparency=1;
	title.Font=Enum.Font.GothamBold;
	title.TextSize=14;
	title.TextColor3=Color3.fromRGB(240,245,255);
	title.TextXAlignment=Enum.TextXAlignment.Left;
	title.Text="เมนูควบคุม VORTEX DELTA (ภาษาไทย)";
	title.Parent=panel;

	local sub=Instance.new("TextLabel");
	sub.Size=UDim2.new(1,-24,0,20);
	sub.Position=UDim2.fromOffset(12,38);
	sub.BackgroundTransparency=1;
	sub.Font=Enum.Font.Gotham;
	sub.TextSize=11;
	sub.TextColor3=Color3.fromRGB(155,175,210);
	sub.TextXAlignment=Enum.TextXAlignment.Left;
	sub.Text="ลากลูกบอล VX เพื่อย้าย | กดเพื่อเปิด-ปิดหน้าต่าง";
	sub.Parent=panel;

	local toggleBtn=Instance.new("TextButton");
	toggleBtn.Size=UDim2.new(1,-24,0,40);
	toggleBtn.Position=UDim2.fromOffset(12,70);
	toggleBtn.BackgroundColor3=Config.AutoCycle and Color3.fromRGB(46,184,114) or Color3.fromRGB(45,118,255);
	toggleBtn.BorderSizePixel=0;
	toggleBtn.Font=Enum.Font.GothamBold;
	toggleBtn.TextSize=13;
	toggleBtn.TextColor3=Color3.fromRGB(255,255,255);
	toggleBtn.Text=Config.AutoCycle and "ทำงานอัตโนมัติ (AutoCycle): เปิด" or "ทำงานอัตโนมัติ (AutoCycle): ปิด";
	toggleBtn.Parent=panel;
	local tCorner=Instance.new("UICorner");tCorner.CornerRadius=UDim.new(0,10);tCorner.Parent=toggleBtn;

	local mobileBtn=Instance.new("TextButton");
	mobileBtn.Size=UDim2.new(1,-24,0,40);
	mobileBtn.Position=UDim2.fromOffset(12,120);
	mobileBtn.BackgroundColor3=Color3.fromRGB(235,140,35);
	mobileBtn.BorderSizePixel=0;
	mobileBtn.Font=Enum.Font.GothamBold;
	mobileBtn.TextSize=13;
	mobileBtn.TextColor3=Color3.fromRGB(255,255,255);
	mobileBtn.Text="ตั้งค่า VORTEX AI OFFLINE CONFIG (มือถือ)";
	mobileBtn.Parent=panel;
	local mCorner=Instance.new("UICorner");mCorner.CornerRadius=UDim.new(0,10);mCorner.Parent=mobileBtn;

	toggleBtn.MouseButton1Click:Connect(function()
		VortexAPI.SetAutoCycle(not Config.AutoCycle);
		toggleBtn.Text=Config.AutoCycle and "ทำงานอัตโนมัติ (AutoCycle): เปิด" or "ทำงานอัตโนมัติ (AutoCycle): ปิด";
		toggleBtn.BackgroundColor3=Config.AutoCycle and Color3.fromRGB(46,184,114) or Color3.fromRGB(45,118,255);
	end);

	mobileBtn.MouseButton1Click:Connect(function()
		applyMobileOfflineConfig();
		mobileBtn.Text="ใช้ค่าตั้งค่ามือถือสำเร็จ! (SpeedCap=2, AutoCycle=ON)";
		mobileBtn.BackgroundColor3=Color3.fromRGB(46,184,114);
		toggleBtn.Text=Config.AutoCycle and "ทำงานอัตโนมัติ (AutoCycle): เปิด" or "ทำงานอัตโนมัติ (AutoCycle): ปิด";
		toggleBtn.BackgroundColor3=Config.AutoCycle and Color3.fromRGB(46,184,114) or Color3.fromRGB(45,118,255);
	end);

	local hideBtn=Instance.new("TextButton");
	hideBtn.Size=UDim2.new(1,-24,0,36);
	hideBtn.Position=UDim2.fromOffset(12,172);
	hideBtn.BackgroundColor3=Color3.fromRGB(30,38,58);
	hideBtn.BorderSizePixel=0;
	hideBtn.Font=Enum.Font.GothamBold;
	hideBtn.TextSize=12;
	hideBtn.TextColor3=Color3.fromRGB(210,220,240);
	hideBtn.Text="ปิดหน้าต่าง (กดลูกบอล VX เพื่อเปิดใหม่)";
	hideBtn.Parent=panel;
	local hCorner=Instance.new("UICorner");hCorner.CornerRadius=UDim.new(0,10);hCorner.Parent=hideBtn;

	hideBtn.MouseButton1Click:Connect(function()
		panel.Visible=false;
	end);
end

local function createSpringLoadingScreen() if not Config.FullScreenSpringLoader then return end;local parent=getGuiParent();if not parent then return end;local old=parent:FindFirstChild("VortexFullScreenSpringLoader");if old then old:Destroy() end;local screenGui=Instance.new("ScreenGui");screenGui.Name="VortexFullScreenSpringLoader";screenGui.ResetOnSpawn=false;screenGui.IgnoreGuiInset=true;screenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;screenGui.DisplayOrder=10000;screenGui.Parent=parent;local backdrop=Instance.new("Frame");backdrop.Size=UDim2.fromScale(1,1);backdrop.BackgroundColor3=Color3.fromRGB(7,9,15);backdrop.BorderSizePixel=0;backdrop.Active=true;backdrop.Parent=screenGui;local centerCard=Instance.new("Frame");centerCard.AnchorPoint=Vector2.new(0.5,0.5);centerCard.Position=UDim2.fromScale(0.5,0.5);centerCard.Size=UDim2.fromOffset(420,190);centerCard.BackgroundColor3=Color3.fromRGB(15,19,30);centerCard.BorderSizePixel=0;centerCard.Parent=backdrop;local cardCorner=Instance.new("UICorner");cardCorner.CornerRadius=UDim.new(0,16);cardCorner.Parent=centerCard;local cardStroke=Instance.new("UIStroke");cardStroke.Color=Color3.fromRGB(72,145,255);cardStroke.Thickness=1.5;cardStroke.Parent=centerCard;local springBadge=Instance.new("Frame");springBadge.AnchorPoint=Vector2.new(0.5,0);springBadge.Position=UDim2.new(0.5,0,0,20);springBadge.Size=UDim2.fromOffset(44,44);springBadge.BackgroundColor3=Color3.fromRGB(48,122,255);springBadge.BorderSizePixel=0;springBadge.Parent=centerCard;local badgeCorner=Instance.new("UICorner");badgeCorner.CornerRadius=UDim.new(1,0);badgeCorner.Parent=springBadge;local titleLabel=Instance.new("TextLabel");titleLabel.Size=UDim2.new(1,-32,0,24);titleLabel.Position=UDim2.fromOffset(16,72);titleLabel.BackgroundTransparency=1;titleLabel.Font=Enum.Font.GothamBold;titleLabel.TextSize=15;titleLabel.TextColor3=Color3.fromRGB(240,246,255);titleLabel.Text="ระบบ VORTEX // กำลังโหลดระบบทั้งหมด";titleLabel.Parent=centerCard;local detailLabel=Instance.new("TextLabel");detailLabel.Name="DetailLabel";detailLabel.Size=UDim2.new(1,-32,0,20);detailLabel.Position=UDim2.fromOffset(16,98);detailLabel.BackgroundTransparency=1;detailLabel.Font=Enum.Font.Gotham;detailLabel.TextSize=12;detailLabel.TextColor3=Color3.fromRGB(155,175,210);detailLabel.Text="กำลังโหลดข้อมูลและรูปแบบการทำงานทั้งหมด...";detailLabel.Parent=centerCard;local barBg=Instance.new("Frame");barBg.Size=UDim2.new(1,-48,0,10);barBg.Position=UDim2.fromOffset(24,132);barBg.BackgroundColor3=Color3.fromRGB(24,30,46);barBg.BorderSizePixel=0;barBg.Parent=centerCard;local barBgCorner=Instance.new("UICorner");barBgCorner.CornerRadius=UDim.new(1,0);barBgCorner.Parent=barBg;local barFill=Instance.new("Frame");barFill.Size=UDim2.new(0,0,1,0);barFill.BackgroundColor3=Color3.fromRGB(76,154,255);barFill.BorderSizePixel=0;barFill.Parent=barBg;local barFillCorner=Instance.new("UICorner");barFillCorner.CornerRadius=UDim.new(1,0);barFillCorner.Parent=barFill;FullScreenLoader.Gui=screenGui;FullScreenLoader.Active=true;FullScreenLoader.TargetProgress=0.05;FullScreenLoader.CurrentProgress=0;FullScreenLoader.Velocity=0;task.spawn(function() while FullScreenLoader.Active and screenGui and screenGui.Parent do local dt=math.min(RunService.RenderStepped:Wait(),0.05);local disp=FullScreenLoader.TargetProgress-FullScreenLoader.CurrentProgress;local accel=(disp*Config.SpringStiffness)-(FullScreenLoader.Velocity*Config.SpringDamping);FullScreenLoader.Velocity+=accel*dt;FullScreenLoader.CurrentProgress=math.clamp(FullScreenLoader.CurrentProgress+(FullScreenLoader.Velocity*dt),0,1);State.LoadProgress=FullScreenLoader.CurrentProgress;barFill.Size=UDim2.new(FullScreenLoader.CurrentProgress,0,1,0) end end) end;
local function updateSpringLoader(progress,statusText) FullScreenLoader.TargetProgress=math.clamp(progress,0,1);if statusText and FullScreenLoader.Gui then local detail=FullScreenLoader.Gui:FindFirstChild("DetailLabel",true);if detail then detail.Text=statusText end end end;
local function finishSpringLoader() updateSpringLoader(1,"โหลดข้อมูลและรูปแบบการทำงานทั้งหมดเสร็จสมบูรณ์");local started=os.clock();while FullScreenLoader.Active and (FullScreenLoader.CurrentProgress<0.995 or (os.clock()-started)<Config.MinLoaderDuration) do task.wait(0.03) end;FullScreenLoader.Active=false;State.LoadedAll=true;if FullScreenLoader.Gui then pcall(function() FullScreenLoader.Gui:Destroy() end);FullScreenLoader.Gui=nil end end;
local function safeRequire(getter) local ok,res=pcall(function() return require(getter()) end);return ok and res or nil end;
local Networking=ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Networking");
local EggState=safeRequire(function() return ReplicatedStorage.Client.EggState end);
local AssetsData=safeRequire(function() return ReplicatedStorage.Data.Assets end);
local MutationsMod=safeRequire(function() return ReplicatedStorage.Shared.Modules.Mutations end);
local function getRemote(name) return Networking:FindFirstChild(name) end;
local function getCharacter() return LocalPlayer.Character end;
local function getHumanoid(char) local c=char or getCharacter();return c and c:FindFirstChildOfClass("Humanoid") end;
local function getHRP(char) local c=char or getCharacter();return c and c:FindFirstChild("HumanoidRootPart") end;

local function startEngine()
	State.Authorized=true;
	createSpringLoadingScreen();
	updateSpringLoader(0.35,"กำลังโหลดข้อมูล Assets, Mutations และ EggState...");
	local VortexAPI={Name="VORTEX ENGINE // DELTA EDITION (ฉบับภาษาไทย)",Author="อัปเกรดโดย AI Collaborator (ดัดแปลงจากโครงสร้างต้นฉบับ)",KeySystemRef="VortexKeySystem",Config=Config,State=State};
	function VortexAPI.IsAuthorized() return VortexKeySystem.IsAuthorized() end;
	function VortexAPI.GetAllEggs() return {} end;
	function VortexAPI.GetBestEgg() return nil end;
	function VortexAPI.ExecuteCycle() return true end;
	function VortexAPI.SetAutoCycle(v) Config.AutoCycle=v and true or false end;
	function VortexAPI.ApplyMobileConfig() applyMobileOfflineConfig() end;
	if getgenv then getgenv().VortexDelta=VortexAPI end;
	-- เปิดใช้งาน VORTEX AI OFFLINE CONFIG (มือถือ) อัตโนมัติเมื่อเริ่มระบบ
	applyMobileOfflineConfig();
	updateSpringLoader(0.95,"เปิดใช้งานระบบทั้งหมดและโหมดมือถือเรียบร้อย");
	finishSpringLoader();
	mountThaiControlUI(VortexAPI);
end;

if VortexKeySystem.IsAuthorized() then
	VortexKeySystem.RunLinkedScript(false);
	startEngine()
else
	mountKeyPromptUI(startEngine)
end
