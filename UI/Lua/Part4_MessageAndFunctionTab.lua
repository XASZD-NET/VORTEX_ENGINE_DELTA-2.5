-- ============================================================================
-- [ส่วนที่ 4] SCRIPT MESSAGE + SCRIPT FUNCTION และ TAB
-- ไฟล์: Part4_MessageAndFunctionTab.lua
-- ============================================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local UICore = _G.CustomUICore
local ui = _G.ScriptUI1
assert(UICore and ui, "กรุณารัน Part1 และ Part2 ก่อน!")

local MessageModule = {}
local FunctionTabModule = {
    Tabs = {},
    Functions = {}
}

-- สคริปต์ Message: ส่งข้อความแจ้งเตือนและส่งข้อมูลออกไปยังลิงก์
function MessageModule:Send(text, targetLink)
    print("[Message]: " .. tostring(text))
    if targetLink then
        pcall(function()
            UICore.HttpRequest(targetLink, "POST", {
                message = text,
                fromCamp = ui.Config.CampName,
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
                    result = result
                })
            end)
        end
        return result
    end
end

_G.MessageModule = MessageModule
_G.FunctionTabModule = FunctionTabModule
return {
    MessageModule = MessageModule,
    FunctionTabModule = FunctionTabModule
}
