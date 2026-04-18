-- WaveManager: Script in ServerScriptService
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- ── RemoteEvents ────────────────────────────────────────────────────────────
local function makeEvent(name)
	local e = ReplicatedStorage:FindFirstChild(name)
	if not e then
		e = Instance.new("RemoteEvent")
		e.Name = name
		e.Parent = ReplicatedStorage
	end
	return e
end

local gameStarted     = makeEvent("GameStarted")
local buyMorph        = makeEvent("BuyMorph")
local equipMorph      = makeEvent("EquipMorph")
local morphConfirmed  = makeEvent("MorphConfirmed")
local returnToLobby   = makeEvent("ReturnToLobby")

print("[WaveManager] RemoteEvents created")

-- ── GameData ─────────────────────────────────────────────────────────────────
local gameData = ReplicatedStorage:FindFirstChild("GameData")
if not gameData then
	gameData = Instance.new("Folder")
	gameData.Name = "GameData"
	gameData.Parent = ReplicatedStorage
end

local waveValue = gameData:FindFirstChild("Wave")
if not waveValue then
	waveValue = Instance.new("NumberValue")
	waveValue.Name = "Wave"
	waveValue.Value = 1
	waveValue.Parent = gameData
end

local timeValue = gameData:FindFirstChild("TimeLeft")
if not timeValue then
	timeValue = Instance.new("NumberValue")
	timeValue.Name = "TimeLeft"
	timeValue.Value = 180
	timeValue.Parent = gameData
end

print("[WaveManager] GameData folder ready")

-- ── Token system ──────────────────────────────────────────────────────────────
local playerTokens = {}

Players.PlayerAdded:Connect(function(player)
	playerTokens[player] = 0
	local tv = Instance.new("NumberValue")
	tv.Name = "Tokens"
	tv.Value = 0
	tv.Parent = player
	print("[WaveManager] Tokens created for", player.Name)
end)

Players.PlayerRemoving:Connect(function(player)
	playerTokens[player] = nil
end)

-- ── Models ────────────────────────────────────────────────────────────────────
-- IMPORTANT: these names must EXACTLY match what's in ServerStorage
local SMALL_NAME = "skibidi toilet"
local BIG_NAME   = "big skibidi toilet"
local GMAN_NAME  = "GMAN"

local smallToilet = ServerStorage:FindFirstChild(SMALL_NAME)
local bigToilet   = ServerStorage:FindFirstChild(BIG_NAME)
local gmanModel   = ServerStorage:FindFirstChild(GMAN_NAME)

if smallToilet then
	print("[WaveManager] Found model:", SMALL_NAME)
else
	warn("[WaveManager] MISSING MODEL in ServerStorage:", SMALL_NAME)
end

if bigToilet then
	print("[WaveManager] Found model:", BIG_NAME)
else
	warn("[WaveManager] MISSING MODEL in ServerStorage:", BIG_NAME)
end

if gmanModel then
	print("[WaveManager] Found model:", GMAN_NAME)
else
	warn("[WaveManager] MISSING MODEL in ServerStorage:", GMAN_NAME)
end

-- ── Spawn config ──────────────────────────────────────────────────────────────
-- Spread toilets around the map instead of one fixed point
-- Adjust these to match your actual map layout
local SPAWN_RADIUS = 40   -- studs from centre
local SPAWN_HEIGHT = 5    -- studs above ground

local function randomSpawnCF()
	local angle = math.random() * 2 * math.pi
	local r     = SPAWN_RADIUS * (0.5 + math.random() * 0.5)
	local x = math.cos(angle) * r
	local z = math.sin(angle) * r
	return CFrame.new(x, SPAWN_HEIGHT, z)
end

-- ── Wave config ───────────────────────────────────────────────────────────────
-- gman = number of GMAN enemies to spawn that wave
local WAVES = {
	{small = 4, big = 0, gman = 0},
	{small = 5, big = 1, gman = 0},
	{small = 6, big = 2, gman = 0},
	{small = 7, big = 3, gman = 1},
	{small = 8, big = 4, gman = 1},
	{small = 8, big = 4, gman = 2},
}

