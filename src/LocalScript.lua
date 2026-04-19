-- LocalScript  →  StarterGui  (LocalScript, NOT Script)
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- destroy any duplicate left over from a respawn
local old = player.PlayerGui:FindFirstChild("SkibieWarzone")
if old then old:Destroy() end

local screen = Instance.new("ScreenGui")
screen.Name = "SkibieWarzone"
screen.ResetOnSpawn = false
screen.Parent = player.PlayerGui

-- helper: fire a RemoteEvent by name (non-blocking, works even before events exist)
local function fire(name, ...)
	local args = {...}
	task.spawn(function()
		local ev = ReplicatedStorage:WaitForChild(name, 20)
		if ev then ev:FireServer(table.unpack(args)) end
	end)
end

-- ─── STATE ────────────────────────────────────────────────────────────────────
local inLobby     = true
local ownedMorphs = {}
local camAngle    = 0

-- ─── LOBBY ────────────────────────────────────────────────────────────────────
local lobbyBg = Instance.new("Frame")
lobbyBg.Size = UDim2.new(1,0,1,0)
lobbyBg.BackgroundColor3 = Color3.fromRGB(10,10,10)
lobbyBg.BackgroundTransparency = 0.1
lobbyBg.ZIndex = 10
lobbyBg.Parent = screen

for row = 0, 20 do for col = 0, 40 do
	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0,3,0,3)
	dot.Position = UDim2.new(0,col*25,0,row*25)
	dot.BackgroundColor3 = Color3.fromRGB(0,200,80)
	dot.BackgroundTransparency = 0.7
	dot.BorderSizePixel = 0
	dot.ZIndex = 11
	Instance.new("UICorner",dot).CornerRadius = UDim.new(1,0)
	dot.Parent = lobbyBg
end end

local function makeLbl(parent, text, size, pos, color, font, z)
	local l = Instance.new("TextLabel")
	l.Size = size l.Position = pos
	l.BackgroundTransparency = 1
	l.Text = text l.TextColor3 = color
	l.TextScaled = true l.Font = font
	l.ZIndex = z l.Parent = parent
	return l
end

makeLbl(lobbyBg,"SKIBIE WARZONE",
	UDim2.new(0,500,0,80), UDim2.new(0.5,-250,0.18,0),
	Color3.fromRGB(0,255,100), Enum.Font.GothamBold, 12)
makeLbl(lobbyBg,"Survive the Skibidi Toilets",
	UDim2.new(0,400,0,40), UDim2.new(0.5,-200,0.32,0),
	Color3.fromRGB(180,255,180), Enum.Font.Gotham, 12)

local function makeBtn(parent, text, size, pos, bg, fg, z)
	local b = Instance.new("TextButton")
	b.Size = size b.Position = pos
	b.BackgroundColor3 = bg b.Text = text
	b.TextColor3 = fg b.TextScaled = true
	b.Font = Enum.Font.GothamBold b.ZIndex = z b.Parent = parent
	Instance.new("UICorner",b).CornerRadius = UDim.new(0,12)
	return b
end

local playBtn = makeBtn(lobbyBg,"PLAY",
	UDim2.new(0,220,0,65), UDim2.new(0.5,-110,0.5,0),
	Color3.fromRGB(0,200,80), Color3.new(1,1,1), 12)

local shopLobbyBtn = makeBtn(lobbyBg,"SHOP",
	UDim2.new(0,220,0,55), UDim2.new(0.5,-110,0.5,80),
	Color3.fromRGB(30,30,30), Color3.fromRGB(0,200,80), 12)
Instance.new("UIStroke",shopLobbyBtn).Color = Color3.fromRGB(0,200,80)

-- ─── HUD ──────────────────────────────────────────────────────────────────────
local hud = Instance.new("Frame")
hud.Size = UDim2.new(1,0,0,50)
hud.BackgroundColor3 = Color3.fromRGB(10,10,10)
hud.BackgroundTransparency = 0.3
hud.Visible = false hud.ZIndex = 5 hud.Parent = screen

