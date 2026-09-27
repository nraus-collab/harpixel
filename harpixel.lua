--[[
    @title:       Scripts HAR Hub PRO
    @author:      Hờ A Rầu
    @version:     4.0 PRO
    @description: Tab Main / PvP / Setting. Fruit ESP tối ưu chống lag.
]]--

-- ============================================================
--  1. SERVICES
-- ============================================================
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local TeleportService  = game:GetService("TeleportService")
local camera           = workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer

-- ============================================================
--  2. GLOBALS
-- ============================================================
_G.SpeedEnabled        = false ; _G.SpeedValue       = 130
_G.JumpEnabled         = false ; _G.JumpPowerValue   = 130
_G.DashEnabled         = false ; _G.DashDist         = 4
_G.HitboxEnabled       = false ; _G.HitboxSize       = 5
_G.InfiniteJumpEnabled = false
_G.ESPEnabled          = false
_G.AutoTeleEnabled     = false
_G.OriginalParts       = {}
_G.FruitESPEnabled     = false
_G.FruitTweenEnabled   = false
_G.FruitTweenSpeed     = 120

-- ============================================================
--  3. THEME
-- ============================================================
local T = {
    BG      = Color3.fromRGB(8,   8,  14),
    BG2     = Color3.fromRGB(13,  13,  22),
    PANEL   = Color3.fromRGB(18,  18,  30),
    RED     = Color3.fromRGB(220,  30,  70),
    RED2    = Color3.fromRGB(255,  80, 110),
    TAB_ON  = Color3.fromRGB(200,  20,  55),
    TAB_OFF = Color3.fromRGB(25,   25,  40),
    WHITE   = Color3.fromRGB(240, 240, 255),
    DIM     = Color3.fromRGB(140, 140, 170),
    GREEN   = Color3.fromRGB(20,  180, 110),
    GRAY    = Color3.fromRGB(50,   50,  70),
    STROKE  = Color3.fromRGB(55,   55,  85),
    YELLOW  = Color3.fromRGB(255, 200,  50),
}

