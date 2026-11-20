-- ============================================================================
-- [ส่วนที่ 1] UI CORE: หน้าต่างหลัก (600x800 / โทนม่วง-น้ำเงิน-ดำ) + ลูกบอลลอยน้ำ
-- ไฟล์: Part1_UICore.lua
-- ============================================================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ลบ UI เก่าหากมีการรันซ้ำ
if PlayerGui:FindFirstChild("CustomPurpleBlueUI") then
    PlayerGui.CustomPurpleBlueUI:Destroy()
end

local UICore = {}

-- ฟังก์ชันพื้นฐาน: ระบบลาก (Draggable)
function UICore.MakeDraggable(guiObject, dragHandle)
    local dragging, dragInput, dragStart, startPos
    dragHandle = dragHandle or guiObject

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ฟังก์ชันพื้นฐาน: ระบบส่งคำสั่ง HTTP Request
function UICore.HttpRequest(url, method, bodyTable)
    if not url or url == "" then return nil end
    local payload = bodyTable and HttpService:JSONEncode(bodyTable) or nil
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if req then
        local ok, res = pcall(function()
            return req({
                Url = url,
                Method = method or "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = payload
            })
        end)
        return ok and res and res.Body or nil
    else
        local ok, res = pcall(function()
            if method == "GET" then
                return HttpService:GetAsync(url)
            else
                return HttpService:PostAsync(url, payload or "{}", Enum.HttpContentType.ApplicationJson)
            end
        end)
        return ok and res or nil
    end
end

-- สร้าง ScreenGui หลัก
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CustomPurpleBlueUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- หน้าต่างหลัก (Main Window - 600 x 800 พิกเซล)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 600, 0, 800)
MainFrame.Position = UDim2.new(0.5, -300, 0.5, -400)
MainFrame.BackgroundColor3 = Color3.fromRGB(14, 12, 28)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(98, 54, 255)
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainGradient = Instance.new("UIGradient")
MainGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0.0, Color3.fromRGB(28, 18, 58)),  -- ม่วงเข้ม
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(14, 22, 52)),  -- น้ำเงินเข้ม
    ColorSequenceKeypoint.new(1.0, Color3.fromRGB(8, 8, 16))     -- ดำสนิท
}
MainGradient.Rotation = 45
MainGradient.Parent = MainFrame

-- แถบด้านบน (Top Header Bar)
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 110)
TopBar.BackgroundColor3 = Color3.fromRGB(18, 15, 38)
TopBar.BackgroundTransparency = 0.2
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopDivider = Instance.new("Frame")
TopDivider.Size = UDim2.new(1, 0, 0, 2)
TopDivider.Position = UDim2.new(0, 0, 1, -2)
TopDivider.BackgroundColor3 = Color3.fromRGB(75, 45, 190)
TopDivider.BorderSizePixel = 0
TopDivider.Parent = TopBar

-- รูปค่ายฝั่งซ้าย (Logo Icon ใน UI)
local LogoImage = Instance.new("ImageButton")
LogoImage.Name = "StudioLogo"
LogoImage.Size = UDim2.new(0, 85, 0, 85)
LogoImage.Position = UDim2.new(0, 15, 0.5, -42.5)
LogoImage.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
LogoImage.Image = "https://cdn.phototourl.com/member/2026-11-19-362b148f-bee1-4c27-8e11-c371a003573e.jpg"
LogoImage.ScaleType = Enum.ScaleType.Crop
LogoImage.Parent = TopBar

local LogoCorner = Instance.new("UICorner")
LogoCorner.CornerRadius = UDim.new(0, 12)
LogoCorner.Parent = LogoImage

local LogoStroke = Instance.new("UIStroke")
LogoStroke.Color = Color3.fromRGB(120, 80, 255)
LogoStroke.Thickness = 2
LogoStroke.Parent = LogoImage

