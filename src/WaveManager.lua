-- WaveManager: Script in ServerScriptService
local ServerStorage     = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local function makeEvent(name)
	local e = ReplicatedStorage:FindFirstChild(name)
	if not e then
		e = Instance.new("RemoteEvent")
		e.Name = name
		e.Parent = ReplicatedStorage
	end
	return e
end

local gameStarted    = makeEvent("GameStarted")
local buyMorph       = makeEvent("BuyMorph")
local equipMorph     = makeEvent("EquipMorph")
local morphConfirmed = makeEvent("MorphConfirmed")
local returnToLobby  = makeEvent("ReturnToLobby")
local bossSpawned    = makeEvent("BossSpawned")

-- GameData
local gameData = ReplicatedStorage:FindFirstChild("GameData")
if not gameData then
	gameData = Instance.new("Folder")
	gameData.Name = "GameData"
	gameData.Parent = ReplicatedStorage
end
local waveValue = gameData:FindFirstChild("Wave")
if not waveValue then
	waveValue = Instance.new("NumberValue")
	waveValue.Name = "Wave" waveValue.Value = 1 waveValue.Parent = gameData
end
local timeValue = gameData:FindFirstChild("TimeLeft")
if not timeValue then
	timeValue = Instance.new("NumberValue")
	timeValue.Name = "TimeLeft" timeValue.Value = 180 timeValue.Parent = gameData
end

-- Tokens
local playerTokens = {}
Players.PlayerAdded:Connect(function(player)
	playerTokens[player] = 0
	local tv = Instance.new("NumberValue")
	tv.Name = "Tokens" tv.Value = 0 tv.Parent = player
end)
Players.PlayerRemoving:Connect(function(player)
	playerTokens[player] = nil
end)

