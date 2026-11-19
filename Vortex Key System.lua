--[[
  ==========================================================================
   File Name   : VORTEX_KEY_SYSTEM.txt (Updated with Language Selector & Floating Ball)
   Module Name : VORTEX KEY MODULE // STANDALONE AUTH + LANGUAGE SELECTOR
   Author      : Upgraded by AI Collaborator
   Key         : QX4J37ENQPZ7
   Mode        : Key System -> Floating Ball / Language Selection -> Auto Link
  ==========================================================================
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local VortexKeySystem = {}

VortexKeySystem.ModuleName = "VORTEX KEY MODULE // LANGUAGE SELECTOR"
VortexKeySystem.Author = "Upgraded by AI Collaborator"
VortexKeySystem.Key = "QX4J37ENQPZ7"
VortexKeySystem.AllowDirectBypass = false

-- กำหนดลิงก์สำหรับแต่ละภาษา (สามารถเปลี่ยนเป็น URL Raw Lua จริงของคุณได้ที่นี่)
VortexKeySystem.Links = {
	English = "", -- ใส่ลิงก์สคริปต์ภาษาอังกฤษตรงนี้
	Thai    = ""  -- ใส่ลิงก์สคริปต์ภาษาไทยตรงนี้
	TH/EN   = "https://raw.githubusercontent.com/XASZD-NET/VORTEX_ENGINE_DELTA-2.5/refs/heads/main/ml.lua"  -- ใส่ลิงก์สคริปต์ภาษาไทยตรงนี้
	
}

local _hasAutoExecuted = false

local function normalizeKey(input)
	if type(input) ~= "string" then
		return ""
	end
	return string.match(input, "^%s*(.-)%s*$") or ""
end

function VortexKeySystem.GetExpectedKey()
	return VortexKeySystem.Key
end

function VortexKeySystem.SetLinks(engUrl, thaiUrl)
	if type(engUrl) == "string" then
		VortexKeySystem.Links.English = normalizeKey(engUrl)
	end
	if type(thaiUrl) == "string" then
		VortexKeySystem.Links.Thai = normalizeKey(thaiUrl)
	end
end

function VortexKeySystem.Validate(candidate)
	local supplied = candidate
	if supplied == nil then
		supplied = rawget(_G, "VORTEX_KEY") or rawget(_G, "SCRIPT_KEY") or (getgenv and getgenv().VORTEX_KEY)
	end
	local cleaned = normalizeKey(tostring(supplied or ""))
	return cleaned == VortexKeySystem.Key
end

-- ฟังก์ชันสำหรับดึงและรันสคริปต์ตามภาษาที่เลือก
function VortexKeySystem.RunSelectedScript(languageKey)
	if _hasAutoExecuted then
		return true
	end

	local targetUrl = VortexKeySystem.Links[languageKey]
	if not targetUrl or targetUrl == "" then
		warn("[VORTEX KEY] No URL configured for language: " .. tostring(languageKey))
		return false
	end

	_hasAutoExecuted = true

	if typeof(game.HttpGet) ~= "function" or typeof(loadstring) ~= "function" then
		warn("[VORTEX KEY] Executor does not support HttpGet/loadstring.")
		return false
	end

	task.spawn(function()
		local okFetch, body = pcall(function()
			return game:HttpGet(targetUrl)
		end)
		if not okFetch or type(body) ~= "string" or body == "" then
			warn("[VORTEX KEY] Failed to fetch link: " .. tostring(body))
			return
		end

		local fn, loadErr = loadstring(body)
		if not fn then
			warn("[VORTEX KEY] Failed to compile linked script: " .. tostring(loadErr))
			return
		end

		local okRun, runErr = pcall(fn)
		if not okRun then
			warn("[VORTEX KEY] Linked script runtime error: " .. tostring(runErr))
			return
		end

		print("[VORTEX KEY] Linked script (" .. tostring(languageKey) .. ") executed successfully.")
	end)

	return true
end

local function getGuiParent()
	local ok, gui = pcall(function()
		return CoreGui
	end)
	if ok and gui then
		return gui
	end
	return LocalPlayer and LocalPlayer:WaitForChild("PlayerGui")
end

-- สร้างหน้าต่างเลือกภาษา พร้อม "ลูกบอลลอยน้ำ" (Floating Ball) สำหรับเปิด/ปิดหน้าต่าง
local function mountLanguageSelectorUI()
	local parent = getGuiParent()
	if not parent then return end

	local old = parent:FindFirstChild("VortexLanguageSelectorGui")
	if old then
		old:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "VortexLanguageSelectorGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 999
	screenGui.Parent = parent

	-- 1. ลูกบอลลอยน้ำ (Floating Ball สำหรับกดเปิด-ปิดหน้าต่าง)
	local floatingBall = Instance.new("TextButton")
	floatingBall.Name = "FloatingBall"
	floatingBall.Size = UDim2.fromOffset(50, 50)
	floatingBall.Position = UDim2.new(0, 30, 0.5, -25)
	floatingBall.BackgroundColor3 = Color3.fromRGB(45, 118, 255)
	floatingBall.BorderSizePixel = 0
	floatingBall.Font = Enum.Font.GothamBold
	floatingBall.TextSize = 12
	floatingBall.TextColor3 = Color3.fromRGB(255, 255, 255)
	floatingBall.Text = "VX"
	floatingBall.Parent = screenGui

	local ballCorner = Instance.new("UICorner")
	ballCorner.CornerRadius = UDim.new(1, 0) -- ทำให้เป็นวงกลมเหมือนลูกบอล
	ballCorner.Parent = floatingBall

	local ballStroke = Instance.new("UIStroke")
	ballStroke.Color = Color3.fromRGB(255, 255, 255)
	ballStroke.Thickness = 2
	ballStroke.Parent = floatingBall

	-- 2. หน้าต่างเลือกภาษาหลัก (Language Selection Card)
	local card = Instance.new("Frame")
	card.Name = "LanguageCard"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Size = UDim2.fromOffset(360, 220)
	card.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
	card.BorderSizePixel = 0
	card.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(68, 138, 255)
	stroke.Thickness = 1.5
	stroke.Parent = card

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -24, 0, 28)
	title.Position = UDim2.fromOffset(12, 16)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.TextColor3 = Color3.fromRGB(240, 245, 255)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Text = "SELECT LANGUAGE / เลือกภาษา"
	title.Parent = card

	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, -24, 0, 24)
	desc.Position = UDim2.fromOffset(12, 48)
	desc.BackgroundTransparency = 1
	desc.Font = Enum.Font.Gotham
	desc.TextSize, desc.TextColor3 = 12, Color3.fromRGB(165, 180, 210)
	desc.TextXAlignment = Enum.TextXAlignment.Center
	desc.Text = "กรุณาเลือกภาษาของสคริปต์ที่คุณต้องการใช้งาน"
	desc.Parent = card

	-- ปุ่มภาษาอังกฤษ (English Button)
	local engBtn = Instance.new("TextButton")
	engBtn.Name = "EnglishBtn"
	engBtn.Size = UDim2.new(1, -24, 0, 45)
	engBtn.Position = UDim2.fromOffset(12, 85)
	engBtn.BackgroundColor3 = Color3.fromRGB(35, 45, 70)
	engBtn.BorderSizePixel = 0
	engBtn.Font = Enum.Font.GothamBold
	engBtn.TextSize = 14
	engBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	engBtn.Text = "🇬🇧 ภาษาอังกฤษ (English Script)"
	engBtn.Parent = card

	local engCorner = Instance.new("UICorner")
	engCorner.CornerRadius = UDim.new(0, 10)
	engCorner.Parent = engBtn

	-- ปุ่มภาษาไทย (Thai Button)
	local thaiBtn = Instance.new("TextButton")
	thaiBtn.Name = "ThaiBtn"
	thaiBtn.Size = UDim2.new(1, -24, 0, 45)
	thaiBtn.Position = UDim2.fromOffset(12, 140)
	thaiBtn.BackgroundColor3 = Color3.fromRGB(35, 45, 70)
	engBtn.BorderSizePixel = 0
	thaiBtn.BorderSizePixel = 0
	thaiBtn.Font = Enum.Font.GothamBold
	thaiBtn.TextSize = 14
	thaiBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	thaiBtn.Text = "🇹🇭 ภาษาไทย (Thai Script)"
	thaiBtn.Parent = card

		-- ปุ่ม2ภาษา (TH/EN)
	local thaiBtn = Instance.new("TextButton")
	thaiBtn.Name = "ThaiBtn"
	thaiBtn.Size = UDim2.new(1, -24, 0, 45)
	thaiBtn.Position = UDim2.fromOffset(12, 140)
	thaiBtn.BackgroundColor3 = Color3.fromRGB(35, 45, 70)
	engBtn.BorderSizePixel = 0
	thaiBtn.BorderSizePixel = 0
	thaiBtn.Font = Enum.Font.GothamBold
	thaiBtn.TextSize = 14
	thaiBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	thaiBtn.Text = "🇹🇭🇬🇧 ภาษาไทยและอังกฤษ(HN/EN)"
	thaiBtn.Parent = card

	local thaiCorner = Instance.new("UICorner")
	thaiCorner.CornerRadius = UDim.new(0, 10)
	thaiCorner.Parent = thaiBtn

	-- ระบบเปิด-ปิดหน้าต่างด้วยลูกบอลลอยน้ำ
	local isOpen = true
	local function toggleUI()
		isOpen = not isOpen
		card.Visible = isOpen
	end
	floatingBall.MouseButton1Click:Connect(toggleUI)

	-- ทำให้ลูกบอลสามารถลากขยับไปมาบนหน้าจอได้ (Draggable Floating Ball)
	local dragging, dragInput, dragStart, startPos
	floatingBall.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = floatingBall.Position
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
			floatingBall.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	-- กดเลือกภาษาอังกฤษ
	engBtn.MouseButton1Click:Connect(function()
		screenGui:Destroy()
		VortexKeySystem.RunSelectedScript("English")
	end)

	-- กดเลือกภาษาไทย
	thaiBtn.MouseButton1Click:Connect(function()
		screenGui:Destroy()
		VortexKeySystem.RunSelectedScript("Thai")
	end)