-- กล่องข้อความฝั่งขวาของรูปค่าย
local InfoContainer = Instance.new("Frame")
InfoContainer.Name = "InfoContainer"
InfoContainer.Size = UDim2.new(1, -240, 0, 90)
InfoContainer.Position = UDim2.new(0, 115, 0.5, -45)
InfoContainer.BackgroundTransparency = 1
InfoContainer.Parent = TopBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "StudioTitle"
TitleLabel.Size = UDim2.new(1, 0, 0, 32)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "ชื่อค่ายของคุณ"
TitleLabel.TextColor3 = Color3.fromRGB(230, 220, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 22
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = InfoContainer

local AuthorLabel = Instance.new("TextLabel")
AuthorLabel.Name = "AuthorName"
AuthorLabel.Size = UDim2.new(1, 0, 0, 24)
AuthorLabel.Position = UDim2.new(0, 0, 0, 34)
AuthorLabel.BackgroundTransparency = 1
AuthorLabel.Text = "by ชื่อผู้จัดทำ"
AuthorLabel.TextColor3 = Color3.fromRGB(150, 170, 255)
AuthorLabel.Font = Enum.Font.GothamSemibold
AuthorLabel.TextSize = 15
AuthorLabel.TextXAlignment = Enum.TextXAlignment.Left
AuthorLabel.Parent = InfoContainer

local LinkButton = Instance.new("TextButton")
LinkButton.Name = "StudioLink"
LinkButton.Size = UDim2.new(1, 0, 0, 24)
LinkButton.Position = UDim2.new(0, 0, 0, 60)
LinkButton.BackgroundTransparency = 1
LinkButton.Text = "🔗 https://your-studio-link.example"
LinkButton.TextColor3 = Color3.fromRGB(110, 200, 255)
LinkButton.Font = Enum.Font.Gotham
LinkButton.TextSize = 14
LinkButton.TextXAlignment = Enum.TextXAlignment.Left
LinkButton.Parent = InfoContainer

-- ปุ่มควบคุมมุมขวาบนสุดตรงขอบ [—][🔳][❎]
local ControlsFrame = Instance.new("Frame")
ControlsFrame.Name = "WindowControls"
ControlsFrame.Size = UDim2.new(0, 114, 0, 34)
ControlsFrame.Position = UDim2.new(1, -114, 0, 0)
ControlsFrame.BackgroundTransparency = 1
ControlsFrame.Parent = TopBar

local function CreateControlBtn(symbol, posX, hoverColor)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 38, 0, 34)
    btn.Position = UDim2.new(0, posX, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(25, 20, 50)
    btn.BackgroundTransparency = 0.3
    btn.BorderSizePixel = 0
    btn.Text = symbol
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.Parent = ControlsFrame

    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = hoverColor
        btn.BackgroundTransparency = 0
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(25, 20, 50)
        btn.BackgroundTransparency = 0.3
    end)
    return btn
end

local MinBtn = CreateControlBtn("—", 0, Color3.fromRGB(70, 90, 200))
local MaxBtn = CreateControlBtn("🔳", 38, Color3.fromRGB(110, 60, 220))
local CloseBtn = CreateControlBtn("❎", 76, Color3.fromRGB(210, 50, 70))

local isMaximized = false
local normalSize = UDim2.new(0, 600, 0, 800)
local normalPos = UDim2.new(0.5, -300, 0.5, -400)

MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

MaxBtn.MouseButton1Click:Connect(function()
    isMaximized = not isMaximized
    if isMaximized then
        normalSize = MainFrame.Size
        normalPos = MainFrame.Position
        MainFrame.Size = UDim2.new(0.9, 0, 0.9, 0)
        MainFrame.Position = UDim2.new(0.05, 0, 0.05, 0)
    else
        MainFrame.Size = normalSize
        MainFrame.Position = normalPos
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

UICore.MakeDraggable(MainFrame, TopBar)

-- พื้นที่โล่งสำหรับใส่ฟังก์ชันและ Tab
local ContentContainer = Instance.new("ScrollingFrame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Size = UDim2.new(1, -24, 1, -125)
ContentContainer.Position = UDim2.new(0, 12, 0, 118)
ContentContainer.BackgroundTransparency = 1
ContentContainer.BorderSizePixel = 0
ContentContainer.ScrollBarThickness = 4
ContentContainer.ScrollBarImageColor3 = Color3.fromRGB(110, 70, 255)
ContentContainer.Parent = MainFrame

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 10)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = ContentContainer

-- ลูกบอลลอยน้ำ (Watermark วงกลมขอบสีดำ ลากได้)
local FloatingBall = Instance.new("ImageButton")
FloatingBall.Name = "FloatingWatermark"
FloatingBall.Size = UDim2.new(0, 65, 0, 65)
FloatingBall.Position = UDim2.new(0.05, 0, 0.2, 0)
FloatingBall.BackgroundColor3 = Color3.fromRGB(15, 12, 30)
FloatingBall.Image = "https://cdn.phototourl.com/member/2026-11-19-362b148f-bee1-4c27-8e11-c371a003573e.jpg"
FloatingBall.ScaleType = Enum.ScaleType.Crop
FloatingBall.ZIndex = 10
FloatingBall.Parent = ScreenGui

local BallCorner = Instance.new("UICorner")
BallCorner.CornerRadius = UDim.new(1, 0)
BallCorner.Parent = FloatingBall

local BallStroke = Instance.new("UIStroke")
BallStroke.Color = Color3.fromRGB(0, 0, 0)
BallStroke.Thickness = 4
BallStroke.Parent = FloatingBall

UICore.MakeDraggable(FloatingBall)

FloatingBall.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- เก็บอ้างอิง Element ทั้งหมดไว้ให้ส่วนที่ 2-5 เรียกใช้ได้
UICore.Elements = {
    ScreenGui = ScreenGui,
    MainFrame = MainFrame,
    TopBar = TopBar,
    LogoImage = LogoImage,
    TitleLabel = TitleLabel,
    AuthorLabel = AuthorLabel,
    LinkButton = LinkButton,
    ContentContainer = ContentContainer,
    FloatingBall = FloatingBall
}

_G.CustomUICore = UICore
return UICore