-- ── Detailed overhead HP bar (visible to all players) ─────────────────────────
local function createOverheadHP(character, player)
	local head = character:WaitForChild("Head", 5)
	if not head then return end
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end

	-- remove any old one
	local old = head:FindFirstChild("OverheadHP")
	if old then old:Destroy() end

	local bb = Instance.new("BillboardGui")
	bb.Name          = "OverheadHP"
	bb.Size          = UDim2.new(0, 220, 0, 72)
	bb.StudsOffset   = Vector3.new(0, 2.8, 0)
	bb.AlwaysOnTop   = false
	bb.MaxDistance   = 60
	bb.Parent        = head

	-- outer red glow ring
	local glow = Instance.new("Frame")
	glow.Size                   = UDim2.new(1, 8, 1, 8)
	glow.Position               = UDim2.new(0, -4, 0, -4)
	glow.BackgroundColor3       = Color3.fromRGB(180, 0, 0)
	glow.BackgroundTransparency = 0.45
	glow.BorderSizePixel        = 0
	glow.ZIndex                 = 1
	glow.Parent                 = bb
	Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 12)

	-- main background
	local bg = Instance.new("Frame")
	bg.Size             = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
	bg.BackgroundTransparency = 0.05
	bg.BorderSizePixel  = 0
	bg.ZIndex           = 2
	bg.Parent           = bb
	Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 9)
	local bgStroke = Instance.new("UIStroke", bg)
	bgStroke.Color     = Color3.fromRGB(200, 0, 0)
	bgStroke.Thickness = 2

	-- heart icon
	local heartIcon = Instance.new("TextLabel")
	heartIcon.Size               = UDim2.new(0, 20, 0, 20)
	heartIcon.Position           = UDim2.new(0, 5, 0, 4)
	heartIcon.BackgroundTransparency = 1
	heartIcon.Text               = "❤"
	heartIcon.TextColor3         = Color3.fromRGB(255, 60, 60)
	heartIcon.TextScaled         = true
	heartIcon.Font               = Enum.Font.GothamBold
	heartIcon.ZIndex             = 4
	heartIcon.Parent             = bg

	-- player name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size               = UDim2.new(1, -30, 0, 20)
	nameLabel.Position           = UDim2.new(0, 28, 0, 4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text               = player.Name
	nameLabel.TextColor3         = Color3.new(1, 1, 1)
	nameLabel.TextScaled         = true
	nameLabel.Font               = Enum.Font.GothamBold
	nameLabel.TextXAlignment     = Enum.TextXAlignment.Left
	nameLabel.ZIndex             = 4
	nameLabel.Parent             = bg

	-- divider line
	local divider = Instance.new("Frame")
	divider.Size             = UDim2.new(1, -10, 0, 1)
	divider.Position         = UDim2.new(0, 5, 0, 26)
	divider.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
	divider.BorderSizePixel  = 0
	divider.ZIndex           = 3
	divider.Parent           = bg

	-- HP bar track
	local hpTrack = Instance.new("Frame")
	hpTrack.Size             = UDim2.new(1, -10, 0, 18)
	hpTrack.Position         = UDim2.new(0, 5, 0, 30)
	hpTrack.BackgroundColor3 = Color3.fromRGB(25, 0, 0)
	hpTrack.BorderSizePixel  = 0
	hpTrack.ZIndex           = 3
	hpTrack.Parent           = bg
	Instance.new("UICorner", hpTrack).CornerRadius = UDim.new(0, 6)
	local trackStroke = Instance.new("UIStroke", hpTrack)
	trackStroke.Color = Color3.fromRGB(80, 0, 0) trackStroke.Thickness = 1

	-- HP fill
	local hpFill = Instance.new("Frame")
	hpFill.Size             = UDim2.new(1, 0, 1, 0)
	hpFill.BackgroundColor3 = Color3.fromRGB(200, 15, 15)
	hpFill.BorderSizePixel  = 0
	hpFill.ZIndex           = 4
	hpFill.Parent           = hpTrack
	Instance.new("UICorner", hpFill).CornerRadius = UDim.new(0, 6)

	-- top shimmer stripe
	local shimmer = Instance.new("Frame")
	shimmer.Size                   = UDim2.new(1, 0, 0.45, 0)
	shimmer.BackgroundColor3       = Color3.new(1, 1, 1)
	shimmer.BackgroundTransparency = 0.72
	shimmer.BorderSizePixel        = 0
	shimmer.ZIndex                 = 5
	shimmer.Parent                 = hpFill
	Instance.new("UICorner", shimmer).CornerRadius = UDim.new(0, 6)

	-- HP numbers
	local hpNumbers = Instance.new("TextLabel")
	hpNumbers.Size               = UDim2.new(1, -10, 0, 16)
	hpNumbers.Position           = UDim2.new(0, 5, 0, 51)
	hpNumbers.BackgroundTransparency = 1
	hpNumbers.Text               = "1000 / 1000"
	hpNumbers.TextColor3         = Color3.fromRGB(255, 140, 140)
	hpNumbers.TextScaled         = true
	hpNumbers.Font               = Enum.Font.Gotham
	hpNumbers.ZIndex             = 4
	hpNumbers.Parent             = bg

	-- update on health change
	local function refresh(health)
		local pct = math.clamp(health / humanoid.MaxHealth, 0, 1)
		hpFill.Size     = UDim2.new(pct, 0, 1, 0)
		hpNumbers.Text  = math.ceil(health) .. " / " .. math.ceil(humanoid.MaxHealth)
		if pct < 0.25 then
			hpFill.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
			bgStroke.Color          = Color3.fromRGB(255, 40, 40)
			glow.BackgroundColor3   = Color3.fromRGB(255, 40, 40)
		elseif pct < 0.5 then
			hpFill.BackgroundColor3 = Color3.fromRGB(220, 110, 0)
			bgStroke.Color          = Color3.fromRGB(220, 110, 0)
			glow.BackgroundColor3   = Color3.fromRGB(220, 110, 0)
		else
			hpFill.BackgroundColor3 = Color3.fromRGB(200, 15, 15)
			bgStroke.Color          = Color3.fromRGB(200, 0, 0)
			glow.BackgroundColor3   = Color3.fromRGB(180, 0, 0)
		end
	end

	refresh(humanoid.Health)
	humanoid.HealthChanged:Connect(refresh)
end

-- Player 1000 HP + overhead bar
local function setupPlayer(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.MaxHealth = 1000
		humanoid.Health    = 1000
		task.wait() -- let health apply before drawing bar
		createOverheadHP(character, player)
	end)
end

for _, p in ipairs(Players:GetPlayers()) do setupPlayer(p) end
Players.PlayerAdded:Connect(setupPlayer)

-- Models
local smallToilet = ServerStorage:FindFirstChild("skibidi toilet")
local bigToilet   = ServerStorage:FindFirstChild("big skibidi toilet")
local gmanModel   = ServerStorage:FindFirstChild("GMAN")

if not smallToilet then warn("[WaveManager] MISSING: skibidi toilet") end
if not bigToilet   then warn("[WaveManager] MISSING: big skibidi toilet") end
if not gmanModel   then warn("[WaveManager] MISSING: GMAN") end

local SPAWN_RADIUS = 40
local SPAWN_HEIGHT = 5

local function randomSpawnCF()
	local angle = math.random() * 2 * math.pi
	local r = SPAWN_RADIUS * (0.5 + math.random() * 0.5)
	return CFrame.new(math.cos(angle)*r, SPAWN_HEIGHT, math.sin(angle)*r)
end

local WAVES = {
	{small=4, big=0, gman=0},
	{small=5, big=1, gman=0},
	{small=6, big=2, gman=0},
	{small=7, big=3, gman=1},
	{small=8, big=4, gman=1},
	{small=8, big=4, gman=2},
}

local activeToilets = {}
local gameRunning   = false

local function clearToilets()
	for _, npc in ipairs(activeToilets) do
		if npc and npc.Parent then npc:Destroy() end
	end
	activeToilets = {}
end

local function spawnToilet(template, spawnCF)
	if not template then warn("[WaveManager] Template nil — skip") return end
	local npc = template:Clone()
	npc.Parent = workspace
	local root = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("BasePart")
	if root then
		npc:PivotTo(spawnCF)
		print("[WaveManager] Spawned", npc.Name, "at", spawnCF.Position)
	else
		warn("[WaveManager] No root part on", npc.Name)
	end
	table.insert(activeToilets, npc)
end

local function countEnemies()
	local n = 0
	for _, npc in ipairs(activeToilets) do
		if npc and npc.Parent then
			local h = npc:FindFirstChildOfClass("Humanoid")
			if h and h.Health > 0 then n += 1 end
		end
	end
	return n
end

local function startGame(player)
	if gameRunning then return end
	gameRunning = true
	print("[WaveManager] Game started by", player and player.Name or "?")
	waveValue.Value = 1 timeValue.Value = 180
	clearToilets()

	task.spawn(function()
		while gameRunning and timeValue.Value > 0 do
			task.wait(1)
			timeValue.Value -= 1
		end
		if gameRunning and timeValue.Value <= 0 then
			gameRunning = false clearToilets()
			waveValue.Value = 1 timeValue.Value = 180
			for _, p in ipairs(Players:GetPlayers()) do p:LoadCharacter() end
		end
	end)

	task.spawn(function()
		while gameRunning do
			local waveIndex = waveValue.Value
			local waveData  = WAVES[waveIndex] or WAVES[#WAVES]
			print("[WaveManager] Wave", waveIndex)
			for i = 1, waveData.small do spawnToilet(smallToilet, randomSpawnCF()) task.wait(0.4) end
			for i = 1, waveData.big   do spawnToilet(bigToilet,   randomSpawnCF()) task.wait(0.6) end
			for i = 1, (waveData.gman or 0) do
				spawnToilet(gmanModel, randomSpawnCF())
				bossSpawned:FireAllClients()
				task.wait(0.8)
			end
			repeat task.wait(1) until countEnemies() == 0 or not gameRunning
			if not gameRunning then break end
			print("[WaveManager] Wave", waveIndex, "cleared!")
			task.wait(3)
			waveValue.Value = waveIndex + 1
			if waveValue.Value > #WAVES then waveValue.Value = #WAVES end
		end
	end)
end

gameStarted.OnServerEvent:Connect(function(player)
	print("[WaveManager] GameStarted from", player.Name)
	startGame(player)
end)

returnToLobby.OnServerEvent:Connect(function(player)
	gameRunning = false clearToilets()
	waveValue.Value = 1 timeValue.Value = 180
	player:LoadCharacter()
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid").Died:Connect(function()
			task.wait(2)
			gameRunning = false clearToilets()
			waveValue.Value = 1 timeValue.Value = 180
			player:LoadCharacter()
		end)
	end)
end)

print("[WaveManager] Ready")
