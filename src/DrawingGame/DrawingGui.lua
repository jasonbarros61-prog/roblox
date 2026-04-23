--[[
    DrawingGui — LocalScript
    Place in: StarterGui  (as a LocalScript directly inside StarterGui, or inside a ScreenGui)

    Builds and manages the entire drawing canvas UI:
    • Receives StartGame event → shows canvas with shape guide
    • Mouse input → draws strokes on canvas
    • Submit / timer-expire → calculates accuracy, fires SubmitDrawing to server
    • ShowResult event → displays accuracy % and coins earned
--]]

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player.PlayerGui

local Events    = ReplicatedStorage:WaitForChild("DrawingGameEvents")
local RE_Start  = Events:WaitForChild("StartGame")
local RE_Submit = Events:WaitForChild("SubmitDrawing")
local RE_Result = Events:WaitForChild("ShowResult")

local ShapeData = require(ReplicatedStorage:WaitForChild("ShapeData"))
local Cfg       = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- ── Build GUI ─────────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name            = "DrawingGameGui"
gui.ResetOnSpawn    = false
gui.IgnoreGuiInset  = true
gui.Enabled         = false
gui.Parent          = playerGui

-- Dimmed backdrop
local backdrop = Instance.new("Frame")
backdrop.Size                 = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3     = Color3.fromRGB(0, 0, 0)
backdrop.BackgroundTransparency = 0.45
backdrop.BorderSizePixel      = 0
backdrop.Parent               = gui

-- Main panel (paper texture feel)
local panel = Instance.new("Frame")
panel.Size                = UDim2.new(0, 590, 0, 690)
panel.Position            = UDim2.new(0.5, -295, 0.5, -345)
panel.BackgroundColor3    = Color3.fromRGB(248, 244, 236)
panel.BorderSizePixel     = 0
panel.Parent              = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

local shadow = Instance.new("ImageLabel")
shadow.Size               = UDim2.new(1, 30, 1, 30)
shadow.Position           = UDim2.new(0, -15, 0, -15)
shadow.BackgroundTransparency = 1
shadow.Image              = "rbxassetid://6014261993"
shadow.ImageColor3        = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency  = 0.55
shadow.ScaleType          = Enum.ScaleType.Slice
shadow.SliceCenter        = Rect.new(49, 49, 450, 450)
shadow.ZIndex             = 0
shadow.Parent             = panel

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size             = UDim2.new(1, 0, 0, 54)
titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 68)
titleBar.BorderSizePixel  = 0
titleBar.Parent           = panel
local tbc = Instance.new("UICorner", titleBar)
tbc.CornerRadius = UDim.new(0, 14)
-- Square off bottom corners
local tbFill = Instance.new("Frame", titleBar)
tbFill.Size             = UDim2.new(1, 0, 0.5, 0)
tbFill.Position         = UDim2.new(0, 0, 0.5, 0)
tbFill.BackgroundColor3 = Color3.fromRGB(45, 45, 68)
tbFill.BorderSizePixel  = 0

local titleTxt = Instance.new("TextLabel", titleBar)
titleTxt.Size            = UDim2.new(1, -120, 1, 0)
titleTxt.Position        = UDim2.new(0, 16, 0, 0)
titleTxt.BackgroundTransparency = 1
titleTxt.TextColor3      = Color3.fromRGB(255, 255, 255)
titleTxt.Font            = Enum.Font.GothamBold
titleTxt.TextSize        = 20
titleTxt.TextXAlignment  = Enum.TextXAlignment.Left
titleTxt.Text            = "Drawing Challenge"

-- Timer display (top-right of title bar)
local timerLbl = Instance.new("TextLabel", titleBar)
timerLbl.Size            = UDim2.new(0, 100, 1, 0)
timerLbl.Position        = UDim2.new(1, -108, 0, 0)
timerLbl.BackgroundTransparency = 1
timerLbl.TextColor3      = Color3.fromRGB(255, 220, 80)
timerLbl.Font            = Enum.Font.GothamBold
timerLbl.TextSize        = 22
timerLbl.Text            = "0:45"

-- Shape info bar
local infoBar = Instance.new("Frame", panel)
infoBar.Size             = UDim2.new(1, 0, 0, 42)
infoBar.Position         = UDim2.new(0, 0, 0, 54)
infoBar.BackgroundColor3 = Color3.fromRGB(235, 228, 214)
infoBar.BorderSizePixel  = 0

