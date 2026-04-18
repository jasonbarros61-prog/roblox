-- LocalScript: LocalScript in StarterGui
local Players        = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ── Wait for RemoteEvents (created by WaveManager on server) ─────────────────
local gameStarted    = ReplicatedStorage:WaitForChild("GameStarted",    15)
local buyMorph       = ReplicatedStorage:WaitForChild("BuyMorph",       15)
local equipMorph     = ReplicatedStorage:WaitForChild("EquipMorph",     15)
local morphConfirmed = ReplicatedStorage:WaitForChild("MorphConfirmed", 15)
local returnToLobby  = ReplicatedStorage:WaitForChild("ReturnToLobby",  15)
local bossSpawned    = ReplicatedStorage:WaitForChild("BossSpawned",    15)

if not gameStarted then
	warn("[LocalScript] RemoteEvents not found in ReplicatedStorage — check WaveManager loaded")
	return
end

print("[LocalScript] RemoteEvents found")

-- ── GameData ──────────────────────────────────────────────────────────────────
local gameData   = ReplicatedStorage:WaitForChild("GameData",   15)
local waveValue  = gameData:WaitForChild("Wave",     10)
local timeValue  = gameData:WaitForChild("TimeLeft", 10)

-- ── State ─────────────────────────────────────────────────────────────────────
local inLobby    = true
local ownedMorphs = {}   -- only set via MorphConfirmed from server
local cameraAngle = 0

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function fmt(secs)
	secs = math.max(0, math.floor(secs))
	return string.format("%d:%02d", math.floor(secs/60), secs%60)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- SCREEN GUI
-- ══════════════════════════════════════════════════════════════════════════════
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SkibieWarzone"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

-- ── LOBBY FRAME ───────────────────────────────────────────────────────────────
local lobbyFrame = Instance.new("Frame")
lobbyFrame.Size = UDim2.new(1, 0, 1, 0)
lobbyFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
lobbyFrame.BackgroundTransparency = 0.1
lobbyFrame.ZIndex = 10
lobbyFrame.Parent = screenGui

-- dot pattern
for row = 0, 20 do
	for col = 0, 40 do
		local dot = Instance.new("Frame")
		dot.Size = UDim2.new(0, 3, 0, 3)
		dot.Position = UDim2.new(0, col*25, 0, row*25)
		dot.BackgroundColor3 = Color3.fromRGB(0, 200, 80)
		dot.BackgroundTransparency = 0.7
		dot.BorderSizePixel = 0
		dot.ZIndex = 11
		Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
		dot.Parent = lobbyFrame
	end
end

-- title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 500, 0, 80)
titleLabel.Position = UDim2.new(0.5, -250, 0.18, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "SKIBIE WARZONE"
titleLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.ZIndex = 12
titleLabel.Parent = lobbyFrame

local subLabel = Instance.new("TextLabel")
subLabel.Size = UDim2.new(0, 400, 0, 40)
subLabel.Position = UDim2.new(0.5, -200, 0.32, 0)
subLabel.BackgroundTransparency = 1
subLabel.Text = "Survive the Skibidi Toilets"
subLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
subLabel.TextScaled = true
subLabel.Font = Enum.Font.Gotham
subLabel.ZIndex = 12
subLabel.Parent = lobbyFrame

-- PLAY button
local playBtn = Instance.new("TextButton")
playBtn.Size = UDim2.new(0, 220, 0, 65)
playBtn.Position = UDim2.new(0.5, -110, 0.5, 0)
playBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 80)
playBtn.Text = "PLAY"
playBtn.TextColor3 = Color3.new(1, 1, 1)
playBtn.TextScaled = true
playBtn.Font = Enum.Font.GothamBold
playBtn.ZIndex = 12
playBtn.Parent = lobbyFrame
Instance.new("UICorner", playBtn).CornerRadius = UDim.new(0, 12)

-- SHOP button
local shopBtn = Instance.new("TextButton")
shopBtn.Size = UDim2.new(0, 220, 0, 55)
shopBtn.Position = UDim2.new(0.5, -110, 0.5, 80)
shopBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
shopBtn.Text = "SHOP"
shopBtn.TextColor3 = Color3.fromRGB(0, 200, 80)
shopBtn.TextScaled = true
shopBtn.Font = Enum.Font.GothamBold
shopBtn.ZIndex = 12
shopBtn.Parent = lobbyFrame
Instance.new("UICorner", shopBtn).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", shopBtn).Color = Color3.fromRGB(0, 200, 80)

