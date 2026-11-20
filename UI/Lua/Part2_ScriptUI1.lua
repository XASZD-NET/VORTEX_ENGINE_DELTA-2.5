-- ============================================================================
-- [ส่วนที่ 2] SCRIPT UI 1: ตั้งชื่อค่าย, ใส่ลิงก์ใต้ผู้จัดทำ/by และคำสั่งรับเพื่อน
-- ไฟล์: Part2_ScriptUI1.lua
-- ============================================================================
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

local UICore = _G.CustomUICore
assert(UICore, "กรุณารัน Part1_UICore.lua ก่อน!")

local ui = {}

ui.Config = {
    CampName = "ชื่อค่ายของคุณ",
    ByAuthor = "by ชื่อผู้จัดทำ",
    BySubLink = "https://link-under-by.example",
    LinkToUI2 = "https://endpoint-ui2.example/relay",
    LinkFromUI2 = "https://endpoint-ui1.example/relay",
    Interval = 2,
    Running = false
}

-- ฟังก์ชันตั้งค่าชื่อค่าย, ผู้จัดทำ/by และลิงก์ใต้ผู้จัดทำ
function ui:SetUI1Info(campName, byText, subLink)
    self.Config.CampName = campName or self.Config.CampName
    self.Config.ByAuthor = byText or self.Config.ByAuthor
    self.Config.BySubLink = subLink or self.Config.BySubLink

    UICore.Elements.TitleLabel.Text = self.Config.CampName
    UICore.Elements.AuthorLabel.Text = self.Config.ByAuthor
    UICore.Elements.LinkButton.Text = "🔗 " .. self.Config.BySubLink
end

-- คลิกคัดลอกลิงก์ใต้คำว่าผู้จัดทำ
UICore.Elements.LinkButton.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(ui.Config.BySubLink)
        UICore.Elements.LinkButton.Text = "✅ คัดลอกลิงก์แล้ว!"
        task.wait(1.5)
        UICore.Elements.LinkButton.Text = "🔗 " .. ui.Config.BySubLink
    end
end)

-- คำสั่งรับเพื่อน / ส่งคำขอเป็นเพื่อน (Friend Command)
function ui:AddFriend(targetPlayerOrId)
    local targetPlayer = nil
    if typeof(targetPlayerOrId) == "Instance" and targetPlayerOrId:IsA("Player") then
        targetPlayer = targetPlayerOrId
    elseif type(targetPlayerOrId) == "number" then
        targetPlayer = Players:GetPlayerByUserId(targetPlayerOrId)
    elseif type(targetPlayerOrId) == "string" then
        targetPlayer = Players:FindFirstChild(targetPlayerOrId)
    end

    if targetPlayer and targetPlayer ~= LocalPlayer then
        StarterGui:SetCore("PromptSendFriendRequest", targetPlayer)
    end
end

-- ตั้งค่าเริ่มต้น
ui:SetUI1Info("ชื่อค่ายของคุณ", "by ชื่อผู้จัดทำ", "https://your-studio-link.example")

_G.ScriptUI1 = ui
return ui
