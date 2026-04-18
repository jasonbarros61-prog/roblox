-- LocalScript in StarterGui
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Remove any leftover GUI from a previous spawn
local old = player.PlayerGui:FindFirstChild("SkibieWarzone")
if old then old:Destroy() end

local screen = Instance.new("ScreenGui")
screen.Name         = "SkibieWarzone"
screen.ResetOnSpawn = false
screen.Parent       = player.PlayerGui

-- ─────────────────────────────────────────────────────────────────────────────
-- LOBBY
-- ─────────────────────────────────────────────────────────────────────────────
local lobbyFrame = Instance.new("Frame")
lobbyFrame.Size                   = UDim2.new(1,0,1,0)
lobbyFrame.BackgroundColor3       = Color3.fromRGB(10,10,10)
lobbyFrame.BackgroundTransparency = 0.1
lobbyFrame.ZIndex = 10
lobbyFrame.Parent = screen

-- dot grid
for row=0,20 do for col=0,40 do
	local d = Instance.new("Frame")
	d.Size = UDim2.new(0,3,0,3)
	d.Position = UDim2.new(0,col*25,0,row*25)
	d.BackgroundColor3 = Color3.fromRGB(0,200,80)
	d.BackgroundTransparency = 0.7
	d.BorderSizePixel = 0 d.ZIndex = 11
	Instance.new("UICorner",d).CornerRadius = UDim.new(1,0)
	d.Parent = lobbyFrame