-- ── HUD FRAME (hidden while in lobby) ─────────────────────────────────────────
local hudFrame = Instance.new("Frame")
hudFrame.Size = UDim2.new(1, 0, 0, 50)
hudFrame.Position = UDim2.new(0, 0, 0, 0)
hudFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
hudFrame.BackgroundTransparency = 0.3
hudFrame.Visible = false
hudFrame.ZIndex = 5
hudFrame.Parent = screenGui

local waveLabel = Instance.new("TextLabel")
waveLabel.Size = UDim2.new(0, 200, 1, 0)
waveLabel.Position = UDim2.new(0.5, -100, 0, 0)
waveLabel.BackgroundTransparency = 1
waveLabel.Text = "Wave 1"
waveLabel.TextColor3 = Color3.new(1, 1, 1)
waveLabel.TextScaled = true
waveLabel.Font = Enum.Font.GothamBold
waveLabel.ZIndex = 6
waveLabel.Parent = hudFrame

local timeLabel = Instance.new("TextLabel")
timeLabel.Size = UDim2.new(0, 150, 1, 0)
timeLabel.Position = UDim2.new(1, -160, 0, 0)
timeLabel.BackgroundTransparency = 1
timeLabel.Text = "3:00"
timeLabel.TextColor3 = Color3.new(1, 1, 1)
timeLabel.TextScaled = true
timeLabel.Font = Enum.Font.GothamBold
timeLabel.ZIndex = 6
timeLabel.Parent = hudFrame

local enemyLabel = Instance.new("TextLabel")
enemyLabel.Size = UDim2.new(0, 200, 1, 0)
enemyLabel.Position = UDim2.new(0, 10, 0, 0)
enemyLabel.BackgroundTransparency = 1
enemyLabel.Text = "Enemies: 0"
enemyLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
enemyLabel.TextScaled = true
enemyLabel.Font = Enum.Font.GothamBold
enemyLabel.ZIndex = 6
enemyLabel.Parent = hudFrame

-- token bar (top-right)
local tokenBar = Instance.new("Frame")
tokenBar.Size = UDim2.new(0, 180, 0, 40)
tokenBar.Position = UDim2.new(1, -190, 0, 55)
tokenBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
tokenBar.BackgroundTransparency = 0.2
tokenBar.Visible = false
tokenBar.ZIndex = 5
tokenBar.Parent = screenGui
Instance.new("UICorner", tokenBar).CornerRadius = UDim.new(0, 8)

local tokenLabel = Instance.new("TextLabel")
tokenLabel.Size = UDim2.new(1, 0, 1, 0)
tokenLabel.BackgroundTransparency = 1
tokenLabel.Text = "Tokens: 0"
tokenLabel.TextColor3 = Color3.fromRGB(255, 220, 0)
tokenLabel.TextScaled = true
tokenLabel.Font = Enum.Font.GothamBold
tokenLabel.ZIndex = 6
tokenLabel.Parent = tokenBar

-- ── PLAYER HEALTH BAR (black/red, bottom-centre) ─────────────────────────────
-- hide Roblox default health bar
game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

local hpBarFrame = Instance.new("Frame")
hpBarFrame.Size             = UDim2.new(0, 360, 0, 44)
hpBarFrame.Position         = UDim2.new(0.5, -180, 1, -70)
hpBarFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
hpBarFrame.BackgroundTransparency = 0.2
hpBarFrame.Visible          = false
hpBarFrame.ZIndex           = 5
hpBarFrame.Parent           = screenGui
Instance.new("UICorner", hpBarFrame).CornerRadius = UDim.new(0, 10)

local hpStroke = Instance.new("UIStroke", hpBarFrame)
hpStroke.Color     = Color3.fromRGB(180, 0, 0)
hpStroke.Thickness = 2

-- skull icon
local hpSkull = Instance.new("TextLabel")
hpSkull.Size               = UDim2.new(0, 30, 1, 0)
hpSkull.Position           = UDim2.new(0, 4, 0, 0)
hpSkull.BackgroundTransparency = 1
hpSkull.Text               = "❤"
hpSkull.TextColor3         = Color3.fromRGB(220, 0, 0)
hpSkull.TextScaled         = true
hpSkull.Font               = Enum.Font.GothamBold
hpSkull.ZIndex             = 7
hpSkull.Parent             = hpBarFrame

