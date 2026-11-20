-- ============================================================================
-- [ส่วนที่ 3] SCRIPT UI 2: โลโก้ลูกบอลลอยน้ำ, ลิงก์ Logo Icon และเชื่อมลิงก์ Part 2
-- ไฟล์: Part3_ScriptUI2.lua
-- ============================================================================

-- [1. ส่วนหัว: ตรวจสอบและโหลดลิงก์ Part 1 และ Part 2 เข้ามาอัตโนมัติ]
local Part1_Link = "https://raw.githubusercontent.com/XASZD-NET/VORTEX_ENGINE_DELTA-2.5/refs/heads/main/UI/Lua/Part1_UICore.lua"
local Part2_Link = "https://raw.githubusercontent.com/XASZD-NET/VORTEX_ENGINE_DELTA-2.5/refs/heads/main/UI/Lua/Part2_ScriptUI1.lua"

if not _G.CustomUICore then
    loadstring(game:HttpGet(Part1_Link))()
end

if not _G.ScriptUI1 then
    loadstring(game:HttpGet(Part2_Link))()
end

local UICore = _G.CustomUICore
local ui = _G.ScriptUI1
assert(UICore and ui, "โหลด Part 1 หรือ Part 2 ไม่สำเร็จ กรุณาเช็กลิงก์!")

-- [2. ส่วนกลาง: ตั้งค่าโลโก้ลูกบอลลอยน้ำ & ลิงก์ Logo Icon ใน UI]
local ui2 = {}

ui2.Assets = {
    Part2ScriptUrl   = Part2_Link, -- เก็บลิงก์ของ Part 2 ไว้ในระบบ UI 2
    FloatingBallLogo = "https://cdn.phototourl.com/member/2026-11-19-362b148f-bee1-4c27-8e11-c371a003573e.jpg",
    UILogoIconLink   = "https://cdn.phototourl.com/member/2026-11-19-362b148f-bee1-4c27-8e11-c371a003573e.jpg",
    IconTargetUrl    = "https://your-logo-icon-destination.example"
}

function ui2:ApplyLogos(ballLogo, uiIconLink, iconTargetUrl)
    if ballLogo then self.Assets.FloatingBallLogo = ballLogo end
    if uiIconLink then self.Assets.UILogoIconLink = uiIconLink end
    if iconTargetUrl then self.Assets.IconTargetUrl = iconTargetUrl end

    UICore.Elements.FloatingBall.Image = self.Assets.FloatingBallLogo
    UICore.Elements.LogoImage.Image = self.Assets.UILogoIconLink
end

UICore.Elements.LogoImage.MouseButton1Click:Connect(function()
    if setclipboard and ui2.Assets.IconTargetUrl then
        setclipboard(ui2.Assets.IconTargetUrl)
        print("[UI 2] คัดลอกลิงก์ Logo Icon แล้ว:", ui2.Assets.IconTargetUrl)
    end
end)

-- รับข้อมูลจากฝั่ง UI 1 แล้วเตรียมแพ็กเกจตีกลับ
function ui2:HandleIncomingAndBounce(incomingData)
    return {
        handledBy = "UI_2",
        part2Source = self.Assets.Part2ScriptUrl,
        floatingBallLogo = self.Assets.FloatingBallLogo,
        uiLogoIconLink = self.Assets.UILogoIconLink,
        echo = incomingData,
        timestamp = os.time()
    }
end

-- ตั้งค่าโลโก้เริ่มต้น
ui2:ApplyLogos(
    "https://cdn.phototourl.com/member/2026-11-19-362b148f-bee1-4c27-8e11-c371a003573e.jpg",
    "https://cdn.phototourl.com/member/2026-11-19-362b148f-bee1-4c27-8e11-c371a003573e.jpg",
    "https://your-logo-icon-destination.example"
)

-- [3. ส่วนท้าย: ส่งค่า UI 2 กลับเข้าตัวแปรหลัก _G และเชื่อมกับ Part 2]
_G.ScriptUI2 = ui2
ui.LinkedUI2 = ui2 -- ผูกให้ Part 2 มองเห็น Part 3 อัตโนมัติ

return ui2
