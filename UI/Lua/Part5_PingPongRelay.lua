-- ============================================================================
-- [ส่วนที่ 5] PING-PONG LINK RELAY: วงจรสลับลิงก์ตีกลับไปมา (UI 1 <-> UI 2)
-- ไฟล์: Part5_PingPongRelay.lua
-- ============================================================================
local UICore = _G.CustomUICore
local ui = _G.ScriptUI1
local ui2 = _G.ScriptUI2
local FunctionTabModule = _G.FunctionTabModule

assert(UICore and ui and ui2 and FunctionTabModule, "กรุณารัน Part1 ถึง Part4 ให้ครบก่อน!")

-- ฟังก์ชันเริ่มวงจรตีกลับลิงก์ไปมาระหว่าง UI 1 และ UI 2
function ui:StartPingPongRelay(initialPayload)
    if self.Config.Running then return end
    self.Config.Running = true

    task.spawn(function()
        local currentPacket = initialPayload or {
            from = "UI_1",
            camp = self.Config.CampName,
            by = self.Config.ByAuthor,
            subLink = self.Config.BySubLink,
            step = 1
        }

        while self.Config.Running do
            -- [->] ส่งจาก UI 1 ไปยังลิงก์ฝั่ง UI 2
            local responseFromUI2 = UICore.HttpRequest(self.Config.LinkToUI2, "POST", {
                direction = "UI1_TO_UI2",
                data = currentPacket
            })

            local localBounce = ui2:HandleIncomingAndBounce(responseFromUI2 or currentPacket)

            -- [<-] ตีกลับจากลิงก์ฝั่ง UI 2 มายัง UI 1
            local bounceBackData = UICore.HttpRequest(self.Config.LinkFromUI2, "POST", {
                direction = "BOUNCE_BACK_TO_UI1",
                receivedFromUI2 = localBounce,
                step = (currentPacket.step or 0) + 1
            })

            currentPacket = {
                from = "UI_1_BOUNCED",
                camp = self.Config.CampName,
                by = self.Config.ByAuthor,
                subLink = self.Config.BySubLink,
                bounceResult = bounceBackData,
                step = (currentPacket.step or 0) + 2
            }

            task.wait(self.Config.Interval)
        end
    end)
end

function ui:StopPingPongRelay()
    self.Config.Running = false
end

-- สร้างปุ่ม Tab ควบคุมการเริ่ม/หยุดตีกลับลิงก์บนหน้า UI
FunctionTabModule:CreateTab("เริ่มระบบตีกลับลิงก์ (Start Ping-Pong Relay)", function()
    ui:StartPingPongRelay({ init = "started" })
end)

FunctionTabModule:CreateTab("หยุดระบบตีกลับลิงก์ (Stop Relay)", function()
    ui:StopPingPongRelay()
end)

return ui