end end

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(0,500,0,80)
titleLbl.Position = UDim2.new(0.5,-250,0.18,0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "SKIBIE WARZONE"
titleLbl.TextColor3 = Color3.fromRGB(0,255,100)
titleLbl.TextScaled = true titleLbl.Font = Enum.Font.GothamBold
titleLbl.ZIndex = 12 titleLbl.Parent = lobbyFrame

local subLbl = Instance.new("TextLabel")
subLbl.Size = UDim2.new(0,400,0,40)
subLbl.Position = UDim2.new(0.5,-200,0.32,0)
subLbl.BackgroundTransparency = 1
subLbl.Text = "Survive the Skibidi Toilets"
subLbl.TextColor3 = Color3.fromRGB(180,255,180)
subLbl.TextScaled = true subLbl.Font = Enum.Font.Gotham
subLbl.ZIndex = 12 subLbl.Parent = lobbyFrame

local playBtn = Instance.new("TextButton")
playBtn.Size = UDim2.new(0,220,0,65)
playBtn.Position = UDim2.new(0.5,-110,0.5,0)
playBtn.BackgroundColor3 = Color3.fromRGB(0,200,80)
playBtn.Text = "PLAY" playBtn.TextColor3 = Color3.new(1,1,1)
playBtn.TextScaled = true playBtn.Font = Enum.Font.GothamBold
playBtn.ZIndex = 12 playBtn.Parent = lobbyFrame
Instance.new("UICorner",playBtn).CornerRadius = UDim.new(0,12)

local shopLobbyBtn = Instance.new("TextButton")
shopLobbyBtn.Size = UDim2.new(0,220,0,55)
shopLobbyBtn.Position = UDim2.new(0.5,-110,0.5,80)
shopLobbyBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
shopLobbyBtn.Text = "SHOP" shopLobbyBtn.TextColor3 = Color3.fromRGB(0,200,80)
shopLobbyBtn.TextScaled = true shopLobbyBtn.Font = Enum.Font.GothamBold
shopLobbyBtn.ZIndex = 12 shopLobbyBtn.Parent = lobbyFrame
Instance.new("UICorner",shopLobbyBtn).CornerRadius = UDim.new(0,12)
Instance.new("UIStroke",shopLobbyBtn).Color = Color3.fromRGB(0,200,80)

-- ─────────────────────────────────────────────────────────────────────────────
-- HUD
-- ─────────────────────────────────────────────────────────────────────────────
local hudFrame = Instance.new("Frame")
hudFrame.Size = UDim2.new(1,0,0,50)
hudFrame.BackgroundColor3 = Color3.fromRGB(10,10,10)
hudFrame.BackgroundTransparency = 0.3
hudFrame.Visible = false hudFrame.ZIndex = 5 hudFrame.Parent = screen

local waveLabel = Instance.new("TextLabel")
waveLabel.Size = UDim2.new(0,200,1,0) waveLabel.Position = UDim2.new(0.5,-100,0,0)
waveLabel.BackgroundTransparency = 1 waveLabel.Text = "Wave 1"
waveLabel.TextColor3 = Color3.new(1,1,1) waveLabel.TextScaled = true
waveLabel.Font = Enum.Font.GothamBold waveLabel.ZIndex = 6 waveLabel.Parent = hudFrame

local timeLabel = Instance.new("TextLabel")
timeLabel.Size = UDim2.new(0,150,1,0) timeLabel.Position = UDim2.new(1,-160,0,0)
timeLabel.BackgroundTransparency = 1 timeLabel.Text = "3:00"
timeLabel.TextColor3 = Color3.new(1,1,1) timeLabel.TextScaled = true
timeLabel.Font = Enum.Font.GothamBold timeLabel.ZIndex = 6 timeLabel.Parent = hudFrame

local enemyLabel = Instance.new("TextLabel")
enemyLabel.Size = UDim2.new(0,200,1,0) enemyLabel.Position = UDim2.new(0,10,0,0)
enemyLabel.BackgroundTransparency = 1 enemyLabel.Text = "Enemies: 0"
enemyLabel.TextColor3 = Color3.fromRGB(255,100,100) enemyLabel.TextScaled = true
enemyLabel.Font = Enum.Font.GothamBold enemyLabel.ZIndex = 6 enemyLabel.Parent = hudFrame

-- ─────────────────────────────────────────────────────────────────────────────
-- TOKEN BAR
-- ─────────────────────────────────────────────────────────────────────────────
local tokenBar = Instance.new("Frame")
tokenBar.Size = UDim2.new(0,180,0,40) tokenBar.Position = UDim2.new(1,-190,0,55)
tokenBar.BackgroundColor3 = Color3.fromRGB(20,20,20)
tokenBar.BackgroundTransparency = 0.2
tokenBar.Visible = false tokenBar.ZIndex = 5 tokenBar.Parent = screen
Instance.new("UICorner",tokenBar).CornerRadius = UDim.new(0,8)

local tokenLabel = Instance.new("TextLabel")
tokenLabel.Size = UDim2.new(1,0,1,0) tokenLabel.BackgroundTransparency = 1
tokenLabel.Text = "Tokens: 0" tokenLabel.TextColor3 = Color3.fromRGB(255,220,0)
tokenLabel.TextScaled = true tokenLabel.Font = Enum.Font.GothamBold
tokenLabel.ZIndex = 6 tokenLabel.Parent = tokenBar

-- ─────────────────────────────────────────────────────────────────────────────
-- HP BAR
-- ─────────────────────────────────────────────────────────────────────────────
game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

local hpBar = Instance.new("Frame")
hpBar.Size = UDim2.new(0,260,0,34) hpBar.Position = UDim2.new(0.5,-130,1,-55)
hpBar.BackgroundColor3 = Color3.fromRGB(10,10,10)
hpBar.BackgroundTransparency = 0.2
hpBar.Visible = false hpBar.ZIndex = 5 hpBar.Parent = screen
Instance.new("UICorner",hpBar).CornerRadius = UDim.new(0,10)
local hpStroke = Instance.new("UIStroke",hpBar)
hpStroke.Color = Color3.fromRGB(180,0,0) hpStroke.Thickness = 2

local hpHeart = Instance.new("TextLabel")
hpHeart.Size = UDim2.new(0,28,1,0) hpHeart.Position = UDim2.new(0,4,0,0)
hpHeart.BackgroundTransparency = 1 hpHeart.Text = "❤"
hpHeart.TextColor3 = Color3.fromRGB(220,0,0) hpHeart.TextScaled = true
hpHeart.Font = Enum.Font.GothamBold hpHeart.ZIndex = 7 hpHeart.Parent = hpBar

local hpTrack = Instance.new("Frame")
hpTrack.Size = UDim2.new(1,-40,0,16) hpTrack.Position = UDim2.new(0,34,0,9)
hpTrack.BackgroundColor3 = Color3.fromRGB(30,0,0)
hpTrack.BorderSizePixel = 0 hpTrack.ZIndex = 6 hpTrack.Parent = hpBar
Instance.new("UICorner",hpTrack).CornerRadius = UDim.new(0,5)

local hpFill = Instance.new("Frame")
hpFill.Size = UDim2.new(1,0,1,0)
hpFill.BackgroundColor3 = Color3.fromRGB(200,20,20)
hpFill.BorderSizePixel = 0 hpFill.ZIndex = 7 hpFill.Parent = hpTrack
Instance.new("UICorner",hpFill).CornerRadius = UDim.new(0,5)

local hpShimmer = Instance.new("Frame")
hpShimmer.Size = UDim2.new(0.4,0,1,0)
hpShimmer.BackgroundColor3 = Color3.new(1,1,1)
hpShimmer.BackgroundTransparency = 0.75
hpShimmer.BorderSizePixel = 0 hpShimmer.ZIndex = 8 hpShimmer.Parent = hpFill
Instance.new("UICorner",hpShimmer).CornerRadius = UDim.new(0,5)

local function updateHP(hp, maxHp)
	local pct = math.clamp(hp/maxHp,0,1)
	hpFill.Size = UDim2.new(pct,0,1,0)
	if pct < 0.25 then hpFill.BackgroundColor3 = Color3.fromRGB(255,50,50)
	elseif pct < 0.5 then hpFill.BackgroundColor3 = Color3.fromRGB(200,20,20)
	else hpFill.BackgroundColor3 = Color3.fromRGB(160,10,10) end
end

local function hookHPChar(char)
	local hum = char:WaitForChild("Humanoid")
	updateHP(hum.Health, hum.MaxHealth)
	hum.HealthChanged:Connect(function(h) updateHP(h, hum.MaxHealth) end)
end
player.CharacterAdded:Connect(hookHPChar)
if player.Character then hookHPChar(player.Character) end

-- ─────────────────────────────────────────────────────────────────────────────
-- BOSS ALERT
-- ─────────────────────────────────────────────────────────────────────────────
local alertFrame = Instance.new("Frame")
alertFrame.Size = UDim2.new(1,0,1,0)
alertFrame.BackgroundColor3 = Color3.fromRGB(150,0,0)
alertFrame.BackgroundTransparency = 1
alertFrame.Visible = false alertFrame.ZIndex = 50 alertFrame.Parent = screen

local alertTitle = Instance.new("TextLabel")
alertTitle.Size = UDim2.new(0,600,0,100) alertTitle.Position = UDim2.new(0.5,-300,0.35,0)
alertTitle.BackgroundTransparency = 1 alertTitle.Text = "☠  FALL BACK  ☠"
alertTitle.TextColor3 = Color3.fromRGB(255,50,50) alertTitle.TextScaled = true
alertTitle.Font = Enum.Font.GothamBold alertTitle.ZIndex = 51 alertTitle.Parent = alertFrame

local alertSub = Instance.new("TextLabel")
alertSub.Size = UDim2.new(0,500,0,50) alertSub.Position = UDim2.new(0.5,-250,0.35,105)
alertSub.BackgroundTransparency = 1 alertSub.Text = "G-MAN HAS ARRIVED"
alertSub.TextColor3 = Color3.fromRGB(255,200,200) alertSub.TextScaled = true
alertSub.Font = Enum.Font.Gotham alertSub.ZIndex = 51 alertSub.Parent = alertFrame

local alertBar = Instance.new("Frame")
alertBar.Size = UDim2.new(0,400,0,30) alertBar.Position = UDim2.new(0.5,-200,0.35,165)
alertBar.BackgroundColor3 = Color3.fromRGB(0,100,220)
alertBar.BackgroundTransparency = 0.3 alertBar.ZIndex = 51 alertBar.Parent = alertFrame
Instance.new("UICorner",alertBar).CornerRadius = UDim.new(0,8)

local alertBarLbl = Instance.new("TextLabel")
alertBarLbl.Size = UDim2.new(1,0,1,0) alertBarLbl.BackgroundTransparency = 1
alertBarLbl.Text = "⚠  BOSS ENEMY  ⚠" alertBarLbl.TextColor3 = Color3.new(1,1,1)
alertBarLbl.TextScaled = true alertBarLbl.Font = Enum.Font.GothamBold
alertBarLbl.ZIndex = 52 alertBarLbl.Parent = alertBar

-- ─────────────────────────────────────────────────────────────────────────────
-- SHOP
-- ─────────────────────────────────────────────────────────────────────────────
local shopFrame = Instance.new("Frame")
shopFrame.Size = UDim2.new(0,480,0,380)
shopFrame.Position = UDim2.new(0.5,-240,1.1,0)
shopFrame.BackgroundColor3 = Color3.fromRGB(15,40,15)
shopFrame.ZIndex = 15 shopFrame.Parent = screen
Instance.new("UICorner",shopFrame).CornerRadius = UDim.new(0,16)
Instance.new("UIStroke",shopFrame).Color = Color3.fromRGB(0,200,80)

local shopTitle = Instance.new("TextLabel")
shopTitle.Size = UDim2.new(1,0,0,45) shopTitle.BackgroundTransparency = 1
shopTitle.Text = "SHOP" shopTitle.TextColor3 = Color3.fromRGB(0,255,100)
shopTitle.TextScaled = true shopTitle.Font = Enum.Font.GothamBold
shopTitle.ZIndex = 16 shopTitle.Parent = shopFrame

local closeShopBtn = Instance.new("TextButton")
closeShopBtn.Size = UDim2.new(0,36,0,36) closeShopBtn.Position = UDim2.new(1,-44,0,5)
closeShopBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
closeShopBtn.Text = "✕" closeShopBtn.TextColor3 = Color3.new(1,1,1)
closeShopBtn.TextScaled = true closeShopBtn.Font = Enum.Font.GothamBold
closeShopBtn.ZIndex = 17 closeShopBtn.Parent = shopFrame
Instance.new("UICorner",closeShopBtn).CornerRadius = UDim.new(0,8)

local grid = Instance.new("Frame")
grid.Size = UDim2.new(1,-20,1,-55) grid.Position = UDim2.new(0,10,0,50)
grid.BackgroundTransparency = 1 grid.ZIndex = 16 grid.Parent = shopFrame
local uiGrid = Instance.new("UIGridLayout")
uiGrid.CellSize = UDim2.new(0,130,0,130)
uiGrid.CellPadding = UDim2.new(0,10,0,10) uiGrid.Parent = grid

local MORPHS = {
	{name="CameraMan", cost=500, col=Color3.fromRGB(50,50,180)},
	{name="???", cost=nil, col=Color3.fromRGB(40,40,40)},
	{name="???", cost=nil, col=Color3.fromRGB(40,40,40)},
	{name="???", cost=nil, col=Color3.fromRGB(40,40,40)},
	{name="???", cost=nil, col=Color3.fromRGB(40,40,40)},
	{name="???", cost=nil, col=Color3.fromRGB(40,40,40)},
}

local ownedMorphs = {}
local shopSlots = {}

for _, m in ipairs(MORPHS) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0,130,0,130) btn.BackgroundColor3 = m.col
	btn.Text = "" btn.ZIndex = 17 btn.Parent = grid
	Instance.new("UICorner",btn).CornerRadius = UDim.new(0,10)

	local nl = Instance.new("TextLabel")
	nl.Size = UDim2.new(1,0,0.4,0) nl.BackgroundTransparency = 1
	nl.Text = m.name nl.TextColor3 = Color3.new(1,1,1)
	nl.TextScaled = true nl.Font = Enum.Font.GothamBold
	nl.ZIndex = 18 nl.Parent = btn

	local cl = Instance.new("TextLabel")
	cl.Size = UDim2.new(1,0,0.3,0) cl.Position = UDim2.new(0,0,0.6,0)
	cl.BackgroundTransparency = 1
	cl.Text = m.cost and (m.cost.." tokens") or "LOCKED"
	cl.TextColor3 = Color3.fromRGB(255,220,0) cl.TextScaled = true
	cl.Font = Enum.Font.Gotham cl.ZIndex = 18 cl.Parent = btn

	table.insert(shopSlots, {btn=btn, morph=m, costLbl=cl})