-- track
local hpTrack = Instance.new("Frame")
hpTrack.Size             = UDim2.new(1, -70, 0, 16)
hpTrack.Position         = UDim2.new(0, 38, 0, 8)
hpTrack.BackgroundColor3 = Color3.fromRGB(30, 0, 0)
hpTrack.BorderSizePixel  = 0
hpTrack.ZIndex           = 6
hpTrack.Parent           = hpBarFrame
Instance.new("UICorner", hpTrack).CornerRadius = UDim.new(0, 6)

local hpFill = Instance.new("Frame")
hpFill.Size             = UDim2.new(1, 0, 1, 0)
hpFill.BackgroundColor3 = Color3.fromRGB(200, 20, 20)
hpFill.BorderSizePixel  = 0
hpFill.ZIndex           = 7
hpFill.Parent           = hpTrack
Instance.new("UICorner", hpFill).CornerRadius = UDim.new(0, 6)

-- shimmer
local hpShimmer = Instance.new("Frame")
hpShimmer.Size             = UDim2.new(0.4, 0, 1, 0)
hpShimmer.BackgroundColor3 = Color3.new(1, 1, 1)
hpShimmer.BackgroundTransparency = 0.75
hpShimmer.BorderSizePixel  = 0
hpShimmer.ZIndex           = 8
hpShimmer.Parent           = hpFill
Instance.new("UICorner", hpShimmer).CornerRadius = UDim.new(0, 6)

local hpText = Instance.new("TextLabel")
hpText.Size               = UDim2.new(1, -70, 0, 14)
hpText.Position           = UDim2.new(0, 38, 1, -22)
hpText.BackgroundTransparency = 1
hpText.Text               = "1000 / 1000"
hpText.TextColor3         = Color3.fromRGB(255, 160, 160)
hpText.TextScaled         = true
hpText.Font               = Enum.Font.Gotham
hpText.ZIndex             = 7
hpText.Parent             = hpBarFrame

local function updateHealthBar(health, maxHealth)
	local pct = math.clamp(health / maxHealth, 0, 1)
	hpFill.Size = UDim2.new(pct, 0, 1, 0)
	hpText.Text = math.ceil(health) .. " / " .. math.ceil(maxHealth)
	if pct < 0.25 then
		hpFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	elseif pct < 0.5 then
		hpFill.BackgroundColor3 = Color3.fromRGB(200, 20, 20)
	else
		hpFill.BackgroundColor3 = Color3.fromRGB(160, 10, 10)
	end
end

-- hook to character humanoid
local function connectHealthBar(character)
	local humanoid = character:WaitForChild("Humanoid")
	updateHealthBar(humanoid.Health, humanoid.MaxHealth)
	humanoid.HealthChanged:Connect(function(hp)
		updateHealthBar(hp, humanoid.MaxHealth)
	end)
end

player.CharacterAdded:Connect(connectHealthBar)
if player.Character then connectHealthBar(player.Character) end

-- ── FALL BACK BOSS ALERT ──────────────────────────────────────────────────────
local alertFrame = Instance.new("Frame")
alertFrame.Size             = UDim2.new(1, 0, 1, 0)
alertFrame.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
alertFrame.BackgroundTransparency = 1
alertFrame.ZIndex           = 50
alertFrame.Visible          = false
alertFrame.Parent           = screenGui

local alertText = Instance.new("TextLabel")
alertText.Size               = UDim2.new(0, 600, 0, 100)
alertText.Position           = UDim2.new(0.5, -300, 0.35, 0)
alertText.BackgroundTransparency = 1
alertText.Text               = "☠  FALL BACK  ☠"
alertText.TextColor3         = Color3.fromRGB(255, 50, 50)
alertText.TextScaled         = true
alertText.Font               = Enum.Font.GothamBold
alertText.ZIndex             = 51
alertText.Parent             = alertFrame

local alertSub = Instance.new("TextLabel")
alertSub.Size               = UDim2.new(0, 500, 0, 50)
alertSub.Position           = UDim2.new(0.5, -250, 0.35, 105)
alertSub.BackgroundTransparency = 1
alertSub.Text               = "G-MAN HAS ARRIVED"
alertSub.TextColor3         = Color3.fromRGB(255, 200, 200)
alertSub.TextScaled         = true
alertSub.Font               = Enum.Font.Gotham
alertSub.ZIndex             = 51
alertSub.Parent             = alertFrame