local shapeLbl = Instance.new("TextLabel", infoBar)
shapeLbl.Size            = UDim2.new(0.6, 0, 1, 0)
shapeLbl.Position        = UDim2.new(0, 16, 0, 0)
shapeLbl.BackgroundTransparency = 1
shapeLbl.TextColor3      = Color3.fromRGB(45, 45, 68)
shapeLbl.Font            = Enum.Font.GothamSemibold
shapeLbl.TextSize        = 16
shapeLbl.TextXAlignment  = Enum.TextXAlignment.Left
shapeLbl.Text            = "Draw the shape!"

local coinsLbl = Instance.new("TextLabel", infoBar)
coinsLbl.Size            = UDim2.new(0.38, 0, 1, 0)
coinsLbl.Position        = UDim2.new(0.62, 0, 0, 0)
coinsLbl.BackgroundTransparency = 1
coinsLbl.TextColor3      = Color3.fromRGB(190, 145, 0)
coinsLbl.Font            = Enum.Font.GothamBold
coinsLbl.TextSize        = 15
coinsLbl.TextXAlignment  = Enum.TextXAlignment.Right
coinsLbl.Text            = ""

-- Canvas
local canvasFrame = Instance.new("Frame", panel)
canvasFrame.Size             = UDim2.new(0, 510, 0, 510)
canvasFrame.Position         = UDim2.new(0.5, -255, 0, 104)
canvasFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
canvasFrame.BorderSizePixel  = 0
canvasFrame.ClipsDescendants = true
Instance.new("UICorner", canvasFrame).CornerRadius = UDim.new(0, 8)

local canvasBorder = Instance.new("UIStroke", canvasFrame)
canvasBorder.Color     = Color3.fromRGB(180, 165, 140)
canvasBorder.Thickness = 2

-- Guide layer (shape outline — rendered behind the player's strokes)
local guideLayer = Instance.new("Frame", canvasFrame)
guideLayer.Size                 = UDim2.new(1, 0, 1, 0)
guideLayer.BackgroundTransparency = 1
guideLayer.ZIndex               = 1

-- Draw layer (player strokes)
local drawLayer = Instance.new("Frame", canvasFrame)
drawLayer.Size                  = UDim2.new(1, 0, 1, 0)
drawLayer.BackgroundTransparency = 1
drawLayer.ZIndex                = 2

-- Button row
local btnRow = Instance.new("Frame", panel)
btnRow.Size             = UDim2.new(0, 510, 0, 52)
btnRow.Position         = UDim2.new(0.5, -255, 0, 624)
btnRow.BackgroundTransparency = 1

local clearBtn = Instance.new("TextButton", btnRow)
clearBtn.Size            = UDim2.new(0, 145, 1, 0)
clearBtn.BackgroundColor3 = Color3.fromRGB(195, 65, 65)
clearBtn.BorderSizePixel = 0
clearBtn.TextColor3      = Color3.fromRGB(255, 255, 255)
clearBtn.Font            = Enum.Font.GothamSemibold
clearBtn.TextSize        = 15
clearBtn.Text            = "🗑 Clear"
Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 9)

local submitBtn = Instance.new("TextButton", btnRow)
submitBtn.Size           = UDim2.new(0, 200, 1, 0)
submitBtn.Position       = UDim2.new(1, -200, 0, 0)
submitBtn.BackgroundColor3 = Color3.fromRGB(55, 160, 80)
submitBtn.BorderSizePixel = 0
submitBtn.TextColor3     = Color3.fromRGB(255, 255, 255)
submitBtn.Font           = Enum.Font.GothamBold
submitBtn.TextSize       = 16
submitBtn.Text           = "✔ Submit Drawing"
Instance.new("UICorner", submitBtn).CornerRadius = UDim.new(0, 9)

-- ── Result overlay ────────────────────────────────────────────────────────────
local resultOverlay = Instance.new("Frame", gui)
resultOverlay.Size               = UDim2.new(1, 0, 1, 0)
resultOverlay.BackgroundColor3   = Color3.fromRGB(0, 0, 0)
resultOverlay.BackgroundTransparency = 0.35
resultOverlay.Visible            = false
resultOverlay.ZIndex             = 20

local resultCard = Instance.new("Frame", resultOverlay)
resultCard.Size            = UDim2.new(0, 440, 0, 310)
resultCard.Position        = UDim2.new(0.5, -220, 0.5, -155)
resultCard.BackgroundColor3 = Color3.fromRGB(248, 244, 236)
resultCard.BorderSizePixel = 0
resultCard.ZIndex          = 21
Instance.new("UICorner", resultCard).CornerRadius = UDim.new(0, 18)