end

local function openShopPanel()
	TweenService:Create(shopFrame,
		TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
		{Position=UDim2.new(0.5,-240,0.5,-190)}):Play()
end
local function closeShopPanel()
	TweenService:Create(shopFrame,
		TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.In),
		{Position=UDim2.new(0.5,-240,1.1,0)}):Play()
end
shopLobbyBtn.MouseButton1Click:Connect(openShopPanel)
closeShopBtn.MouseButton1Click:Connect(closeShopPanel)

-- ─────────────────────────────────────────────────────────────────────────────
-- SETTINGS
-- ─────────────────────────────────────────────────────────────────────────────
local settingsBtn = Instance.new("TextButton")
settingsBtn.Size = UDim2.new(0,44,0,44) settingsBtn.Position = UDim2.new(0,10,1,-54)
settingsBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
settingsBtn.Text = "⚙" settingsBtn.TextColor3 = Color3.new(1,1,1)
settingsBtn.TextScaled = true settingsBtn.Font = Enum.Font.GothamBold
settingsBtn.Visible = false settingsBtn.ZIndex = 10 settingsBtn.Parent = screen
Instance.new("UICorner",settingsBtn).CornerRadius = UDim.new(0,10)

local settingsPanel = Instance.new("Frame")
settingsPanel.Size = UDim2.new(0,260,0,160) settingsPanel.Position = UDim2.new(0,10,1,-224)
settingsPanel.BackgroundColor3 = Color3.fromRGB(20,20,20)
settingsPanel.BackgroundTransparency = 0.1
settingsPanel.Visible = false settingsPanel.ZIndex = 20 settingsPanel.Parent = screen
Instance.new("UICorner",settingsPanel).CornerRadius = UDim.new(0,12)
Instance.new("UIStroke",settingsPanel).Color = Color3.fromRGB(0,200,80)