local activeToilets = {}
local gameRunning   = false

local function clearToilets()
	for _, npc in ipairs(activeToilets) do
		if npc and npc.Parent then
			npc:Destroy()
		end
	end
	activeToilets = {}
end

local function spawnToilet(template, spawnCF)
	if not template then
		warn("[WaveManager] Cannot spawn — template is nil")
		return
	end
	local npc = template:Clone()
	npc.Parent = workspace
	-- Move every BasePart so the model lands at spawnCF
	local root = npc:FindFirstChild("HumanoidRootPart")
		or npc:FindFirstChildWhichIsA("BasePart")
	if root then
		npc:PivotTo(spawnCF)
		print("[WaveManager] Spawned", npc.Name, "at", spawnCF.Position)
	else
		warn("[WaveManager] Model has no BasePart to pivot:", npc.Name)
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

-- ── Main game loop ────────────────────────────────────────────────────────────
local function startGame(player)
	if gameRunning then
		print("[WaveManager] startGame called but already running — ignoring")
		return
	end
	gameRunning = true
	print("[WaveManager] startGame() fired by", player and player.Name or "?")

	-- reset values
	waveValue.Value = 1
	timeValue.Value = 180
	clearToilets()

	-- timer (runs in background)
	task.spawn(function()
		while gameRunning and timeValue.Value > 0 do
			task.wait(1)
			timeValue.Value = timeValue.Value - 1
		end
		if gameRunning and timeValue.Value <= 0 then
			print("[WaveManager] Time ran out — resetting game")
			gameRunning = false
			clearToilets()
			waveValue.Value = 1
			timeValue.Value = 180
			-- reload each player's character
			for _, p in ipairs(Players:GetPlayers()) do
				p:LoadCharacter()
			end
		end
	end)

	-- wave loop
	task.spawn(function()
		while gameRunning do
			local waveIndex = waveValue.Value
			local waveData  = WAVES[waveIndex] or WAVES[#WAVES]
			print("[WaveManager] Starting wave", waveIndex,
				"| small:", waveData.small, "| big:", waveData.big)

			-- spawn small toilets
			for i = 1, waveData.small do
				spawnToilet(smallToilet, randomSpawnCF())
				task.wait(0.4)
			end
			-- spawn big toilets
			for i = 1, waveData.big do
				spawnToilet(bigToilet, randomSpawnCF())
				task.wait(0.6)
			end
			-- spawn GMAN enemies
			for i = 1, (waveData.gman or 0) do
				spawnToilet(gmanModel, randomSpawnCF())
				task.wait(0.8)
			end

			-- wait until all enemies dead
			repeat
				task.wait(1)
			until countEnemies() == 0 or not gameRunning

			if not gameRunning then break end

			print("[WaveManager] Wave", waveIndex, "cleared!")
			task.wait(3) -- brief pause between waves
			waveValue.Value = waveIndex + 1
			if waveValue.Value > #WAVES then
				waveValue.Value = #WAVES -- loop on last wave config
			end
		end
	end)
end

-- ── Event listeners ───────────────────────────────────────────────────────────
gameStarted.OnServerEvent:Connect(function(player)
	print("[WaveManager] GameStarted event received from", player.Name)
	startGame(player)
end)

returnToLobby.OnServerEvent:Connect(function(player)
	print("[WaveManager] ReturnToLobby received from", player.Name)
	gameRunning = false
	clearToilets()
	waveValue.Value = 1
	timeValue.Value = 180
	player:LoadCharacter()
end)

-- ── Death reset ───────────────────────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			print("[WaveManager]", player.Name, "died — resetting")
			task.wait(2)
			gameRunning = false
			clearToilets()
			waveValue.Value = 1
			timeValue.Value = 180
			player:LoadCharacter()
		end)
	end)
end)

print("[WaveManager] Loaded and waiting for GameStarted event")