local resultHeading = Instance.new("TextLabel", resultCard)
resultHeading.Size            = UDim2.new(1, 0, 0, 60)
resultHeading.Position        = UDim2.new(0, 0, 0, 18)
resultHeading.BackgroundTransparency = 1
resultHeading.TextColor3      = Color3.fromRGB(45, 45, 68)
resultHeading.Font            = Enum.Font.GothamBold
resultHeading.TextSize        = 26
resultHeading.Text            = "Result!"
resultHeading.ZIndex          = 22

local resultPct = Instance.new("TextLabel", resultCard)
resultPct.Size                = UDim2.new(1, 0, 0, 70)
resultPct.Position            = UDim2.new(0, 0, 0, 78)
resultPct.BackgroundTransparency = 1
resultPct.TextColor3          = Color3.fromRGB(55, 160, 80)
resultPct.Font                = Enum.Font.GothamBold
resultPct.TextSize            = 52
resultPct.Text                = "0%"
resultPct.ZIndex              = 22

local resultCoinsLbl = Instance.new("TextLabel", resultCard)
resultCoinsLbl.Size           = UDim2.new(1, 0, 0, 38)
resultCoinsLbl.Position       = UDim2.new(0, 0, 0, 153)
resultCoinsLbl.BackgroundTransparency = 1
resultCoinsLbl.TextColor3     = Color3.fromRGB(190, 145, 0)
resultCoinsLbl.Font           = Enum.Font.GothamSemibold
resultCoinsLbl.TextSize        = 20
resultCoinsLbl.Text           = "+0 coins"
resultCoinsLbl.ZIndex         = 22

local resultMsg = Instance.new("TextLabel", resultCard)
resultMsg.Size                = UDim2.new(1, -30, 0, 28)
resultMsg.Position            = UDim2.new(0, 15, 0, 196)
resultMsg.BackgroundTransparency = 1
resultMsg.TextColor3          = Color3.fromRGB(130, 120, 100)
resultMsg.Font                = Enum.Font.Gotham
resultMsg.TextSize            = 14
resultMsg.Text                = ""
resultMsg.ZIndex              = 22

local closeResultBtn = Instance.new("TextButton", resultCard)
closeResultBtn.Size           = UDim2.new(0, 170, 0, 44)
closeResultBtn.Position       = UDim2.new(0.5, -85, 0, 252)
closeResultBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 68)
closeResultBtn.BorderSizePixel = 0
closeResultBtn.TextColor3     = Color3.fromRGB(255, 255, 255)
closeResultBtn.Font           = Enum.Font.GothamBold
closeResultBtn.TextSize       = 15
closeResultBtn.Text           = "Close"
closeResultBtn.ZIndex         = 22
Instance.new("UICorner", closeResultBtn).CornerRadius = UDim.new(0, 10)

-- ── Drawing state ─────────────────────────────────────────────────────────────
local gameActive      = false
local currentShape    = nil
local drawnPoints     = {}  -- array of Vector2 (canvas-pixel coords)
local lastCanvasPos   = nil
local inputConn       = nil
local inputEndConn    = nil
local timerTask       = nil
local CSIZE           = Cfg.CANVAS_SIZE  -- 500

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function makeCorner(parent, r)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, r or 3)
end

local function drawSegment(p1, p2, parent, color, thickness, zindex)
    local delta = p2 - p1
    local dist  = delta.Magnitude
    if dist < 0.5 then return end
    local mid   = (p1 + p2) * 0.5
    local angle = math.deg(math.atan2(delta.Y, delta.X))

    local seg = Instance.new("Frame", parent)
    seg.BackgroundColor3    = color
    seg.BorderSizePixel     = 0
    seg.Size                = UDim2.new(0, dist, 0, thickness)
    seg.Position            = UDim2.new(0, mid.X - dist * 0.5, 0, mid.Y - thickness * 0.5)
    seg.Rotation            = angle
    seg.ZIndex              = zindex or 1
    return seg
end

local function clearChildren(frame)
    for _, c in ipairs(frame:GetChildren()) do c:Destroy() end
end

-- Convert screen position → canvas-pixel position (0..CSIZE)
local function toCanvasPos(screenPos)
    local ap   = canvasFrame.AbsolutePosition
    local as   = canvasFrame.AbsoluteSize
    local rx   = math.clamp(screenPos.X - ap.X, 0, as.X)
    local ry   = math.clamp(screenPos.Y - ap.Y, 0, as.Y)
    return Vector2.new(rx / as.X * CSIZE, ry / as.Y * CSIZE)
