-- ============================================================================
-- [ส่วนที่ 3] SCRIPT UI 2: โลโก้ลูกบอลลอยน้ำ & ลิงก์ Logo Icon ใน UI
-- ไฟล์: Part3_ScriptUI2.lua
-- ============================================================================
local UICore = _G.CustomUICore
assert(UICore, "กรุณารัน Part1_UICore.lua ก่อน!")

local ui2 = {}

ui2.Assets = {
    FloatingBallLogo = "https://cdn.phototourl.com/member/2026-11-19-362b148f-bee1-4c27-8e11-c371a003573e.jpg",
    UILogoIconLink   = "https://cdn.phototourl.com/member/2026-11-19-362b148f-bee1-4c27-8e11-c371a003573e.jpg",
    IconTargetUrl    = "https://your-logo-icon-destination.example"
}

-- ตั้งค่าโลโก้ลูกบอลลอยน้ำ และลิงก์ Logo Icon ใน UI
function ui2:ApplyLogos(ballLogo, uiIconLink, iconTargetUrl)
    if ballLogo then self.Assets.FloatingBallLogo = ballLogo end
    if uiIconLink then self.Assets.UILogoIconLink = uiIconLink end
    if iconTargetUrl then self.Assets.IconTargetUrl = iconTargetUrl end

    UICore.Elements.FloatingBall.Image = self.Assets.FloatingBallLogo
    UICore.Elements.LogoImage.Image = self.Assets.UILogoIconLink
end

-- คลิกที่ Logo Icon ใน UI เพื่อคัดลอกลิงก์ปลายทาง
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

_G.ScriptUI2 = ui2
return ui2