local waveLabel  = makeLbl(hud,"Wave 1",UDim2.new(0,200,1,0),UDim2.new(0.5,-100,0,0),Color3.new(1,1,1),Enum.Font.GothamBold,6)
local timeLabel  = makeLbl(hud,"3:00",UDim2.new(0,150,1,0),UDim2.new(1,-160,0,0),Color3.new(1,1,1),Enum.Font.GothamBold,6)
local enemyLabel = makeLbl(hud,"Enemies: 0",UDim2.new(0,200,1,0),UDim2.new(0,10,0,0),Color3.fromRGB(255,100,100),Enum.Font.GothamBold,6)

-- ─── TOKEN BAR ────────────────────────────────────────────────────────────────
local tokenBar = Instance.new("Frame")
tokenBar.Size = UDim2.new(0,180,0,40)
tokenBar.Position = UDim2.new(1,-190,0,55)
tokenBar.BackgroundColor3 = Color3.fromRGB(20,20,20)
tokenBar.BackgroundTransparency = 0.2
tokenBar.Visible = false tokenBar.ZIndex = 5 tokenBar.Parent = screen
Instance.new("UICorner",tokenBar).CornerRadius = UDim.new(0,8)
local tokenLabel = makeLbl(tokenBar,"Tokens: 0",UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),Color3.fromRGB(255,220,0),Enum.Font.GothamBold,6)

-- ─── HP BAR ───────────────────────────────────────────────────────────────────
game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

local hpBar = Instance.new("Frame")
hpBar.Size = UDim2.new(0,260,0,34)
hpBar.Position = UDim2.new(0.5,-130,1,-55)
hpBar.BackgroundColor3 = Color3.fromRGB(10,10,10)
hpBar.BackgroundTransparency = 0.2
hpBar.Visible = false hpBar.ZIndex = 5 hpBar.Parent = screen
Instance.new("UICorner",hpBar).CornerRadius = UDim.new(0,10)
local hpStroke = Instance.new("UIStroke",hpBar)
hpStroke.Color = Color3.fromRGB(180,0,0) hpStroke.Thickness = 2

makeLbl(hpBar,"❤",UDim2.new(0,26,1,0),UDim2.new(0,4,0,0),Color3.fromRGB(220,0,0),Enum.Font.GothamBold,7)

local hpTrack = Instance.new("Frame")
hpTrack.Size = UDim2.new(1,-38,0,16) hpTrack.Position = UDim2.new(0,34,0,9)
hpTrack.BackgroundColor3 = Color3.fromRGB(30,0,0) hpTrack.BorderSizePixel = 0
hpTrack.ZIndex = 6 hpTrack.Parent = hpBar
Instance.new("UICorner",hpTrack).CornerRadius = UDim.new(0,5)

local hpFill = Instance.new("Frame")
hpFill.Size = UDim2.new(1,0,1,0) hpFill.BackgroundColor3 = Color3.fromRGB(200,20,20)
hpFill.BorderSizePixel = 0 hpFill.ZIndex = 7 hpFill.Parent = hpTrack
Instance.new("UICorner",hpFill).CornerRadius = UDim.new(0,5)

local hpShimmer = Instance.new("Frame")
hpShimmer.Size = UDim2.new(0.4,0,1,0) hpShimmer.BackgroundColor3 = Color3.new(1,1,1)
hpShimmer.BackgroundTransparency = 0.75 hpShimmer.BorderSizePixel = 0
hpShimmer.ZIndex = 8 hpShimmer.Parent = hpFill
Instance.new("UICorner",hpShimmer).CornerRadius = UDim.new(0,5)

local function setHP(hp, max)
	local p = math.clamp(hp/max,0,1)
	hpFill.Size = UDim2.new(p,0,1,0)
	hpFill.BackgroundColor3 = p<0.25 and Color3.fromRGB(255,50,50) or p<0.5 and Color3.fromRGB(200,20,20) or Color3.fromRGB(160,10,10)