local alertBossBar = Instance.new("Frame")
alertBossBar.Size             = UDim2.new(0, 400, 0, 30)
alertBossBar.Position         = UDim2.new(0.5, -200, 0.35, 165)
alertBossBar.BackgroundColor3 = Color3.fromRGB(0, 100, 220)
alertBossBar.BackgroundTransparency = 0.3
alertBossBar.ZIndex           = 51
alertBossBar.Parent           = alertFrame
Instance.new("UICorner", alertBossBar).CornerRadius = UDim.new(0, 8)

local alertBossText = Instance.new("TextLabel")
alertBossText.Size               = UDim2.new(1, 0, 1, 0)
alertBossText.BackgroundTransparency = 1
alertBossText.Text               = "⚠  BOSS ENEMY  ⚠"
alertBossText.TextColor3         = Color3.new(1, 1, 1)
alertBossText.TextScaled         = true
alertBossText.Font               = Enum.Font.GothamBold
alertBossText.ZIndex             = 52
alertBossText.Parent             = alertBossBar

local alertActive = false
local function showFallBackAlert()
	if alertActive then return end
	alertActive = true
	alertFrame.Visible = true
	-- red border flash
	TweenService:Create(alertFrame,
		TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 4, true),
		{BackgroundTransparency = 0.7}
	):Play()
	-- text pulse
	TweenService:Create(alertText,
		TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 3, true),
		{TextColor3 = Color3.fromRGB(255, 255, 100)}
	):Play()
	task.delay(3.5, function()
		TweenService:Create(alertFrame,
			TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundTransparency = 1}
		):Play()
		TweenService:Create(alertText,
			TweenInfo.new(0.6),
			{TextTransparency = 1}
		):Play()
		TweenService:Create(alertSub,
			TweenInfo.new(0.6),
			{TextTransparency = 1}
		):Play()
		TweenService:Create(alertBossBar,
			TweenInfo.new(0.6),
			{BackgroundTransparency = 1}
		):Play()
		task.wait(0.7)
		alertFrame.Visible = false
		alertText.TextTransparency = 0
		alertSub.TextTransparency = 0
		alertBossBar.BackgroundTransparency = 0.3
		alertActive = false
	end)
end

bossSpawned.OnClientEvent:Connect(showFallBackAlert)

-- ── SHOP FRAME ────────────────────────────────────────────────────────────────
local shopFrame = Instance.new("Frame")
shopFrame.Size = UDim2.new(0, 480, 0, 380)
shopFrame.Position = UDim2.new(0.5, -240, 1.1, 0)   -- starts off-screen below
shopFrame.BackgroundColor3 = Color3.fromRGB(15, 40, 15)
shopFrame.ZIndex = 15
shopFrame.Parent = screenGui
Instance.new("UICorner", shopFrame).CornerRadius = UDim.new(0, 16)
Instance.new("UIStroke", shopFrame).Color = Color3.fromRGB(0, 200, 80)

local shopTitle = Instance.new("TextLabel")
shopTitle.Size = UDim2.new(1, 0, 0, 45)
shopTitle.BackgroundTransparency = 1
shopTitle.Text = "SHOP"
shopTitle.TextColor3 = Color3.fromRGB(0, 255, 100)
shopTitle.TextScaled = true
shopTitle.Font = Enum.Font.GothamBold
shopTitle.ZIndex = 16
shopTitle.Parent = shopFrame

local closeShopBtn = Instance.new("TextButton")
closeShopBtn.Size = UDim2.new(0, 36, 0, 36)
closeShopBtn.Position = UDim2.new(1, -44, 0, 5)
closeShopBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeShopBtn.Text = "✕"
closeShopBtn.TextColor3 = Color3.new(1, 1, 1)
closeShopBtn.TextScaled = true
closeShopBtn.Font = Enum.Font.GothamBold
closeShopBtn.ZIndex = 17
closeShopBtn.Parent = shopFrame
Instance.new("UICorner", closeShopBtn).CornerRadius = UDim.new(0, 8)

local grid = Instance.new("Frame")
grid.Size = UDim2.new(1, -20, 1, -55)
grid.Position = UDim2.new(0, 10, 0, 50)
grid.BackgroundTransparency = 1
grid.ZIndex = 16
grid.Parent = shopFrame

