-- BigToiletScript: Script inside "big skibidi toilet" model in ServerStorage
local npc      = script.Parent
local humanoid = npc:WaitForChild("Humanoid")
local rootPart = npc:WaitForChild("HumanoidRootPart")

for _, part in ipairs(npc:GetDescendants()) do
	if part:IsA("BasePart") then part.Anchored = false end
end

humanoid.MaxHealth = 300
humanoid.Health    = 300
humanoid.WalkSpeed = 8

local DAMAGE          = 30
local ATTACK_RANGE    = 6
local ATTACK_COOLDOWN = 2.0
local TOKEN_REWARD    = 25

-- Flush ProximityPrompt
local head = npc:FindFirstChild("Head")
if head then
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Flush"
	prompt.ObjectText = "Big Skibidi Toilet"
	prompt.HoldDuration = 1.5
	prompt.MaxActivationDistance = 8
	prompt.Parent = head
	prompt.Triggered:Connect(function(player)
		local tv = player:FindFirstChild("Tokens")
		if tv then tv.Value += TOKEN_REWARD end
		humanoid.Health = 0
		task.delay(2, function()
			if npc and npc.Parent then npc:Destroy() end
		end)
	end)
end

local lastAttack = 0
local function attackNearest()
	local now = tick()
	if now - lastAttack < ATTACK_COOLDOWN then return end
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		local char  = player.Character if not char then continue end
		local cRoot = char:FindFirstChild("HumanoidRootPart")
		local cHum  = char:FindFirstChildOfClass("Humanoid")
		if not cRoot or not cHum or cHum.Health <= 0 then continue end
		if (rootPart.Position - cRoot.Position).Magnitude <= ATTACK_RANGE then
			lastAttack = now
			cHum:TakeDamage(DAMAGE)
			break
		end
	end
end

local function getNearestPlayer()
	local nearest, nearestDist = nil, math.huge
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		local char  = player.Character if not char then continue end
		local cRoot = char:FindFirstChild("HumanoidRootPart")
		local cHum  = char:FindFirstChildOfClass("Humanoid")
		if not cRoot or not cHum or cHum.Health <= 0 then continue end
		local dist = (rootPart.Position - cRoot.Position).Magnitude
		if dist < nearestDist then nearest, nearestDist = cRoot, dist end
	end
	return nearest, nearestDist
end

while humanoid.Health > 0 do
	local target, dist = getNearestPlayer()
	if target then
		humanoid:MoveTo(target.Position)
		if dist <= ATTACK_RANGE then attackNearest() end
	end
	task.wait(0.35)
end

task.wait(0.5)
if npc and npc.Parent then npc:Destroy() end