end
local function hookHP(char)
	local h = char:WaitForChild("Humanoid")
	setHP(h.Health,h.MaxHealth)
	h.HealthChanged:Connect(function(v) setHP(v,h.MaxHealth) end)
end
player.CharacterAdded:Connect(hookHP)
if player.Character then hookHP(player.Character) end

-- ─── BOSS ALERT ───────────────────────────────────────────────────────────────
local alertBg = Instance.new("Frame")
alertBg.Size = UDim2.new(1,0,1,0) alertBg.BackgroundColor3 = Color3.fromRGB(150,0,0)
alertBg.BackgroundTransparency = 1 alertBg.Visible = false alertBg.ZIndex = 50 alertBg.Parent = screen

local alertTitleLbl = makeLbl(alertBg,"☠  FALL BACK  ☠",UDim2.new(0,600,0,100),UDim2.new(0.5,-300,0.35,0),Color3.fromRGB(255,50,50),Enum.Font.GothamBold,51)
local alertSubLbl   = makeLbl(alertBg,"G-MAN HAS ARRIVED",UDim2.new(0,500,0,50),UDim2.new(0.5,-250,0.35,105),Color3.fromRGB(255,200,200),Enum.Font.Gotham,51)

local alertBarFrame = Instance.new("Frame")
alertBarFrame.Size = UDim2.new(0,400,0,30) alertBarFrame.Position = UDim2.new(0.5,-200,0.35,165)
alertBarFrame.BackgroundColor3 = Color3.fromRGB(0,100,220) alertBarFrame.BackgroundTransparency = 0.3
alertBarFrame.ZIndex = 51 alertBarFrame.Parent = alertBg
Instance.new("UICorner",alertBarFrame).CornerRadius = UDim.new(0,8)
makeLbl(alertBarFrame,"⚠  BOSS ENEMY  ⚠",UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),Color3.new(1,1,1),Enum.Font.GothamBold,52)

-- ─── SHOP ─────────────────────────────────────────────────────────────────────
local shopFrame = Instance.new("Frame")
shopFrame.Size = UDim2.new(0,480,0,380)
shopFrame.Position = UDim2.new(0.5,-240,1.1,0)
shopFrame.BackgroundColor3 = Color3.fromRGB(15,40,15) shopFrame.ZIndex = 15 shopFrame.Parent = screen
Instance.new("UICorner",shopFrame).CornerRadius = UDim.new(0,16)
Instance.new("UIStroke",shopFrame).Color = Color3.fromRGB(0,200,80)

makeLbl(shopFrame,"SHOP",UDim2.new(1,0,0,45),UDim2.new(0,0,0,0),Color3.fromRGB(0,255,100),Enum.Font.GothamBold,16)

local closeShopBtn = makeBtn(shopFrame,"✕",UDim2.new(0,36,0,36),UDim2.new(1,-44,0,5),Color3.fromRGB(200,50,50),Color3.new(1,1,1),17)

local grid = Instance.new("Frame")
grid.Size = UDim2.new(1,-20,1,-55) grid.Position = UDim2.new(0,10,0,50)
grid.BackgroundTransparency = 1 grid.ZIndex = 16 grid.Parent = shopFrame
local uiGrid = Instance.new("UIGridLayout")
uiGrid.CellSize = UDim2.new(0,130,0,130) uiGrid.CellPadding = UDim2.new(0,10,0,10) uiGrid.Parent = grid