local ROW_DEFS = {
	{text="Return to Lobby", col=Color3.fromRGB(255,80,80)},
	{text="Music: ON",       col=Color3.fromRGB(200,200,200)},
	{text="Credits",         col=Color3.fromRGB(200,200,200)},
}
local rowBtns = {}
for i, r in ipairs(ROW_DEFS) do
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1,-20,0,40) b.Position = UDim2.new(0,10,0,(i-1)*50+10)
	b.BackgroundColor3 = Color3.fromRGB(35,35,35) b.Text = r.text
	b.TextColor3 = r.col b.TextScaled = true b.Font = Enum.Font.GothamBold
	b.ZIndex = 21 b.Parent = settingsPanel
	Instance.new("UICorner",b).CornerRadius = UDim.new(0,8)
	rowBtns[i] = b
end

local settingsOpen = false
settingsBtn.MouseButton1Click:Connect(function()
	settingsOpen = not settingsOpen
	settingsPanel.Visible = settingsOpen
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- LOBBY/GAME SWITCH HELPERS
-- ─────────────────────────────────────────────────────────────────────────────
local inLobby = true
local camAngle = 0

local function goLobby()
	inLobby = true
	lobbyFrame.Visible = true
	hudFrame.Visible = false tokenBar.Visible = false
	hpBar.Visible = false settingsBtn.Visible = false
	settingsPanel.Visible = false settingsOpen = false
	camera.CameraType = Enum.CameraType.Custom
end

local function goGame()
	inLobby = false
	lobbyFrame.Visible = false
	hudFrame.Visible = true tokenBar.Visible = true
	hpBar.Visible = true settingsBtn.Visible = true
	camera.CameraType = Enum.CameraType.Custom
end

-- ─────────────────────────────────────────────────────────────────────────────
-- LOOPS
-- ─────────────────────────────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function(dt)
	if not inLobby then return end
	camAngle = camAngle + dt * 0.4
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(
		Vector3.new(math.cos(camAngle)*30, 15, math.sin(camAngle)*30),
		Vector3.new(0,5,0))
end)