-- ============================================================
--  4. UTILITY
-- ============================================================
local function corner(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = UDim.new(0, r or 8)
    return c
end

local function stroke(p, col, th)
    local s = Instance.new("UIStroke", p)
    s.Color = col or T.STROKE ; s.Thickness = th or 1
    return s
end

local function tw(obj, props, t, sty, dir)
    TweenService:Create(obj,
        TweenInfo.new(t or 0.18, sty or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props):Play()
end

-- Kéo frame qua dragZone (dùng InputBegan trên dragZone + global InputChanged)
local function makeDraggable(frame, dragZone)
    local dragging, dragStart, startPos = false, nil, nil
    dragZone.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = inp.Position
            startPos  = frame.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (
            inp.UserInputType == Enum.UserInputType.MouseMovement or
            inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ============================================================
--  5. LOGIC: RESET HITBOX
-- ============================================================
local function resetHitbox()
    for part, data in pairs(_G.OriginalParts) do
        if part and part.Parent then
            part.Size         = data.Size
            part.Transparency = data.Transparency
            part.Color        = data.Color
            part.CanCollide   = data.CanCollide
        end
    end
    _G.OriginalParts = {}
end

-- ============================================================
--  6. LOGIC: PLAYER ESP
-- ============================================================
local function removeDot(p)
    if p.Character and p.Character:FindFirstChild("Head") then
        local h = p.Character.Head:FindFirstChild("DotESP")
        if h then h:Destroy() end
    end
end

local function createDot(p)
    if not _G.ESPEnabled or p == LocalPlayer then return end
    if not p.Character or not p.Character:FindFirstChild("Head") then return end
    removeDot(p)
    local head = p.Character.Head
    local bill = Instance.new("BillboardGui", head)
    bill.Name        = "DotESP"
    bill.Size        = UDim2.new(0, 160, 0, 50)
    bill.StudsOffset = Vector3.new(0, 3, 0)
    bill.AlwaysOnTop = true
    bill.LightInfluence = 0
    local lbl = Instance.new("TextLabel", bill)
    lbl.Size                  = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextScaled            = true
    lbl.Font                  = Enum.Font.GothamBold
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3      = Color3.new(0, 0, 0)
    lbl.TextColor3 = (p.Team and p.Team.Name:lower():find("marine"))
        and Color3.fromRGB(60, 180, 255) or T.RED2
    task.spawn(function()
        while bill.Parent and _G.ESPEnabled and task.wait(0.1) do
            local char = p.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local myR  = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hum and root and myR then
                local dist = math.floor((myR.Position - root.Position).Magnitude)
                lbl.Text = ("%s\n[%dm] HP:%d"):format(p.Name, dist, math.floor(hum.Health))
            else
                lbl.Text = p.Name
            end
        end
        bill:Destroy()
    end)
end

local function setupPlayer(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        if _G.ESPEnabled then createDot(p) end
    end)
end
for _, p in pairs(Players:GetPlayers()) do setupPlayer(p) end
Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(removeDot)

-- ============================================================
--  7. LOGIC: FRUIT ESP (TỐI ƯU - CHỐNG LAG)
--  Thay vì quét workspace mỗi frame → dùng bảng + sự kiện.
--  Cập nhật khoảng cách theo heartbeat 0.25s, không phải render.
-- ============================================================
local MythicalFruits  = {"gravity","mammoth","shadow","t-rex","mochi","venom","gas","control","tiger","kitsune","dragon"}
local LegendaryFruits = {"quake","buddha","love","spider","phoenix","portal","rumble","pain","blizzard"}

local function getFruitColor(name)
    name = name:lower()
    for _, v in pairs(MythicalFruits)  do if name:find(v) then return Color3.fromRGB(255, 60, 60)  end end
    for _, v in pairs(LegendaryFruits) do if name:find(v) then return Color3.fromRGB(210, 60, 255) end end
    return Color3.fromRGB(200, 200, 255)
end

local function isFruit(obj)
    return obj:IsA("Tool") and obj:FindFirstChild("Handle") and not obj:FindFirstChildOfClass("Humanoid")
end

-- Bảng lưu ESP theo obj
local FruitESPTable = {}

-- Tạo container ESP trong CoreGui (tránh bị xóa khi respawn)
local FruitESPHolder
do
    local ok, existing = pcall(function() return game.CoreGui:FindFirstChild("HAR_FruitHolder") end)
    if ok and existing then existing:Destroy() end
    FruitESPHolder = Instance.new("Folder", game.CoreGui)
    FruitESPHolder.Name = "HAR_FruitHolder"
end

local function createFruitESP(obj)
    if not isFruit(obj) or FruitESPTable[obj] then return end
    local bill = Instance.new("BillboardGui", FruitESPHolder)
    bill.Name        = "FruitESP"
    bill.Size        = UDim2.new(0, 200, 0, 50)
    bill.Adornee     = obj.Handle
    bill.AlwaysOnTop = true
    bill.Enabled     = false
    local txt = Instance.new("TextLabel", bill)
    txt.Size                   = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.TextStrokeTransparency = 0
    txt.TextScaled             = true
    txt.Font                   = Enum.Font.GothamBold
    txt.Text                   = obj.Name
    txt.TextColor3             = getFruitColor(obj.Name)
    FruitESPTable[obj] = { Bill = bill, Text = txt }
end

-- Quét lần đầu
for _, v in pairs(workspace:GetDescendants()) do
    createFruitESP(v)
end

-- Theo dõi object mới thêm vào
workspace.DescendantAdded:Connect(function(v)
    task.wait(0.1)
    createFruitESP(v)
end)

-- Dọn dẹp khi trái bị nhặt/xóa
workspace.DescendantRemoving:Connect(function(v)
    local data = FruitESPTable[v]
    if data then
        data.Bill:Destroy()
        FruitESPTable[v] = nil
    end
end)

-- Loop cập nhật ESP trái — chạy mỗi 0.25s (không mỗi frame!)
task.spawn(function()
    while true do
        task.wait(0.25)
        local char = LocalPlayer.Character
        local myR  = char and char:FindFirstChild("HumanoidRootPart")
        for obj, data in pairs(FruitESPTable) do
            if obj and obj.Parent and obj:FindFirstChild("Handle") and data.Bill and data.Bill.Parent then
                if _G.FruitESPEnabled then
                    data.Bill.Enabled = true
                    if myR then
                        local dist = math.floor((myR.Position - obj.Handle.Position).Magnitude)
                        data.Text.Text = ("🍎 %s [%dm]"):format(obj.Name, dist)
                    else
                        data.Text.Text = "🍎 " .. obj.Name
                    end
                    data.Text.TextColor3 = getFruitColor(obj.Name)
                else
                    data.Bill.Enabled = false
                end
            else
                if data and data.Bill and data.Bill.Parent then
                    data.Bill:Destroy()
                end
                FruitESPTable[obj] = nil
            end
        end
    end
end)

-- ============================================================
--  8. LOGIC: FRUIT TWEEN (STABIL)
-- ============================================================
local curFruitTween = nil
local tweenTarget   = nil

local function nearestFruit()
    local best, bd = nil, math.huge
    local char = LocalPlayer.Character
    local myR  = char and char:FindFirstChild("HumanoidRootPart")
    if not myR then return end
    for obj in pairs(FruitESPTable) do
        if obj and obj.Parent and obj:FindFirstChild("Handle") then
            local d = (myR.Position - obj.Handle.Position).Magnitude
            if d < bd then bd = d ; best = obj end
        end
    end
    return best, bd
end

task.spawn(function()
    while true do
        task.wait(0.3)
        if not _G.FruitTweenEnabled then
            if curFruitTween then curFruitTween:Cancel() ; curFruitTween = nil end
            tweenTarget = nil
            continue
        end
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        local fruit, dist = nearestFruit()

        if tweenTarget and tweenTarget ~= fruit then
            if curFruitTween then curFruitTween:Cancel() ; curFruitTween = nil end
        end

        if fruit and fruit:FindFirstChild("Handle") then
            if dist < 3 then
                if curFruitTween then curFruitTween:Cancel() ; curFruitTween = nil end
            else
                local time = dist / _G.FruitTweenSpeed
                time = math.clamp(time, 0.05, 5)
                if curFruitTween then curFruitTween:Cancel() end
                curFruitTween = TweenService:Create(
                    root,
                    TweenInfo.new(time, Enum.EasingStyle.Linear),
                    { CFrame = CFrame.new(fruit.Handle.Position) }
                )
                curFruitTween:Play()
                tweenTarget = fruit
            end
        else
            if curFruitTween then curFruitTween:Cancel() ; curFruitTween = nil end
            tweenTarget = nil
        end
    end
end)

-- ============================================================
--  9. VÒNG LẶP CHÍNH (RENDER LOOP)
-- ============================================================
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChild("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if hum and root then
        hum.WalkSpeed = _G.SpeedEnabled and _G.SpeedValue or 50
        if _G.JumpEnabled then
            hum.UseJumpPower = true
            hum.JumpPower    = _G.JumpPowerValue
        else
            hum.JumpPower = 50
        end
        if _G.DashEnabled and hum.MoveDirection.Magnitude > 0 then
            root.CFrame = root.CFrame + hum.MoveDirection * _G.DashDist
        end
        if _G.AutoTeleEnabled then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    root.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                    break
                end
            end
        end
    end
    if _G.HitboxEnabled then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local part = p.Character.HumanoidRootPart
                if not _G.OriginalParts[part] then
                    _G.OriginalParts[part] = {
                        Size = part.Size, Transparency = part.Transparency,
                        Color = part.Color, CanCollide = part.CanCollide
                    }
                end
                part.Size        = Vector3.new(_G.HitboxSize, _G.HitboxSize, _G.HitboxSize)
                part.Transparency = 0.7
                part.CanCollide  = false
            end
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if _G.InfiniteJumpEnabled and LocalPlayer.Character then
        local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ============================================================
--  10. GUI — HAR HUB PRO PIXEL EDITION
--  Chỉ thay đổi giao diện. Toàn bộ callback/logic phía trên giữ nguyên.
-- ============================================================

local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
gui.Name           = "HAR_Hub_Pro"
gui.ResetOnSpawn   = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = false

-- ============================================================
--  PIXEL UI HELPERS
-- ============================================================

local PX_FONT = Enum.Font.Arcade
local PX_FONT_BOLD = Enum.Font.Arcade

local function pxFrame(parent, size, pos, bg, z)
    local f = Instance.new("Frame", parent)
    f.Size = size
    f.Position = pos
    f.BackgroundColor3 = bg
    f.BorderSizePixel = 0
    f.ZIndex = z or 1
    return f
end

local function pxStroke(parent, color, thickness)
    local s = Instance.new("UIStroke", parent)
    s.Color = color
    s.Thickness = thickness or 1
    s.Transparency = 0
    return s
end

local function pxText(parent, text, size, color, fontSize, align, z)
    local l = Instance.new("TextLabel", parent)
    l.Size = size
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color
    l.Font = PX_FONT_BOLD
    l.TextSize = fontSize or 12
    l.TextXAlignment = align or Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.ZIndex = z or 2
    return l
end

local function pxButton(parent, size, pos, text, bg, z)
    local b = Instance.new("TextButton", parent)
    b.Size = size
    b.Position = pos
    b.BackgroundColor3 = bg
    b.BorderSizePixel = 0
    b.Text = text or ""
    b.TextColor3 = T.WHITE
    b.Font = PX_FONT_BOLD
    b.TextSize = 12
    b.AutoButtonColor = false
    b.ZIndex = z or 2
    return b
end

-- ============================================================
--  SMALL PIXEL MENU — luôn hiện, kéo được
-- ============================================================

local SmallMenu = pxFrame(
    gui,
    UDim2.new(0, 62, 0, 62),
    UDim2.new(0, 20, 0, 300),
    T.BG,
    30
)
pxStroke(SmallMenu, T.RED, 2)

local smAccentTop = pxFrame(
    SmallMenu,
    UDim2.new(1, -8, 0, 3),
    UDim2.new(0, 4, 0, 4),
    T.RED,
    31
)

local smAccentLeft = pxFrame(
    SmallMenu,
    UDim2.new(0, 3, 1, -14),
    UDim2.new(0, 4, 0, 10),
    T.RED,
    31
)

local smTop = pxText(
    SmallMenu, "HAR",
    UDim2.new(1, -8, 0, 25),
    T.RED2, 17,
    Enum.TextXAlignment.Center, 32
)
smTop.Position = UDim2.new(0, 4, 0, 9)

local smBot = pxText(
    SmallMenu, "HUB",
    UDim2.new(1, -8, 0, 18),
    T.DIM, 10,
    Enum.TextXAlignment.Center, 32
)
smBot.Position = UDim2.new(0, 4, 0, 35)

local smDot = pxFrame(
    SmallMenu,
    UDim2.new(0, 7, 0, 7),
    UDim2.new(1, -11, 0, 7),
    T.GREEN,
    33
)

local smHit = pxButton(
    SmallMenu,
    UDim2.new(1, 0, 1, 0),
    UDim2.new(0, 0, 0, 0),
    "",
    Color3.new(0, 0, 0),
    34
)
smHit.BackgroundTransparency = 1

makeDraggable(SmallMenu, smHit)

task.spawn(function()
    while true do
        for i = 1, 16 do
            smDot.BackgroundTransparency = 0.15 + (i / 16) * 0.55
            task.wait(0.05)
        end
        for i = 1, 16 do
            smDot.BackgroundTransparency = 0.70 - (i / 16) * 0.55
            task.wait(0.05)
        end
    end
end)

-- ============================================================
--  MAIN FRAME
-- ============================================================

local MainFrame = pxFrame(
    gui,
    UDim2.new(0, 610, 0, 410),
    UDim2.new(0, 94, 0, 300),
    T.BG,
    10
)
pxStroke(MainFrame, T.RED, 2)

-- Pixel outer accents
local outerTop = pxFrame(
    MainFrame,
    UDim2.new(1, -20, 0, 3),
    UDim2.new(0, 10, 0, 7),
    T.RED,
    11
)

local outerBottom = pxFrame(
    MainFrame,
    UDim2.new(1, -20, 0, 2),
    UDim2.new(0, 10, 1, -9),
    T.RED,
    11
)

local outerLeft = pxFrame(
    MainFrame,
    UDim2.new(0, 2, 1, -20),
    UDim2.new(0, 7, 0, 10),
    T.RED,
    11
)

local outerRight = pxFrame(
    MainFrame,
    UDim2.new(0, 2, 1, -20),
    UDim2.new(1, -9, 0, 10),
    T.RED,
    11
)

-- ============================================================
--  TOP BAR
-- ============================================================

local TopBar = pxFrame(
    MainFrame,
    UDim2.new(1, -20, 0, 54),
    UDim2.new(0, 10, 0, 10),
    T.BG2,
    12
)
pxStroke(TopBar, T.STROKE, 1)

local logoMark = pxFrame(
    TopBar,
    UDim2.new(0, 8, 0, 28),
    UDim2.new(0, 12, 0.5, -14),
    T.RED,
    14
)

local logo = pxText(
    TopBar,
    "HAR // HUB",
    UDim2.new(0, 185, 1, 0),
    T.WHITE, 17,
    Enum.TextXAlignment.Left, 14
)
logo.Position = UDim2.new(0, 30, 0, 0)

local subLogo = pxText(
    TopBar,
    "PIXEL CONTROL PANEL",
    UDim2.new(0, 190, 0, 14),
    T.RED2, 8,
    Enum.TextXAlignment.Left, 14
)
subLogo.Position = UDim2.new(0, 31, 1, -17)

local verBadge = pxFrame(
    TopBar,
    UDim2.new(0, 58, 0, 22),
    UDim2.new(0, 220, 0.5, -11),
    T.RED,
    14
)
pxStroke(verBadge, T.RED2, 1)

local verText = pxText(
    verBadge, "V4.0",
    UDim2.new(1, 0, 1, 0),
    T.WHITE, 10,
    Enum.TextXAlignment.Center, 15
)

local statusBox = pxFrame(
    TopBar,
    UDim2.new(0, 130, 0, 22),
    UDim2.new(1, -210, 0.5, -11),
    T.PANEL,
    14
)
pxStroke(statusBox, T.STROKE, 1)

local statusDot = pxFrame(
    statusBox,
    UDim2.new(0, 6, 0, 6),
    UDim2.new(0, 8, 0.5, -3),
    T.GREEN,
    15
)

local statusText = pxText(
    statusBox, "SYSTEM ONLINE",
    UDim2.new(1, -22, 1, 0),
    T.GREEN, 8,
    Enum.TextXAlignment.Center, 15
)
statusText.Position = UDim2.new(0, 16, 0, 0)

local closeBtn = pxButton(
    TopBar,
    UDim2.new(0, 34, 0, 34),
    UDim2.new(1, -44, 0.5, -17),
    "X",
    Color3.fromRGB(100, 18, 35),
    16
)
pxStroke(closeBtn, T.RED, 1)
closeBtn.TextSize = 15
closeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

local topDrag = pxButton(
    TopBar,
    UDim2.new(1, -48, 1, 0),
    UDim2.new(0, 0, 0, 0),
    "",
    Color3.new(0, 0, 0),
    13
)
topDrag.BackgroundTransparency = 1
makeDraggable(MainFrame, topDrag)

smHit.MouseButton1Click:Connect(function()
    if MainFrame.Visible then
        MainFrame.Visible = false
    else
        MainFrame.Position = UDim2.new(
            0,
            SmallMenu.AbsolutePosition.X + SmallMenu.AbsoluteSize.X + 10,
            0,
            SmallMenu.AbsolutePosition.Y
        )
        MainFrame.Visible = true
    end
end)

-- ============================================================
--  SIDEBAR
-- ============================================================

local SideBar = pxFrame(
    MainFrame,
    UDim2.new(0, 154, 1, -82),
    UDim2.new(0, 10, 0, 72),
    T.BG2,
    12
)
pxStroke(SideBar, T.STROKE, 1)

local sideTitle = pxText(
    SideBar,
    "NAVIGATION",
    UDim2.new(1, -20, 0, 22),
    T.RED2, 9,
    Enum.TextXAlignment.Left, 14
)
sideTitle.Position = UDim2.new(0, 12, 0, 8)

local sideLine = pxFrame(
    SideBar,
    UDim2.new(1, -24, 0, 1),
    UDim2.new(0, 12, 0, 34),
    T.STROKE,
    14
)

local TabList = Instance.new("Frame", SideBar)
TabList.Size = UDim2.new(1, -16, 1, -48)
TabList.Position = UDim2.new(0, 8, 0, 43)
TabList.BackgroundTransparency = 1
TabList.ZIndex = 13

local tlLayout = Instance.new("UIListLayout", TabList)
tlLayout.Padding = UDim.new(0, 7)
tlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tlLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- ============================================================
--  CONTENT AREA
-- ============================================================

local divider = pxFrame(
    MainFrame,
    UDim2.new(0, 2, 1, -82),
    UDim2.new(0, 171, 0, 72),
    T.RED,
    13
)

local ContentArea = pxFrame(
    MainFrame,
    UDim2.new(1, -193, 1, -82),
    UDim2.new(0, 183, 0, 72),
    Color3.new(0, 0, 0),
    12
)
ContentArea.BackgroundTransparency = 1

local footer = pxText(
    MainFrame,
    "HAR SYSTEM  //  READY",
    UDim2.new(0, 190, 0, 18),
    T.DIM, 8,
    Enum.TextXAlignment.Left, 14
)
footer.Position = UDim2.new(0, 184, 1, -31)

local authorLbl = pxText(
    MainFrame,
    "HỜ A RẦU",
    UDim2.new(0, 150, 0, 18),
    T.DIM, 8,
    Enum.TextXAlignment.Right, 14
)
authorLbl.Position = UDim2.new(1, -174, 1, -31)

-- ============================================================
--  TAB SYSTEM
-- ============================================================

local TabFrames, TabButtons, activeTab = {}, {}, nil

local function createTabContent(name)
    local scroll = Instance.new("ScrollingFrame", ContentArea)
    scroll.Size = UDim2.new(1, -4, 1, -22)
    scroll.Position = UDim2.new(0, 2, 0, 2)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = T.RED
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.BorderSizePixel = 0
    scroll.Visible = false
    scroll.ZIndex = 14

    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local pad = Instance.new("UIPadding", scroll)
    pad.PaddingTop = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 8)

    TabFrames[name] = scroll
    return scroll
end

local function createSideTab(name, icon)
    local btn = pxButton(
        TabList,
        UDim2.new(1, -8, 0, 43),
        UDim2.new(0, 4, 0, 0),
        "",
        T.TAB_OFF,
        14
    )
    pxStroke(btn, T.STROKE, 1)

    local activeBar = pxFrame(
        btn,
        UDim2.new(0, 3, 1, -8),
        UDim2.new(0, 0, 0, 4),
        T.RED,
        16
    )
    activeBar.BackgroundTransparency = 1

    local ic = pxText(
        btn,
        icon,
        UDim2.new(0, 34, 1, 0),
        T.DIM, 15,
        Enum.TextXAlignment.Center, 16
    )
    ic.Position = UDim2.new(0, 5, 0, 0)

    local nm = pxText(
        btn,
        name:upper(),
        UDim2.new(1, -46, 1, 0),
        T.DIM, 10,
        Enum.TextXAlignment.Left, 16
    )
    nm.Position = UDim2.new(0, 45, 0, 0)

    TabButtons[name] = {
        btn = btn,
        ic = ic,
        nm = nm,
        bar = activeBar
    }

    btn.MouseButton1Click:Connect(function()
        for n, d in pairs(TabButtons) do
            tw(d.btn, {BackgroundColor3 = T.TAB_OFF}, 0.12)
            d.ic.TextColor3 = T.DIM
            d.nm.TextColor3 = T.DIM
            d.bar.BackgroundTransparency = 1
            if TabFrames[n] then
                TabFrames[n].Visible = false
            end
        end

        tw(btn, {BackgroundColor3 = T.TAB_ON}, 0.12)
        ic.TextColor3 = T.WHITE
        nm.TextColor3 = T.WHITE
        activeBar.BackgroundTransparency = 0
        if TabFrames[name] then
            TabFrames[name].Visible = true
        end
        activeTab = name
    end)

    btn.MouseEnter:Connect(function()
        if activeTab ~= name then
            tw(btn, {BackgroundColor3 = Color3.fromRGB(34, 34, 52)}, 0.08)
        end
    end)

    btn.MouseLeave:Connect(function()
        if activeTab ~= name then
            tw(btn, {BackgroundColor3 = T.TAB_OFF}, 0.08)
        end
    end)

    return btn
end

-- ============================================================
--  PIXEL WIDGETS
-- ============================================================

local function createSection(parent, text)
    local h = Instance.new("Frame", parent)
    h.Size = UDim2.new(0.96, 0, 0, 28)
    h.BackgroundTransparency = 1
    h.ZIndex = 15

    local tag = pxFrame(
        h,
        UDim2.new(0, 5, 0, 14),
        UDim2.new(0, 0, 0.5, -7),
        T.RED,
        16
    )

    local lbl = pxText(
        h,
        text:upper(),
        UDim2.new(0.48, 0, 1, 0),
        T.RED2, 9,
        Enum.TextXAlignment.Left, 16
    )
    lbl.Position = UDim2.new(0, 12, 0, 0)

    local l1 = pxFrame(
        h,
        UDim2.new(0.40, 0, 0, 1),
        UDim2.new(0.52, 0, 0.5, 0),
        T.STROKE,
        16
    )

    local l2 = pxFrame(
        h,
        UDim2.new(0.04, 0, 0, 1),
        UDim2.new(0.96, 0, 0.5, 0),
        T.RED,
        16
    )
end

local function createToggle(parent, text, callback)
    local row = pxFrame(
        parent,
        UDim2.new(0.96, 0, 0, 46),
        UDim2.new(0, 0, 0, 0),
        T.PANEL,
        15
    )
    pxStroke(row, T.STROKE, 1)

    local leftMark = pxFrame(
        row,
        UDim2.new(0, 3, 0, 22),
        UDim2.new(0, 7, 0.5, -11),
        T.STROKE,
        16
    )

    local lbl = pxText(
        row,
        text,
        UDim2.new(1, -80, 1, 0),
        T.WHITE, 10,
        Enum.TextXAlignment.Left, 16
    )
    lbl.Position = UDim2.new(0, 18, 0, 0)

    local stateBox = pxFrame(
        row,
        UDim2.new(0, 54, 0, 24),
        UDim2.new(1, -66, 0.5, -12),
        T.GRAY,
        16
    )
    pxStroke(stateBox, T.STROKE, 1)

    local stateText = pxText(
        stateBox,
        "OFF",
        UDim2.new(1, 0, 1, 0),
        T.DIM, 8,
        Enum.TextXAlignment.Center, 18
    )

    local knob = pxFrame(
        stateBox,
        UDim2.new(0, 7, 0, 16),
        UDim2.new(0, 4, 0.5, -8),
        T.WHITE,
        18
    )

    local state = false
    local startPos = nil

    local hitBtn = pxButton(
        row,
        UDim2.new(1, 0, 1, 0),
        UDim2.new(0, 0, 0, 0),
        "",
        Color3.new(0, 0, 0),
        19
    )
    hitBtn.BackgroundTransparency = 1

    hitBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            startPos = inp.Position
        end
    end)

    hitBtn.InputEnded:Connect(function(inp)
        if (inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch) and startPos then
            local diff = (inp.Position - startPos).Magnitude

            if diff < 6 then
                state = not state

                tw(stateBox, {
                    BackgroundColor3 = state and T.GREEN or T.GRAY
                }, 0.12)

                tw(knob, {
                    Position = state
                        and UDim2.new(1, -11, 0.5, -8)
                        or UDim2.new(0, 4, 0.5, -8)
                }, 0.12)

                stateText.Text = state and "ON" or "OFF"
                stateText.TextColor3 = state and T.WHITE or T.DIM
                leftMark.BackgroundColor3 = state and T.GREEN or T.STROKE

                callback(state)
            end

            startPos = nil
        end
    end)
end

local function createSlider(parent, text, min, max, default, callback)
    local row = pxFrame(
        parent,
        UDim2.new(0.96, 0, 0, 58),
        UDim2.new(0, 0, 0, 0),
        T.PANEL,
        15
    )
    pxStroke(row, T.STROKE, 1)

    local leftMark = pxFrame(
        row,
        UDim2.new(0, 3, 0, 24),
        UDim2.new(0, 7, 0.5, -12),
        T.RED,
        16
    )

    local lbl = pxText(
        row,
        text,
        UDim2.new(0.60, 0, 0, 21),
        T.WHITE, 10,
        Enum.TextXAlignment.Left, 16
    )
    lbl.Position = UDim2.new(0, 18, 0, 5)

    local valLbl = pxText(
        row,
        tostring(default),
        UDim2.new(0.28, 0, 0, 21),
        T.RED2, 10,
        Enum.TextXAlignment.Right, 16
    )
    valLbl.Position = UDim2.new(0.68, 0, 0, 5)

    local bar = pxFrame(
        row,
        UDim2.new(0.86, 0, 0, 5),
        UDim2.new(0.07, 0, 0, 38),
        T.GRAY,
        16
    )

    local fill = pxFrame(
        bar,
        UDim2.new((default - min) / (max - min), 0, 1, 0),
        UDim2.new(0, 0, 0, 0),
        T.RED,
        17
    )

    local fillEdge = pxFrame(
        fill,
        UDim2.new(0, 2, 1, 0),
        UDim2.new(1, -2, 0, 0),
        T.RED2,
        18
    )

    local thumb = pxFrame(
        bar,
        UDim2.new(0, 10, 0, 10),
        UDim2.new((default - min) / (max - min), -5, 0.5, -5),
        T.WHITE,
        18
    )
    pxStroke(thumb, T.RED, 1)

    local function updateVal(inputX)
        local pct = math.clamp(
            (inputX - bar.AbsolutePosition.X) / bar.AbsoluteSize.X,
            0, 1
        )

        fill.Size = UDim2.new(pct, 0, 1, 0)
        thumb.Position = UDim2.new(pct, -5, 0.5, -5)

        local v = math.floor(min + (max - min) * pct)
        valLbl.Text = tostring(v)
        callback(v)
    end

    local dragging = false
    local startPosSlider = nil

    row.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            startPosSlider = inp.Position
            task.delay(0.1, function()
                if startPosSlider then
                    dragging = true
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (
            inp.UserInputType == Enum.UserInputType.MouseMovement
            or inp.UserInputType == Enum.UserInputType.Touch
        ) then
            updateVal(inp.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            if not dragging and startPosSlider then
                local diff = (inp.Position - startPosSlider).Magnitude
                if diff < 6 then
                    updateVal(inp.Position.X)
                end
            end

            dragging = false
            startPosSlider = nil
        end
    end)
end

-- ============================================================
--  BUILD TABS
-- ============================================================

local Tab_Main    = createTabContent("Main")
local Tab_PvP     = createTabContent("PvP")
local Tab_Setting = createTabContent("Setting")

createSideTab("Main",    "H")
createSideTab("PvP",     "P")
createSideTab("Setting", "S")

-- ============================================================
--  TAB MAIN
-- ============================================================

createSection(Tab_Main, "TIỆN ÍCH")
createToggle(Tab_Main, "Nhảy Vô Hạn", function(s)
    _G.InfiniteJumpEnabled = s
end)

createSection(Tab_Main, "TRÁI ÁC QUỶ")
createToggle(Tab_Main, "Hiện Trái (Fruit ESP)", function(s)
    _G.FruitESPEnabled = s
end)

createToggle(Tab_Main, "Bay Tới Trái (Tween)", function(s)
    _G.FruitTweenEnabled = s

    if not s and curFruitTween then
        curFruitTween:Cancel()
        curFruitTween = nil
        tweenTarget = nil
    end
end)

createSlider(
    Tab_Main,
    "Tốc Độ Tween",
    50, 500, 120,
    function(v)
        _G.FruitTweenSpeed = v
    end
)

-- ============================================================
--  TAB PVP
-- ============================================================

createSection(Tab_PvP, "DI CHUYỂN")

createSlider(
    Tab_PvP,
    "Tốc Độ",
    16, 500, 130,
    function(v)
        _G.SpeedValue = v
    end
)

createToggle(Tab_PvP, "Bật Tốc Độ", function(s)
    _G.SpeedEnabled = s
end)

createSlider(
    Tab_PvP,
    "Sức Nhảy",
    50, 500, 130,
    function(v)
        _G.JumpPowerValue = v
    end
)

createToggle(Tab_PvP, "Bật Nhảy Cao", function(s)
    _G.JumpEnabled = s
end)

createSlider(
    Tab_PvP,
    "Dash (Lướt)",
    1, 20, 4,
    function(v)
        _G.DashDist = v
    end
)

createToggle(Tab_PvP, "Bật Dash", function(s)
    _G.DashEnabled = s
end)

createSection(Tab_PvP, "CHIẾN ĐẤU")

createSlider(
    Tab_PvP,
    "Kích Thước Hitbox",
    5, 100, 5,
    function(v)
        _G.HitboxSize = v
    end
)

createToggle(Tab_PvP, "Bật Hitbox", function(s)
    _G.HitboxEnabled = s
    if not s then
        resetHitbox()
    end
end)

createToggle(Tab_PvP, "ESP Người Chơi", function(s)
    _G.ESPEnabled = s

    if s then
        for _, p in pairs(Players:GetPlayers()) do
            createDot(p)
        end
    else
        for _, p in pairs(Players:GetPlayers()) do
            removeDot(p)
        end
    end
end)

createToggle(Tab_PvP, "Tự Áp Sát (Auto Tele)", function(s)
    _G.AutoTeleEnabled = s
end)

-- ============================================================
--  TAB SETTING
-- ============================================================

createSection(Tab_Setting, "HIỂN THỊ")

createToggle(Tab_Setting, "Góc Nhìn Rộng (95°)", function(s)
    camera.FieldOfView = s and 95 or 70
end)

createSection(Tab_Setting, "HỆ THỐNG")

createToggle(Tab_Setting, "Vào Lại Server", function()
    TeleportService:TeleportToPlaceInstance(
        game.PlaceId,
        game.JobId,
        LocalPlayer
    )
end)

-- ============================================================
--  KÍCH HOẠT TAB MAIN MẶC ĐỊNH
-- ============================================================

do
    tw(TabButtons["Main"].btn, {BackgroundColor3 = T.TAB_ON}, 0)
    TabButtons["Main"].ic.TextColor3 = T.WHITE
    TabButtons["Main"].nm.TextColor3 = T.WHITE
    TabButtons["Main"].bar.BackgroundTransparency = 0

    TabFrames["Main"].Visible = true
    activeTab = "Main"
end

-- Pixel status pulse
task.spawn(function()
    while MainFrame.Parent do
        tw(statusBox, {BackgroundColor3 = Color3.fromRGB(20, 30, 28)}, 0.35)
        task.wait(0.5)
        tw(statusBox, {BackgroundColor3 = T.PANEL}, 0.35)
        task.wait(1.5)
    end
end)
