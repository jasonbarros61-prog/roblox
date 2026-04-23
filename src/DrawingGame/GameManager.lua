--[[
    GameManager — Script (server)
    Place in: ServerScriptService/GameManager

    Responsibilities:
    • Creates RemoteEvents under ReplicatedStorage/DrawingGameEvents
    • Manages per-table game sessions (up to 2 players per table)
    • Receives drawing accuracy from clients, awards coins, broadcasts results
    • Gives each player a Coins IntValue in their leaderstats (auto-creates if absent)

    Workspace setup required:
    • Any Seat with Name = "DrawingSeat"  OR  attribute IsDrawingSeat = true
    • Group seats into a Model named e.g. "DrawingTable_1", "DrawingTable_2", etc.
    • Seats in the same Model share a session; players race to see who scores higher
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ── Remote events ────────────────────────────────────────────────────────────
local eventsFolder = Instance.new("Folder")
eventsFolder.Name = "DrawingGameEvents"
eventsFolder.Parent = ReplicatedStorage

local function makeEvent(name)
    local e = Instance.new("RemoteEvent")
    e.Name = name
    e.Parent = eventsFolder
    return e
end

local RE_PlayerSat   = makeEvent("PlayerSat")    -- client → server: player sat down
local RE_StartGame   = makeEvent("StartGame")    -- server → client: begin drawing
local RE_Submit      = makeEvent("SubmitDrawing") -- client → server: accuracy score
local RE_ShowResult  = makeEvent("ShowResult")   -- server → client: result data

-- ── Shared modules ───────────────────────────────────────────────────────────
local ShapeData = require(ReplicatedStorage:WaitForChild("ShapeData"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- ── Leaderstats helpers ──────────────────────────────────────────────────────
local function ensureLeaderstats(player)
    local ls = player:FindFirstChild("leaderstats")
    if not ls then
        ls = Instance.new("Folder")
        ls.Name = "leaderstats"
        ls.Parent = player
    end
    local coins = ls:FindFirstChild("Coins")
    if not coins then
        coins = Instance.new("IntValue")
        coins.Name = "Coins"
        coins.Value = 0
        coins.Parent = ls
    end
    return coins
end

local function awardCoins(player, amount)
    if amount <= 0 then return end
    local coinsVal = ensureLeaderstats(player)
    coinsVal.Value = coinsVal.Value + amount
end

Players.PlayerAdded:Connect(ensureLeaderstats)
for _, p in ipairs(Players:GetPlayers()) do
    ensureLeaderstats(p)
end

-- ── Session state ────────────────────────────────────────────────────────────
-- sessions[tableId] = { shape, players={name,...}, results={name=acc}, startTime }
local sessions     = {}
local playerTable  = {}  -- playerName → tableId

local function tableIdFromSeat(seat)
    local parent = seat.Parent
    return (parent and parent ~= workspace) and parent.Name or seat.Name
end

local function newSession(tableId, shapeName)
    local names   = ShapeData.getShapeNames()
    local shape   = shapeName or names[math.random(1, #names)]
    sessions[tableId] = {
        shape     = shape,
        players   = {},
        results   = {},
        startTime = tick(),
        active    = true,
    }
    return sessions[tableId]
end

local function cleanupSession(tableId, delay)
    task.delay(delay or 12, function()
        local s = sessions[tableId]
        if not s then return end
        for _, pName in ipairs(s.players) do
            if playerTable[pName] == tableId then
                playerTable[pName] = nil
            end
        end
        sessions[tableId] = nil
    end)
end

-- ── PlayerSat: client tells server a player sat at a drawing seat ─────────────
RE_PlayerSat.OnServerEvent:Connect(function(player, seatPart, shapeName)
    if typeof(seatPart) ~= "Instance" then return end

    local tableId = tableIdFromSeat(seatPart)
    local session = sessions[tableId]

    if not session or not session.active then
        session = newSession(tableId, shapeName)
    end

    local pName = player.Name
    if not table.find(session.players, pName) then
        table.insert(session.players, pName)
    end
    playerTable[pName] = tableId

    RE_StartGame:FireClient(player, {
        shape     = session.shape,
        timeLimit = GameConfig.DRAW_TIME,
    })
end)

-- ── SubmitDrawing: client sends accuracy after drawing ────────────────────────
RE_Submit.OnServerEvent:Connect(function(player, accuracy)
    if type(accuracy) ~= "number" then return end
    accuracy = math.clamp(math.floor(accuracy), 0, 100)

    local tableId = playerTable[player.Name]
    if not tableId then return end

    local session = sessions[tableId]
    if not session or not session.active then return end

    -- Prevent double-submit
    if session.results[player.Name] then return end
    session.results[player.Name] = accuracy

    -- Coin calculation
    local fullCoins = ShapeData.getCoins(session.shape)
    local awarded   = 0

    if accuracy >= GameConfig.WIN_THRESHOLD then
        awarded = fullCoins
    elseif accuracy >= GameConfig.MIN_ACCURACY then
        -- Proportional: maps MIN→WIN range to 10%→100% of coins
        local range = GameConfig.WIN_THRESHOLD - GameConfig.MIN_ACCURACY
        local t     = (accuracy - GameConfig.MIN_ACCURACY) / range
        awarded = math.floor(fullCoins * (0.1 + 0.9 * t))
    end

    awardCoins(player, awarded)

    RE_ShowResult:FireClient(player, {
        accuracy     = accuracy,
        shape        = session.shape,
        coinsAwarded = awarded,
        fullCoins    = fullCoins,
    })

    -- Check if all players have submitted
    local allDone = true
    for _, pName in ipairs(session.players) do
        if not session.results[pName] then
            allDone = false
            break
        end
    end

    if allDone then
        session.active = false
        cleanupSession(tableId, 12)
    end
end)

-- ── Cleanup on player leave ───────────────────────────────────────────────────
Players.PlayerRemoving:Connect(function(player)
    local tableId = playerTable[player.Name]
    if not tableId then return end

    local session = sessions[tableId]
    if session then
        local idx = table.find(session.players, player.Name)
        if idx then table.remove(session.players, idx) end
        session.results[player.Name] = nil
        if #session.players == 0 then
            session.active = false
            cleanupSession(tableId, 0)
        end
    end
    playerTable[player.Name] = nil
end)
