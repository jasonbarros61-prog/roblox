-- GMAN NPC Script: Script inside "GMAN" model in ServerStorage
-- Slower than big toilet, tankier, hits hard, no animations yet

local npc       = script.Parent
local humanoid  = npc:WaitForChild("Humanoid")
local rootPart  = npc:WaitForChild("HumanoidRootPart")
local head      = npc:FindFirstChild("Head")

-- ── Stats ─────────────────────────────────────────────────────────────────────
humanoid.MaxHealth  = 250
humanoid.Health     = 250
humanoid.WalkSpeed  = 5    -- slower than big toilet (8)

local DAMAGE          = 40
local ATTACK_RANGE    = 6
local ATTACK_COOLDOWN = 2.5
local TOKEN_REWARD    = 150

-- ── ProximityPrompt on Head (flush mechanic) ──────────────────────────────────
if head then
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText    = "Flush"
	prompt.ObjectText    = "GMAN"
	prompt.HoldDuration  = 0.8    -- takes longer to flush than normal toilet
	prompt.MaxActivationDistance = 8
	prompt.Parent = head

	prompt.Triggered:Connect(function(player)
		local tokenValue = player:FindFirstChild("Tokens")
		if tokenValue then
			tokenValue.Value += TOKEN_REWARD
		end
		humanoid.Health = 0

		-- anchor all parts so it doesn't fall weirdly
		task.delay(0.3, function()
			for _, part in ipairs(npc:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = true
				end
			end
		end)

		task.delay(2, function()
			if npc and npc.Parent then
				npc:Destroy()
			end
		end)
	end)
end

-- ── Attack loop ───────────────────────────────────────────────────────────────
local lastAttack = 0

local function attackNearest()
	local now = tick()
	if now - lastAttack < ATTACK_COOLDOWN then return end

	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		local char = player.Character
		if not char then continue end
		local charRoot = char:FindFirstChild("HumanoidRootPart")
		local charHum  = char:FindFirstChildOfClass("Humanoid")
		if not charRoot or not charHum or charHum.Health <= 0 then continue end

		local dist = (rootPart.Position - charRoot.Position).Magnitude
		if dist <= ATTACK_RANGE then
			lastAttack = now
			charHum:TakeDamage(DAMAGE)
			break
		end
	end
end

-- ── Follow nearest player ─────────────────────────────────────────────────────
local function getNearestPlayer()
	local nearest, nearestDist = nil, math.huge
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		local char = player.Character
		if not char then continue end
		local charRoot = char:FindFirstChild("HumanoidRootPart")
		local charHum  = char:FindFirstChildOfClass("Humanoid")
		if not charRoot or not charHum or charHum.Health <= 0 then continue end

		local dist = (rootPart.Position - charRoot.Position).Magnitude
		if dist < nearestDist then
			nearest     = charRoot
			nearestDist = dist
		end
	end
	return nearest, nearestDist
end

-- main loop
while humanoid.Health > 0 do
	local target, dist = getNearestPlayer()
	if target then
		humanoid:MoveTo(target.Position)
		if dist <= ATTACK_RANGE then
			attackNearest()
		end
	end
	task.wait(0.3)
end

-- on death
task.wait(0.5)
if npc and npc.Parent then
	npc:Destroy()
end