local uiGrid = Instance.new("UIGridLayout")
uiGrid.CellSize = UDim2.new(0, 130, 0, 130)
uiGrid.CellPadding = UDim2.new(0, 10, 0, 10)
uiGrid.Parent = grid

-- morph slots
local morphItems = {
	{name = "CameraMan", cost = 500, color = Color3.fromRGB(50, 50, 180)},
	{name = "???",       cost = nil,  color = Color3.fromRGB(40, 40, 40)},
	{name = "???",       cost = nil,  color = Color3.fromRGB(40, 40, 40)},
	{name = "???",       cost = nil,  color = Color3.fromRGB(40, 40, 40)},
	{name = "???",       cost = nil,  color = Color3.fromRGB(40, 40, 40)},
	{name = "???",       cost = nil,  color = Color3.fromRGB(40, 40, 40)},
}

local shopSlots = {}
for _, item in ipairs(morphItems) do
	local slot = Instance.new("TextButton")
	slot.Size = UDim2.new(0, 130, 0, 130)
	slot.BackgroundColor3 = item.color
	slot.Text = ""
	slot.ZIndex = 17
	slot.Parent = grid
	Instance.new("UICorner", slot).CornerRadius = UDim.new(0, 10)

	local nameL = Instance.new("TextLabel")
	nameL.Size = UDim2.new(1, 0, 0.4, 0)
	nameL.Position = UDim2.new(0, 0, 0, 0)
	nameL.BackgroundTransparency = 1
	nameL.Text = item.name
	nameL.TextColor3 = Color3.new(1, 1, 1)
	nameL.TextScaled = true
	nameL.Font = Enum.Font.GothamBold
	nameL.ZIndex = 18
	nameL.Parent = slot

	local costL = Instance.new("TextLabel")
	costL.Size = UDim2.new(1, 0, 0.3, 0)
	costL.Position = UDim2.new(0, 0, 0.6, 0)
	costL.BackgroundTransparency = 1
	costL.Text = item.cost and (item.cost .. " tokens") or "LOCKED"
	costL.TextColor3 = Color3.fromRGB(255, 220, 0)
	costL.TextScaled = true
	costL.Font = Enum.Font.Gotham
	costL.ZIndex = 18
	costL.Parent = slot

	if item.cost then
		slot.MouseButton1Click:Connect(function()
			if ownedMorphs[item.name] then
				-- already owned → equip
				equipMorph:FireServer(item.name)
				print("[LocalScript] Equip:", item.name)
			else
				-- try to buy
				buyMorph:FireServer(item.name)
				print("[LocalScript] BuyMorph:", item.name)
			end
		end)
	end

	table.insert(shopSlots, {slot = slot, item = item, costLabel = costL})
end

local shopOpen = false
local function openShop()
	shopOpen = true
	TweenService:Create(shopFrame,
		TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, -240, 0.5, -190)}
	):Play()
end
local function closeShop()
	shopOpen = false
	TweenService:Create(shopFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
		{Position = UDim2.new(0.5, -240, 1.1, 0)}
	):Play()
end

shopBtn.MouseButton1Click:Connect(openShop)
closeShopBtn.MouseButton1Click:Connect(closeShop)

-- ── SETTINGS PANEL ────────────────────────────────────────────────────────────
local settingsBtn = Instance.new("TextButton")
settingsBtn.Size = UDim2.new(0, 44, 0, 44)
settingsBtn.Position = UDim2.new(0, 10, 1, -54)
settingsBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
settingsBtn.Text = "⚙"
settingsBtn.TextColor3 = Color3.new(1, 1, 1)
settingsBtn.TextScaled = true
settingsBtn.Font = Enum.Font.GothamBold
settingsBtn.Visible = false   -- only shown in-game
settingsBtn.ZIndex = 10
settingsBtn.Parent = screenGui
Instance.new("UICorner", settingsBtn).CornerRadius = UDim.new(0, 10)

local settingsPanel = Instance.new("Frame")
settingsPanel.Size = UDim2.new(0, 260, 0, 160)
settingsPanel.Position = UDim2.new(0, 10, 1, -224)
settingsPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
settingsPanel.BackgroundTransparency = 0.1
settingsPanel.Visible = false
settingsPanel.ZIndex = 20
settingsPanel.Parent = screenGui
Instance.new("UICorner", settingsPanel).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", settingsPanel).Color = Color3.fromRGB(0, 200, 80)