end

	-- กดเลือก2 ภาษา
	thaiBtn.MouseButton1Click:Connect(function()
		screenGui:Destroy()
		VortexKeySystem.RunSelectedScript("TH/EN")
	end)
end

-- หน้าต่างกรอกคีย์ (Key Prompt UI)
local function mountKeyPromptUI()
	local parent = getGuiParent()
	if not parent then return end

	local old = parent:FindFirstChild("VortexKeyPromptGui")
	if old then
		old:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "VortexKeyPromptGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 999
	screenGui.Parent = parent

	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
	overlay.BackgroundTransparency = 0.35
	overlay.BorderSizePixel = 0
	overlay.Parent = screenGui

	local card = Instance.new("Frame")
	card.Name = "KeyCard"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Size = UDim2.fromOffset(360, 210)
	card.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
	card.BorderSizePixel = 0
	card.Parent = overlay

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(68, 138, 255)
	stroke.Thickness = 1.5
	stroke.Parent = card

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -24, 0, 28)
	title.Position = UDim2.fromOffset(12, 12)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.TextColor3 = Color3.fromRGB(240, 245, 255)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "VORTEX KEY SYSTEM"
	title.Parent = card

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -24, 0, 22)
	statusLabel.Position = UDim2.fromOffset(12, 40)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextSize = 12
	statusLabel.TextColor3 = Color3.fromRGB(165, 180, 210)
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Text = "กรุณากรอกคีย์เพื่อปลดล็อกระบบเลือกภาษา"
	statusLabel.Parent = card

	local inputBox = Instance.new("TextBox")
	inputBox.Name = "KeyInput"
	inputBox.Size = UDim2.new(1, -24, 0, 40)
	inputBox.Position = UDim2.fromOffset(12, 72)
	inputBox.BackgroundColor3 = Color3.fromRGB(11, 14, 22)
	inputBox.BorderSizePixel = 0
	inputBox.ClearTextOnFocus = false
	inputBox.Font = Enum.Font.Code
	inputBox.TextSize = 15
	inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	inputBox.PlaceholderText = "ใส่คีย์ที่นี่..."
	inputBox.PlaceholderColor3 = Color3.fromRGB(110, 122, 148)
	inputBox.Text = ""
	inputBox.Parent = card

	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 10)
	inputCorner.Parent = inputBox

	local submitBtn = Instance.new("TextButton")
	submitBtn.Name = "SubmitBtn"
	submitBtn.Size = UDim2.new(1, -24, 0, 40)
	submitBtn.Position = UDim2.fromOffset(12, 124)
	submitBtn.BackgroundColor3 = Color3.fromRGB(45, 118, 255)
	submitBtn.BorderSizePixel = 0
	submitBtn.Font = Enum.Font.GothamBold
	submitBtn.TextSize = 14
	submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	submitBtn.Text = "ยืนยันคีย์"
	submitBtn.Parent = card

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 10)
	btnCorner.Parent = submitBtn

	local hintLabel = Instance.new("TextLabel")
	hintLabel.Size = UDim2.new(1, -24, 0, 20)
	hintLabel.Position = UDim2.fromOffset(12, 174)
	hintLabel.BackgroundTransparency = 1
	hintLabel.Font = Enum.Font.Gotham
	hintLabel.TextSize = 11
	hintLabel.TextColor3 = Color3.fromRGB(120, 140, 175)
	hintLabel.TextXAlignment = Enum.TextXAlignment.Left
	hintLabel.Text = "Key: " .. VortexKeySystem.Key
	hintLabel.Parent = card

	local function handleSubmit()
		local rawInput = inputBox.Text
		local ok = VortexKeySystem.Authorize(rawInput)
		if ok then
			statusLabel.TextColor3 = Color3.fromRGB(95, 235, 155)
			statusLabel.Text = "เช็คคีย์สำเร็จ! กำลังเปิดเมนูเลือกภาษา..."
			submitBtn.Text = "สำเร็จ"
			task.delay(0.45, function()
				local tween = TweenService:Create(overlay, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundTransparency = 1
				})
				tween:Play()
				tween.Completed:Connect(function()
					if screenGui then
						screenGui:Destroy()
					end
					-- เปิดหน้าต่างเลือกภาษา พร้อมลูกบอลลอยน้ำ
					mountLanguageSelectorUI()
				end)
			end)
		else
			statusLabel.TextColor3 = Color3.fromRGB(255, 105, 105)
			statusLabel.Text = "คีย์ไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง"
			local origPos = card.Position
			for _, offsetX in ipairs({ -8, 8, -5, 5, 0 }) do
				card.Position = origPos + UDim2.fromOffset(offsetX, 0)
				task.wait(0.03)
			end
			card.Position = origPos
		end
	end

	submitBtn.MouseButton1Click:Connect(handleSubmit)
	inputBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			handleSubmit()
		end
	end)
