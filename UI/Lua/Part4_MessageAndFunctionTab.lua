-- ============================================================================
-- [ส่วนที่ 4] SCRIPT MESSAGE + SCRIPT FUNCTION และ TAB (เชื่อมพอร์ต 3 <-> พอร์ต 5)
-- ไฟล์: Part4_MessageAndFunctionTab.lua
-- ============================================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ลิงก์ของพอร์ตที่ 3 (UI 2)
local Part3_Link = "https://raw.githubusercontent.com/XASZD-NET/VORTEX_ENGINE_DELTA-2.5/refs/heads/main/UI/Lua/Part3_ScriptUI2.lua"

-- [ใส่ลิงก์พอร์ตที่ 5 ตรงนี้ได้เลย]
local Part5_Link = "https://raw.githubusercontent.com/XASZD-NET/VORTEX_ENGINE_DELTA-2.5/refs/heads/main/UI/Lua/Part5_PingPongRelay.lua" -- ตัวอย่าง: "https://raw.githubusercontent.com/.../Part5_PingPongRelay.lua"

-- โหลดพอร์ตที่ 3 อัตโนมัติหากยังไม่มีในระบบ
if not _G.ScriptUI2 then
    loadstring(game:HttpGet(Part3_Link))()
end

-- โหลดพอร์ตที่ 5 อัตโนมัติหากมีการใส่ลิงก์ Part5_Link ไว้และยังไม่ถูกโหลด
if Part5_Link ~= "" and not _G.Part5Loaded then
    loadstring(game:HttpGet(Part5_Link))()
    _G.Part5Loaded = true
end

local UICore = _G.CustomUICore
local ui = _G.ScriptUI1
local ui2 = _G.ScriptUI2
assert(UICore and ui and ui2, "กรุณาตรวจสอบให้แน่ใจว่าพอร์ต 1, 2 และ 3 โหลดครบแล้ว!")

local MessageModule = {}
local FunctionTabModule = {
    Tabs = {},
    Functions = {},
    Bridge = {
        Part3Url = Part3_Link,
        Part5Url = Part5_Link,
        UI2Ref = ui2,
        RelayReady = false
    }
}

-- ฟังก์ชันตั้งค่า/อัปเดตลิงก์พอร์ตที่ 5 ได้ภายหลัง
function FunctionTabModule:SetPart5Link(linkUrl, autoLoad)
    self.Bridge.Part5Url = linkUrl or ""
    Part5_Link = self.Bridge.Part5Url
    if autoLoad and Part5_Link ~= "" and not _G.Part5Loaded then
        loadstring(game:HttpGet(Part5_Link))()
        _G.Part5Loaded = true
    end
    return self:ConnectPart3ToPart5()
end

-- ฟังก์ชันเชื่อมต่อพอร์ตที่ 3 เข้ากับวงจรพอร์ตที่ 5
function FunctionTabModule:ConnectPart3ToPart5()
    self.Bridge.UI2Ref = _G.ScriptUI2 or ui2
    self.Bridge.Part5Url = Part5_Link
    self.Bridge.RelayReady = (type(ui.StartPingPongRelay) == "function")
    return self.Bridge.RelayReady
end

-- สคริปต์ Message: ส่งข้อความแจ้งเตือนและส่งข้อมูลออกไปยังลิงก์
function MessageModule:Send(text, targetLink)
    print("[Message]: " .. tostring(text))
    if targetLink then
        pcall(function()
            UICore.HttpRequest(targetLink, "POST", {
                message = text,
                fromCamp = ui.Config.CampName,
                ui2Logo = ui2.Assets and ui2.Assets.UILogoIconLink or nil,
                part5Url = Part5_Link,
                player = LocalPlayer.Name
            })
        end)
    end
end

-- สคริปต์ Tab: สร้าง Tab ปุ่มคำสั่งบนหน้าต่าง UI
function FunctionTabModule:CreateTab(tabName, onSelectCallback)
    self.Tabs[tabName] = onSelectCallback or function() end

    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(1, 0, 0, 42)
    tabBtn.BackgroundColor3 = Color3.fromRGB(32, 24, 78)
    tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.TextSize = 15
    tabBtn.Text = "📑 " .. tabName
    tabBtn.Parent = UICore.Elements.ContentContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = tabBtn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(100, 70, 255)
    stroke.Thickness = 1.5
    stroke.Parent = tabBtn

    tabBtn.MouseButton1Click:Connect(function()
        MessageModule:Send("เปิด Tab: " .. tabName, ui.Config.LinkToUI2)
        self.Tabs[tabName]()
    end)

    return tabBtn
end

-- สคริปต์ Function: ลงทะเบียนและรันฟังก์ชันพร้อมตีกลับผลลัพธ์ไปยังลิงก์
function FunctionTabModule:RegisterFunction(fnName, fnHandler)
    self.Functions[fnName] = fnHandler
end

function FunctionTabModule:RunFunction(fnName, ...)
    local fn = self.Functions[fnName]
    if fn then
        local result = fn(...)
        if ui.Config.LinkFromUI2 then
            pcall(function()
                UICore.HttpRequest(ui.Config.LinkFromUI2, "POST", {
                    direction = "FUNCTION_RESULT_BOUNCE",
                    fnName = fnName,
                    result = result,
                    fromPart3 = Part3_Link,
                    toPart5 = Part5_Link
                })
            end)
        end
        return result
    end
end

FunctionTabModule:ConnectPart3ToPart5()

_G.MessageModule = MessageModule
_G.FunctionTabModule = FunctionTabModule

return {
    MessageModule = MessageModule,
    FunctionTabModule = FunctionTabModule
}