local settingsRows = {
	{text = "Return to Lobby", color = Color3.fromRGB(255, 80, 80)},
	{text = "Music: ON",       color = Color3.fromRGB(200, 200, 200)},
	{text = "Credits",         color = Color3.fromRGB(200, 200, 200)},
}

local rowBtns = {}
for i, row in ipairs(settingsRows) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -20, 0, 40)
	btn.Position = UDim2.new(0, 10, 0, (i-1)*50 + 10)
	btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	btn.Text = row.text
	btn.TextColor3 = row.color
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold
	btn.ZIndex = 21
	btn.Parent = settingsPanel
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	rowBtns[i] = btn
end

-- Return to Lobby
rowBtns[1].MouseButton1Click:Connect(function()
	returnToLobby:FireServer()
	settingsPanel.Visible = false
	-- show lobby
	inLobby = true
	lobbyFrame.Visible = true
	hudFrame.Visible = false
	tokenBar.Visible = false
	hpBarFrame.Visible = false
	settingsBtn.Visible = false
	camera.CameraType = Enum.CameraType.Custom
end)

local settingsVisible = false
settingsBtn.MouseButton1Click:Connect(function()
	settingsVisible = not settingsVisible
	settingsPanel.Visible = settingsVisible
end)

-- ── MorphConfirmed: mark as owned and update shop ────────────────────────────
morphConfirmed.OnClientEvent:Connect(function(morphName)
	print("[LocalScript] MorphConfirmed:", morphName)
	ownedMorphs[morphName] = true
	-- update shop slot text
	for _, s in ipairs(shopSlots) do
		if s.item.name == morphName then
			s.costLabel.Text = "OWNED"
			s.costLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
		end
	end
end)

-- ── Enter game mode (called when PLAY pressed) ────────────────────────────────
local function startGame()
	print("[LocalScript] PLAY pressed — firing GameStarted")
	inLobby = false
	lobbyFrame.Visible = false
	hudFrame.Visible = true
	tokenBar.Visible = true
	hpBarFrame.Visible = true
	settingsBtn.Visible = true
	camera.CameraType = Enum.CameraType.Custom
	gameStarted:FireServer()
end

playBtn.MouseButton1Click:Connect(startGame)

-- ── Lobby camera (cinematic 360) ──────────────────────────────────────────────
RunService.Heartbeat:Connect(function(dt)
	if not inLobby then return end
	cameraAngle = cameraAngle + dt * 0.4
	local dist = 30
	local height = 15
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(
		math.cos(cameraAngle) * dist,
		height,
		math.sin(cameraAngle) * dist
	) * CFrame.Angles(0, cameraAngle + math.pi, 0)
	camera.CFrame = CFrame.lookAt(
		Vector3.new(math.cos(cameraAngle)*dist, height, math.sin(cameraAngle)*dist),
		Vector3.new(0, 5, 0)
	)
end)

-- ── HUD updates ───────────────────────────────────────────────────────────────
-- wave label
waveValue.Changed:Connect(function(v)
	waveLabel.Text = "Wave " .. v
end)

-- timer label
timeValue.Changed:Connect(function(v)
	timeLabel.Text = fmt(v)
	timeLabel.TextColor3 = (v <= 30)
		and Color3.fromRGB(255, 80, 80)
		or Color3.new(1, 1, 1)
end)

-- token label
local function updateTokens()
	local tv = player:FindFirstChild("Tokens")
	if tv then
		tokenLabel.Text = "Tokens: " .. tv.Value
	end
end

player.ChildAdded:Connect(function(child)
	if child.Name == "Tokens" then
		child.Changed:Connect(updateTokens)
		updateTokens()
	end
end)

-- enemy counter
RunService.Heartbeat:Connect(function()
	if inLobby then return end
	local count = 0
	for _, obj in ipairs(workspace:GetChildren()) do
		local n = obj.Name:lower()
		if n == "skibidi toilet" or n == "big skibidi toilet" then
			local h = obj:FindFirstChildOfClass("Humanoid")
			if h and h.Health > 0 then
				count += 1
			end
		end
	end
	enemyLabel.Text = "Enemies: " .. count
end)

print("[LocalScript] Loaded")