end

function VortexKeySystem.Authorize(candidate)
	if VortexKeySystem.Validate(candidate) then
		if getgenv then
			getgenv().VORTEX_AUTH_VERIFIED = true
			getgenv().VORTEX_AUTH_KEY = VortexKeySystem.Key
			getgenv().VORTEX_KEY = VortexKeySystem.Key
		end
		print("[VORTEX KEY] Authorized with key: " .. VortexKeySystem.Key)
		return true
	end
	if getgenv then
		getgenv().VORTEX_AUTH_VERIFIED = false
	end
	warn("[VORTEX KEY] Authorization failed. Expected key: " .. VortexKeySystem.Key)
	return false
end

function VortexKeySystem.IsAuthorized()
	if VortexKeySystem.AllowDirectBypass then
		return true
	end
	if getgenv and getgenv().VORTEX_AUTH_VERIFIED == true and getgenv().VORTEX_AUTH_KEY == VortexKeySystem.Key then
		return true
	end
	return VortexKeySystem.Validate()
end

if getgenv then
	getgenv().VortexKeySystem = VortexKeySystem
end

-- เริ่มต้นการทำงาน: เช็คว่าผ่านการยืนยันคีย์มาแล้วหรือยัง
if VortexKeySystem.IsAuthorized() then
	mountLanguageSelectorUI()
else
	mountKeyPromptUI()
end

return VortexKeySystem