local MORPHS = {
	{name="CameraMan", cost=500, col=Color3.fromRGB(50,50,180)},
	{name="???", col=Color3.fromRGB(40,40,40)},
	{name="???", col=Color3.fromRGB(40,40,40)},
	{name="???", col=Color3.fromRGB(40,40,40)},
	{name="???", col=Color3.fromRGB(40,40,40)},
	{name="???", col=Color3.fromRGB(40,40,40)},
}
local shopSlots = {}
for _,m in ipairs(MORPHS) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0,130,0,130) btn.BackgroundColor3 = m.col
	btn.Text = "" btn.ZIndex = 17 btn.Parent = grid
	Instance.new("UICorner",btn).CornerRadius = UDim.new(0,10)
	makeLbl(btn,m.name,UDim2.new(1,0,0.4,0),UDim2.new(0,0,0,0),Color3.new(1,1,1),Enum.Font.GothamBold,18)
	local cl = makeLbl(btn,m.cost and (m.cost.." tokens") or "LOCKED",UDim2.new(1,0,0.3,0),UDim2.new(0,0,0.6,0),Color3.fromRGB(255,220,0),Enum.Font.Gotham,18)
	if m.cost then
		btn.MouseButton1Click:Connect(function()
			if ownedMorphs[m.name] then fire("EquipMorph",m.name)
			else fire("BuyMorph",m.name) end
		end)
	end
	table.insert(shopSlots,{btn=btn,morph=m,costLbl=cl})
end

local function openShop()
	TweenService:Create(shopFrame,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
		{Position=UDim2.new(0.5,-240,0.5,-190)}):Play()
end
local function closeShop()
	TweenService:Create(shopFrame,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.In),
		{Position=UDim2.new(0.5,-240,1.1,0)}):Play()
end
shopLobbyBtn.MouseButton1Click:Connect(openShop)
closeShopBtn.MouseButton1Click:Connect(closeShop)

-- ─── SETTINGS ─────────────────────────────────────────────────────────────────
local settingsBtn = makeBtn(screen,"⚙",UDim2.new(0,44,0,44),UDim2.new(0,10,1,-54),Color3.fromRGB(30,30,30),Color3.new(1,1,1),10)
settingsBtn.Visible = false

local settingsPanel = Instance.new("Frame")
settingsPanel.Size = UDim2.new(0,260,0,160) settingsPanel.Position = UDim2.new(0,10,1,-224)
settingsPanel.BackgroundColor3 = Color3.fromRGB(20,20,20) settingsPanel.BackgroundTransparency = 0.1
settingsPanel.Visible = false settingsPanel.ZIndex = 20 settingsPanel.Parent = screen
Instance.new("UICorner",settingsPanel).CornerRadius = UDim.new(0,12)
Instance.new("UIStroke",settingsPanel).Color = Color3.fromRGB(0,200,80)

local ROWS = {{text="Return to Lobby",col=Color3.fromRGB(255,80,80)},{text="Music: ON",col=Color3.fromRGB(200,200,200)},{text="Credits",col=Color3.fromRGB(200,200,200)}}
local rowBtns = {}
for i,r in ipairs(ROWS) do
	local b = makeBtn(settingsPanel,r.text,UDim2.new(1,-20,0,40),UDim2.new(0,10,0,(i-1)*50+10),Color3.fromRGB(35,35,35),r.col,21)
	rowBtns[i] = b
end

local settingsOpen = false
settingsBtn.MouseButton1Click:Connect(function()
	settingsOpen = not settingsOpen
	settingsPanel.Visible = settingsOpen
end)

-- ─── SHOW/HIDE ────────────────────────────────────────────────────────────────
local function goLobby()
	inLobby = true
	lobbyBg.Visible = true hud.Visible = false tokenBar.Visible = false
	hpBar.Visible = false settingsBtn.Visible = false settingsPanel.Visible = false
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(Vector3.new(math.cos(camAngle)*30,15,math.sin(camAngle)*30),Vector3.new(0,5,0))
end
local function goGame()
	inLobby = false
	lobbyBg.Visible = false hud.Visible = true
	tokenBar.Visible = true hpBar.Visible = true settingsBtn.Visible = true
	camera.CameraType = Enum.CameraType.Custom
end

-- ─── BUTTON WIRING ────────────────────────────────────────────────────────────
playBtn.MouseButton1Click:Connect(function()
	goGame()
	fire("GameStarted")
end)