end

local function isOverCanvas(screenPos)
    local ap = canvasFrame.AbsolutePosition
    local as = canvasFrame.AbsoluteSize
    return screenPos.X >= ap.X and screenPos.X <= ap.X + as.X
       and screenPos.Y >= ap.Y and screenPos.Y <= ap.Y + as.Y
end

-- ── Guide rendering ───────────────────────────────────────────────────────────
local GUIDE_COLOR   = Color3.fromRGB(100, 190, 255)
local GUIDE_DOT_CLR = Color3.fromRGB(60, 150, 240)

local function renderGuide(shapePoints)
    clearChildren(guideLayer)
    local n = #shapePoints
    -- Draw connecting lines (semi-transparent dashes)
    for i = 1, n do
        if i % Cfg.GUIDE_DASH_SKIP == 0 then continue end
        local p1 = shapePoints[i]
        local p2 = shapePoints[(i % n) + 1]
        local px1 = Vector2.new(p1.X * CSIZE, p1.Y * CSIZE)
        local px2 = Vector2.new(p2.X * CSIZE, p2.Y * CSIZE)
        local seg = drawSegment(px1, px2, guideLayer, GUIDE_COLOR, 2, 1)
        if seg then seg.BackgroundTransparency = 0.45 end
    end
    -- Draw dots at each vertex for clearer outline
    for i = 1, n, 3 do
        local pt  = shapePoints[i]
        local px  = pt.X * CSIZE
        local py  = pt.Y * CSIZE
        local dot = Instance.new("Frame", guideLayer)
        dot.Size             = UDim2.new(0, Cfg.GUIDE_DOT_SIZE, 0, Cfg.GUIDE_DOT_SIZE)
        dot.Position         = UDim2.new(0, px - Cfg.GUIDE_DOT_SIZE * 0.5, 0, py - Cfg.GUIDE_DOT_SIZE * 0.5)
        dot.BackgroundColor3 = GUIDE_DOT_CLR
        dot.BorderSizePixel  = 0
        dot.ZIndex           = 2
        makeCorner(dot, 99)
    end
end

