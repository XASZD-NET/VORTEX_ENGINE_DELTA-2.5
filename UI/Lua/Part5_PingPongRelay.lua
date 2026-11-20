-- ============================================================================
-- [ส่วนที่ 5] PING-PONG LINK RELAY: เชื่อมพอร์ตที่ 1 <-> พอร์ตที่ 4 และตีกลับลิงก์
-- ไฟล์: Part5_PingPongRelay.lua
-- ============================================================================

-- [1. ส่วนหัว: ลิงก์ของพอร์ตที่ 1 และพอร์ตที่ 4]
local Part1_Link = "https://raw.githubusercontent.com/XASZD-NET/VORTEX_ENGINE_DELTA-2.5/refs/heads/main/UI/Lua/Part1_UICore.lua"
local Part4_Link = "https://raw.githubusercontent.com/XASZD-NET/VORTEX_ENGINE_DELTA-2.5/refs/heads/main/UI/Lua/Part4_MessageAndFunctionTab.lua"

if not _G.CustomUICore then
    loadstring(game:HttpGet(Part1_Link))()
end

if not _G.FunctionTabModule then
    loadstring(game:HttpGet(Part4_Link))()
end

local UICore = _G.CustomUICore
local ui = _G.ScriptUI1
local ui2 = _G.ScriptUI2
local MessageModule = _G.MessageModule
local FunctionTabModule = _G.FunctionTabModule

assert(UICore and FunctionTabModule, "กรุณาตรวจสอบให้แน่ใจว่าพอร์ตที่ 1 และพอร์ตที่ 4 โหลดครบแล้ว!")

-- [2. ส่วนกลาง: ตัวเชื่อมระหว่างพอร์ตที่ 1 (UICore) กับพอร์ตที่ 4 (FunctionTabModule)]
local RelayBridge = {
    Part1Url = Part1_Link,
    Part4Url = Part4_Link,
    UICoreRef = UICore,
    Part4Ref = FunctionTabModule,
    Connected = false
}

function RelayBridge:ConnectPart1AndPart4()
    self.UICoreRef = _G.CustomUICore or UICore
    self.Part4Ref = _G.FunctionTabModule or FunctionTabModule
    self.Connected = (self.UICoreRef ~= nil and self.Part4Ref ~= nil)

    if self.Part4Ref and self.Part4Ref.Bridge then
        self.Part4Ref.Bridge.Part1Url = self.Part1Url
        self.Part4Ref.Bridge.Part4Url = self.Part4Url
        self.Part4Ref.Bridge.Part5Connected = self.Connected
    end

    return self.Connected
end

RelayBridge:ConnectPart1AndPart4()
_G.RelayBridgePart1ToPart4 = RelayBridge

-- [3. ส่วนท้าย: วงจรตีกลับไปมา (พอร์ต 1 <-> พอร์ต 4 ผ่านลิงก์ต่อเนื่อง)]
if ui then
    ui.Config = ui.Config or {
        CampName = "ชื่อค่ายของคุณ",
        ByAuthor = "by ชื่อผู้จัดทำ",
        BySubLink = "https://link-under-by.example",
        LinkToUI2 = "https://endpoint-ui2.example/relay",
        LinkFromUI2 = "https://endpoint-ui1.example/relay",
        Interval = 2,
        Running = false
    }

    function ui:StartPingPongRelay(initialPayload)
        RelayBridge:ConnectPart1AndPart4()
        if self.Config.Running then return end
        self.Config.Running = true

        task.spawn(function()
            local currentPacket = initialPayload or {
                from = "Part1_UICore",
                bridgeTo = "Part4_MessageAndFunctionTab",
                part1Url = RelayBridge.Part1Url,
                part4Url = RelayBridge.Part4Url,
                camp = self.Config.CampName,
                by = self.Config.ByAuthor,
                subLink = self.Config.BySubLink,
                step = 1
            }

            while self.Config.Running do
                -- [->] ส่งจากฝั่งพอร์ต 1 -> พอร์ต 4 ไปยังลิงก์ปลายทางฝั่ง UI 2
                local responseFromUI2 = UICore.HttpRequest(self.Config.LinkToUI2, "POST", {
                    direction = "PART1_TO_PART4_TO_UI2",
                    part1Url = RelayBridge.Part1Url,
                    part4Url = RelayBridge.Part4Url,
                    data = currentPacket
                })

                local localBounce = ui2 and ui2:HandleIncomingAndBounce(responseFromUI2 or currentPacket) or {
                    handledBy = "Part5_Relay",
                    echo = responseFromUI2 or currentPacket,
                    timestamp = os.time()
                }

                -- [<-] ตีกลับจากฝั่งพอร์ต 4 -> พอร์ต 1 ผ่านลิงก์กลับ
                local bounceBackData = UICore.HttpRequest(self.Config.LinkFromUI2, "POST", {
                    direction = "BOUNCE_BACK_PART4_TO_PART1",
                    part1Url = RelayBridge.Part1Url,
                    part4Url = RelayBridge.Part4Url,
                    receivedFromUI2 = localBounce,
                    step = (currentPacket.step or 0) + 1
                })

                currentPacket = {
                    from = "Part1_BOUNCED_FROM_Part4",
                    part1Url = RelayBridge.Part1Url,
                    part4Url = RelayBridge.Part4Url,
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

    -- สร้างปุ่ม Tab ควบคุมบนหน้า UI ผ่านพอร์ตที่ 4
    FunctionTabModule:CreateTab("เริ่มระบบตีกลับลิงก์ (Start Ping-Pong Relay)", function()
        ui:StartPingPongRelay({ init = "started_part1_part4" })
    end)

    FunctionTabModule:CreateTab("หยุดระบบตีกลับลิงก์ (Stop Relay)", function()
        ui:StopPingPongRelay()
    end)
end

return RelayBridge