rowBtns[1].MouseButton1Click:Connect(function()
	fire("ReturnToLobby")
	goLobby()
end)

-- ─── LOOPS ────────────────────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function(dt)
	if not inLobby then return end
	camAngle = camAngle + dt * 0.4
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(Vector3.new(math.cos(camAngle)*30,15,math.sin(camAngle)*30),Vector3.new(0,5,0))
end)

RunService.Heartbeat:Connect(function()
	if inLobby then return end
	local n = 0
	for _,obj in ipairs(workspace:GetChildren()) do
		local nm = obj.Name:lower()
		if nm=="skibidi toilet" or nm=="big skibidi toilet" then
			local h = obj:FindFirstChildOfClass("Humanoid")
			if h and h.Health > 0 then n += 1 end
		end
	end
	enemyLabel.Text = "Enemies: "..n
end)

-- ─── SERVER EVENTS (background – only needed for server→client signals) ───────
task.spawn(function()
	local RS = ReplicatedStorage
	local morphConfirmed = RS:WaitForChild("MorphConfirmed", 30)
	local bossSpawned    = RS:WaitForChild("BossSpawned",    30)
	local gameData       = RS:WaitForChild("GameData",       30)
	if not morphConfirmed then return end

	local waveValue = gameData:WaitForChild("Wave",10)
	local timeValue = gameData:WaitForChild("TimeLeft",10)

	local function fmt(s)
		s = math.max(0,math.floor(s))
		return string.format("%d:%02d",math.floor(s/60),s%60)
	end

	waveValue.Changed:Connect(function(v) waveLabel.Text = "Wave "..v end)
	timeValue.Changed:Connect(function(v)
		timeLabel.Text = fmt(v)
		timeLabel.TextColor3 = v<=30 and Color3.fromRGB(255,80,80) or Color3.new(1,1,1)
	end)

	morphConfirmed.OnClientEvent:Connect(function(name)
		ownedMorphs[name] = true
		for _,s in ipairs(shopSlots) do
			if s.morph.name == name then
				s.costLbl.Text = "OWNED" s.costLbl.TextColor3 = Color3.fromRGB(0,255,100)
			end
		end
	end)

	local alertActive = false
	bossSpawned.OnClientEvent:Connect(function()
		if alertActive then return end
		alertActive = true alertBg.Visible = true
		TweenService:Create(alertBg,TweenInfo.new(0.2,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,4,true),{BackgroundTransparency=0.7}):Play()
		TweenService:Create(alertTitleLbl,TweenInfo.new(0.4,Enum.EasingStyle.Sine,Enum.EasingDirection.Out,3,true),{TextColor3=Color3.fromRGB(255,255,100)}):Play()
		task.delay(3.5,function()
			TweenService:Create(alertBg,TweenInfo.new(0.6),{BackgroundTransparency=1}):Play()
			TweenService:Create(alertTitleLbl,TweenInfo.new(0.6),{TextTransparency=1}):Play()
			TweenService:Create(alertSubLbl,TweenInfo.new(0.6),{TextTransparency=1}):Play()
			TweenService:Create(alertBarFrame,TweenInfo.new(0.6),{BackgroundTransparency=1}):Play()
			task.wait(0.7) alertBg.Visible=false
			alertTitleLbl.TextTransparency=0 alertSubLbl.TextTransparency=0
			alertBarFrame.BackgroundTransparency=0.3 alertActive=false
		end)
	end)

	local function refreshTokens()
		local tv = player:FindFirstChild("Tokens")
		if tv then tokenLabel.Text = "Tokens: "..tv.Value end
	end
	player.ChildAdded:Connect(function(c)
		if c.Name=="Tokens" then c.Changed:Connect(refreshTokens) refreshTokens() end
	end)
	local tok = player:FindFirstChild("Tokens")
	if tok then tok.Changed:Connect(refreshTokens) refreshTokens() end
end)