-- ── Accuracy calculation ──────────────────────────────────────────────────────
local function calcAccuracy(drawn, shapePoints)
    if #drawn < 3 then return 0 end

    local thresh     = Cfg.ACCURACY_THRESHOLD
    local penaltyRad = thresh * Cfg.PENALTY_RADIUS_MULT
    local hits       = 0

    -- Coverage: what fraction of the shape outline is "touched"
    for _, sp in ipairs(shapePoints) do
        local spx = sp.X * CSIZE
        local spy = sp.Y * CSIZE
        local best = math.huge
        for _, dp in ipairs(drawn) do
            local d = math.sqrt((dp.X - spx)^2 + (dp.Y - spy)^2)
            if d < best then best = d end
        end
        if best <= thresh then hits = hits + 1 end
    end

    local coveragePct = (hits / #shapePoints) * 100

    -- Stray penalty: how much drawing went far outside the shape
    local strayCount = 0
    for _, dp in ipairs(drawn) do
        local best = math.huge
        for _, sp in ipairs(shapePoints) do
            local d = math.sqrt((dp.X - sp.X * CSIZE)^2 + (dp.Y - sp.Y * CSIZE)^2)
            if d < best then best = d end
        end
        if best > penaltyRad then strayCount = strayCount + 1 end
    end

    local strayRatio  = strayCount / math.max(#drawn, 1)
    local penalty     = math.min(strayRatio * Cfg.STRAY_PENALTY_MAX * 2, Cfg.STRAY_PENALTY_MAX)

    return math.max(0, math.min(100, math.floor(coveragePct - penalty)))
end

-- ── Submit ────────────────────────────────────────────────────────────────────
local function submitDrawing()
    if not gameActive then return end
    gameActive = false

    if timerTask  then task.cancel(timerTask);  timerTask  = nil end
    if inputConn  then inputConn:Disconnect();  inputConn  = nil end
    if inputEndConn then inputEndConn:Disconnect(); inputEndConn = nil end

    submitBtn.Active          = false
    submitBtn.BackgroundColor3 = Color3.fromRGB(110, 110, 110)

    local shapeData = ShapeData.getShape(currentShape)
    local accuracy  = calcAccuracy(drawnPoints, shapeData.points)

    RE_Submit:FireServer(accuracy)
end

-- ── StartGame event ───────────────────────────────────────────────────────────
RE_Start.OnClientEvent:Connect(function(data)
    currentShape = data.shape
    local timeLimit = data.timeLimit or Cfg.DRAW_TIME

    -- Reset
    clearChildren(drawLayer)
    drawnPoints   = {}
    lastCanvasPos = nil
    gameActive    = true
    timerLbl.TextColor3       = Color3.fromRGB(255, 220, 80)
    submitBtn.Active          = true
    submitBtn.BackgroundColor3 = Color3.fromRGB(55, 160, 80)
    resultOverlay.Visible     = false

    local shapeData = ShapeData.getShape(currentShape)
    shapeLbl.Text  = "Draw a " .. shapeData.name .. "!"
    coinsLbl.Text  = shapeData.coins .. " coins if you win"
    timerLbl.Text  = string.format("0:%02d", timeLimit)

    renderGuide(shapeData.points)

    gui.Enabled = true

    -- Timer countdown
    timerTask = task.spawn(function()
        local rem = timeLimit
        while rem > 0 and gameActive do
            task.wait(1)
            rem = rem - 1
            timerLbl.Text = string.format("0:%02d", rem)
            if rem <= 10 then
                timerLbl.TextColor3 = Color3.fromRGB(255, 90, 90)
            end
        end
        if gameActive then submitDrawing() end
    end)

    -- Input: mouse move while LMB held
    if inputConn then inputConn:Disconnect() end
    inputConn = UserInputService.InputChanged:Connect(function(input)
        if not gameActive then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end

        if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            lastCanvasPos = nil
            return
        end

        local screenPos = Vector2.new(input.Position.X, input.Position.Y)
        if not isOverCanvas(screenPos) then
            lastCanvasPos = nil
            return
        end

        local cp = toCanvasPos(screenPos)
        drawnPoints[#drawnPoints + 1] = cp

        if lastCanvasPos then
            drawSegment(lastCanvasPos, cp, drawLayer,
                Color3.fromRGB(25, 25, 25), Cfg.LINE_THICKNESS, 3)
        end
        lastCanvasPos = cp
    end)

    -- Reset pen lift on mouse release
    if inputEndConn then inputEndConn:Disconnect() end
    inputEndConn = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            lastCanvasPos = nil
        end
    end)
end)

-- ── ShowResult event ──────────────────────────────────────────────────────────
local GRADE_DATA = {
    { min = 90, heading = "PERFECT!",         pctColor = Color3.fromRGB(55, 200, 90),  msg = "Absolutely flawless!" },
    { min = 70, heading = "Great Job!",        pctColor = Color3.fromRGB(55, 160, 80),  msg = "You nailed it — coins earned!" },
    { min = 50, heading = "Not Bad!",          pctColor = Color3.fromRGB(200, 155, 0),  msg = "Keep practising for full coins." },
    { min = 25, heading = "Almost There...",   pctColor = Color3.fromRGB(210, 110, 40), msg = "You earned partial coins." },
    { min = 0,  heading = "Keep Practising!",  pctColor = Color3.fromRGB(200, 60, 60),  msg = "No coins this time. Try again!" },
}

RE_Result.OnClientEvent:Connect(function(data)
    local acc   = data.accuracy
    local coins = data.coinsAwarded
    local full  = data.fullCoins

    resultPct.Text = acc .. "%"

    local grade = GRADE_DATA[#GRADE_DATA]
    for _, g in ipairs(GRADE_DATA) do
        if acc >= g.min then grade = g; break end
    end

    resultHeading.Text       = grade.heading
    resultPct.TextColor3     = grade.pctColor
    resultMsg.Text           = grade.msg

    if coins > 0 then
        resultCoinsLbl.Text      = "+" .. coins .. " coins"
        resultCoinsLbl.TextColor3 = Color3.fromRGB(190, 145, 0)
    else
        resultCoinsLbl.Text      = "No coins earned"
        resultCoinsLbl.TextColor3 = Color3.fromRGB(160, 140, 120)
    end

    resultOverlay.Visible = true
end)

-- ── Button handlers ───────────────────────────────────────────────────────────
clearBtn.MouseButton1Click:Connect(function()
    if not gameActive then return end
    clearChildren(drawLayer)
    drawnPoints   = {}
    lastCanvasPos = nil
end)

submitBtn.MouseButton1Click:Connect(function()
    if gameActive then submitDrawing() end
end)

closeResultBtn.MouseButton1Click:Connect(function()
    resultOverlay.Visible = false
    gui.Enabled           = false
end)