RunService.Heartbeat:Connect(function()
	if inLobby then return end
	local n = 0
	for _, obj in ipairs(workspace:GetChildren()) do
		local nm = obj.Name:lower()
		if nm == "skibidi toilet" or nm == "big skibidi toilet" then
			local h = obj:FindFirstChildOfClass("Humanoid")
			if h and h.Health > 0 then n += 1 end
		end
	end
	enemyLabel.Text = "Enemies: " .. n
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- CONNECT SERVER EVENTS (in background — GUI above is already working)
-- ─────────────────────────────────────────────────────────────────────────────
task.spawn(function()
	local RS = ReplicatedStorage

	local gameStarted    = RS:WaitForChild("GameStarted",    30)
	local buyMorphEv     = RS:WaitForChild("BuyMorph",       30)
	local equipMorphEv   = RS:WaitForChild("EquipMorph",     30)
	local morphConfirmed = RS:WaitForChild("MorphConfirmed", 30)
	local returnToLobby  = RS:WaitForChild("ReturnToLobby",  30)
	local bossSpawned    = RS:WaitForChild("BossSpawned",    30)
	local gameData       = RS:WaitForChild("GameData",       30)

	if not gameStarted or not gameData then
		-- Show error on screen so player knows what's wrong
		local errLbl = Instance.new("TextLabel")
		errLbl.Size = UDim2.new(1,0,0,40)
		errLbl.Position = UDim2.new(0,0,1,-45)
		errLbl.BackgroundColor3 = Color3.fromRGB(180,0,0)
		errLbl.BackgroundTransparency = 0.2
		errLbl.Text = "ERROR: WaveManager script missing from ServerScriptService!"
		errLbl.TextColor3 = Color3.new(1,1,1)
		errLbl.TextScaled = true errLbl.Font = Enum.Font.GothamBold
		errLbl.ZIndex = 200 errLbl.Parent = screen
		return
	end

	local waveValue = gameData:WaitForChild("Wave",     10)
	local timeValue = gameData:WaitForChild("TimeLeft", 10)

	local function fmtTime(s)
		s = math.max(0, math.floor(s))
		return string.format("%d:%02d", math.floor(s/60), s%60)
	end

	-- Wire up PLAY
	playBtn.MouseButton1Click:Connect(function()
		goGame()
		gameStarted:FireServer()
	end)

	-- Wire up Return to Lobby (settings)
	rowBtns[1].MouseButton1Click:Connect(function()
		returnToLobby:FireServer()
		goLobby()
	end)

	-- Wire up shop slots
	for _, s in ipairs(shopSlots) do
		if s.morph.cost then
			s.btn.MouseButton1Click:Connect(function()
				if ownedMorphs[s.morph.name] then
					equipMorphEv:FireServer(s.morph.name)
				else
					buyMorphEv:FireServer(s.morph.name)
				end
			end)
		end
	end

	-- Morph confirmed
	morphConfirmed.OnClientEvent:Connect(function(morphName)
		ownedMorphs[morphName] = true
		for _, s in ipairs(shopSlots) do
			if s.morph.name == morphName then
				s.costLbl.Text = "OWNED"
				s.costLbl.TextColor3 = Color3.fromRGB(0,255,100)
			end
		end
	end)

	-- Boss alert
	local alertActive = false
	bossSpawned.OnClientEvent:Connect(function()
		if alertActive then return end
		alertActive = true alertFrame.Visible = true
		TweenService:Create(alertFrame,
			TweenInfo.new(0.2,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,4,true),
			{BackgroundTransparency=0.7}):Play()
		TweenService:Create(alertTitle,
			TweenInfo.new(0.4,Enum.EasingStyle.Sine,Enum.EasingDirection.Out,3,true),
			{TextColor3=Color3.fromRGB(255,255,100)}):Play()
		task.delay(3.5, function()
			TweenService:Create(alertFrame,  TweenInfo.new(0.6),{BackgroundTransparency=1}):Play()
			TweenService:Create(alertTitle,  TweenInfo.new(0.6),{TextTransparency=1}):Play()
			TweenService:Create(alertSub,    TweenInfo.new(0.6),{TextTransparency=1}):Play()
			TweenService:Create(alertBar,    TweenInfo.new(0.6),{BackgroundTransparency=1}):Play()
			task.wait(0.7)
			alertFrame.Visible = false
			alertTitle.TextTransparency = 0 alertSub.TextTransparency = 0
			alertBar.BackgroundTransparency = 0.3 alertActive = false
		end)
	end)

	-- Wave / timer labels
	waveValue.Changed:Connect(function(v) waveLabel.Text = "Wave "..v end)
	timeValue.Changed:Connect(function(v)
		timeLabel.Text = fmtTime(v)
		timeLabel.TextColor3 = v<=30 and Color3.fromRGB(255,80,80) or Color3.new(1,1,1)
	end)

	-- Token display
	local function refreshTokens()
		local tv = player:FindFirstChild("Tokens")
		if tv then tokenLabel.Text = "Tokens: "..tv.Value end
	end
	player.ChildAdded:Connect(function(c)
		if c.Name == "Tokens" then c.Changed:Connect(refreshTokens) refreshTokens() end
	end)
	local tok = player:FindFirstChild("Tokens")
	if tok then tok.Changed:Connect(refreshTokens) refreshTokens() end
end)
