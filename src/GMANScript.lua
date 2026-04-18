-- GMAN Boss Script: Script inside "GMAN" model in ServerStorage

local npc      = script.Parent
local humanoid = npc:WaitForChild("Humanoid")
local rootPart = npc:WaitForChild("HumanoidRootPart")
local head     = npc:FindFirstChild("Head")

-- Unanchor ALL parts so GMAN can actually move
for _, part in ipairs(npc:GetDescendants()) do
	if part:IsA("BasePart") then
		part.Anchored = false
	end
end

-- Stats
humanoid.MaxHealth  = 2500
humanoid.Health     = 2500
humanoid.WalkSpeed  = 5

local DAMAGE          = 50
local ATTACK_RANGE    = 7
local ATTACK_COOLDOWN = 2.5
local TOKEN_REWARD    = 300

-- Boss health bar BillboardGui (floats above GMAN)
local billboard = Instance.new("BillboardGui")
billboard.Size        = UDim2.new(0, 340, 0, 90)
billboard.StudsOffset = Vector3.new(0, 5, 0)
billboard.AlwaysOnTop = false
billboard.MaxDistance = 80
billboard.Parent      = rootPart

local outerGlow = Instance.new("Frame")
outerGlow.Size                   = UDim2.new(1, 6, 1, 6)
outerGlow.Position               = UDim2.new(0, -3, 0, -3)
outerGlow.BackgroundColor3       = Color3.fromRGB(0, 120, 255)
outerGlow.BackgroundTransparency = 0.5
outerGlow.BorderSizePixel        = 0
outerGlow.ZIndex                 = 1
outerGlow.Parent                 = billboard
Instance.new("UICorner", outerGlow).CornerRadius = UDim.new(0, 13)

local bg = Instance.new("Frame")
bg.Size             = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromRGB(5, 5, 20)
bg.BorderSizePixel  = 0
bg.ZIndex           = 2
bg.Parent           = billboard
Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 10)
local bgStroke = Instance.new("UIStroke", bg)
bgStroke.Color = Color3.fromRGB(0, 160, 255) bgStroke.Thickness = 2

local nameRow = Instance.new("Frame")
nameRow.Size = UDim2.new(1,-12,0,28) nameRow.Position = UDim2.new(0,6,0,5)
nameRow.BackgroundTransparency = 1 nameRow.ZIndex = 3 nameRow.Parent = bg

local skullLabel = Instance.new("TextLabel")
skullLabel.Size = UDim2.new(0,28,1,0) skullLabel.BackgroundTransparency = 1
skullLabel.Text = "☠" skullLabel.TextColor3 = Color3.fromRGB(255,40,40)
skullLabel.TextScaled = true skullLabel.Font = Enum.Font.GothamBold
skullLabel.ZIndex = 4 skullLabel.Parent = nameRow

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1,-36,1,0) nameLabel.Position = UDim2.new(0,34,0,0)
nameLabel.BackgroundTransparency = 1 nameLabel.Text = "G-MAN  ⚠ BOSS"
nameLabel.TextColor3 = Color3.fromRGB(0,200,255) nameLabel.TextScaled = true
nameLabel.Font = Enum.Font.GothamBold nameLabel.ZIndex = 4 nameLabel.Parent = nameRow

local barTrack = Instance.new("Frame")
barTrack.Size = UDim2.new(1,-12,0,18) barTrack.Position = UDim2.new(0,6,0,38)
barTrack.BackgroundColor3 = Color3.fromRGB(15,15,35) barTrack.BorderSizePixel = 0
barTrack.ZIndex = 3 barTrack.Parent = bg
Instance.new("UICorner", barTrack).CornerRadius = UDim.new(0,6)

local healthFill = Instance.new("Frame")
healthFill.Size = UDim2.new(1,0,1,0) healthFill.BackgroundColor3 = Color3.fromRGB(0,140,255)
healthFill.BorderSizePixel = 0 healthFill.ZIndex = 4 healthFill.Parent = barTrack
Instance.new("UICorner", healthFill).CornerRadius = UDim.new(0,6)

local shimmer = Instance.new("Frame")
shimmer.Size = UDim2.new(0.3,0,1,0) shimmer.BackgroundColor3 = Color3.new(1,1,1)
shimmer.BackgroundTransparency = 0.8 shimmer.BorderSizePixel = 0
shimmer.ZIndex = 5 shimmer.Parent = healthFill
Instance.new("UICorner", shimmer).CornerRadius = UDim.new(0,6)

local healthText = Instance.new("TextLabel")
healthText.Size = UDim2.new(1,0,0,18) healthText.Position = UDim2.new(0,0,0,60)
healthText.BackgroundTransparency = 1 healthText.Text = "2500 / 2500"
healthText.TextColor3 = Color3.fromRGB(180,220,255) healthText.TextScaled = true
healthText.Font = Enum.Font.Gotham healthText.ZIndex = 4 healthText.Parent = bg

humanoid.HealthChanged:Connect(function(health)
	local pct = math.clamp(health / humanoid.MaxHealth, 0, 1)
	healthFill.Size = UDim2.new(pct, 0, 1, 0)
	healthText.Text = math.ceil(health) .. " / " .. humanoid.MaxHealth
	if pct < 0.25 then
		healthFill.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
	elseif pct < 0.5 then
		healthFill.BackgroundColor3 = Color3.fromRGB(255, 160, 0)
	else
		healthFill.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
	end
end)

-- Yellow laser eyes
local LEFT_EYE_OFFSET  = CFrame.new(-0.22,  0.08, -0.52)
local RIGHT_EYE_OFFSET = CFrame.new( 0.22,  0.08, -0.52)
local LASER_RANGE           = 50
local LASER_DAMAGE          = 6
local LASER_DAMAGE_INTERVAL = 0.4

local function makeEyeGlow(offset)
	local glow = Instance.new("Part")
	glow.Name = "EyeGlow" glow.Size = Vector3.new(0.18,0.18,0.18)
	glow.Shape = Enum.PartType.Ball glow.Material = Enum.Material.Neon
	glow.Color = Color3.fromRGB(255,220,0) glow.CastShadow = false
	glow.CanCollide = false glow.Anchored = false
	glow.CFrame = head.CFrame * offset glow.Parent = npc
	local pl = Instance.new("PointLight")
	pl.Color = Color3.fromRGB(255,220,0) pl.Brightness = 4 pl.Range = 8 pl.Parent = glow
	local w = Instance.new("WeldConstraint")
	w.Part0 = head w.Part1 = glow w.Parent = glow
	return glow
end

local leftEyeGlow  = makeEyeGlow(LEFT_EYE_OFFSET)
local rightEyeGlow = makeEyeGlow(RIGHT_EYE_OFFSET)

local function makeTargetPart(eyePart)
	local t = Instance.new("Part")
	t.Size = Vector3.new(0.05,0.05,0.05) t.Anchored = true
	t.CanCollide = false t.Transparency = 1
	t.CFrame = eyePart.CFrame * CFrame.new(0,0,-LASER_RANGE)
	t.Parent = npc return t
end

local leftTarget  = makeTargetPart(leftEyeGlow)
local rightTarget = makeTargetPart(rightEyeGlow)

local function makeBeam(eyePart, targetPart)
	local srcA = Instance.new("Attachment") srcA.Parent = eyePart
	local tgtA = Instance.new("Attachment") tgtA.Parent = targetPart
	local beam = Instance.new("Beam")
	beam.Attachment0 = srcA beam.Attachment1 = tgtA
	beam.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255,240,50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255,160,0)),
	})
	beam.Width0 = 0.12 beam.Width1 = 0.04
	beam.LightEmission = 1 beam.LightInfluence = 0
	beam.FaceCamera = true beam.Segments = 1
	beam.Transparency = NumberSequence.new(0)
	beam.Parent = eyePart
end

makeBeam(leftEyeGlow, leftTarget)
makeBeam(rightEyeGlow, rightTarget)

local rayParams = RaycastParams.new()
rayParams.FilterDescendantsInstances = {npc}
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local lastLaserDmg = 0

task.spawn(function()
	while humanoid.Health > 0 do
		task.wait(0.06)
		if not head or not head.Parent then break end
		local lookDir = head.CFrame.LookVector
		local lPos = leftEyeGlow.CFrame.Position
		local lHit = workspace:Raycast(lPos, lookDir * LASER_RANGE, rayParams)
		leftTarget.CFrame = CFrame.new(lHit and lHit.Position or (lPos + lookDir * LASER_RANGE))
		local rPos = rightEyeGlow.CFrame.Position
		local rHit = workspace:Raycast(rPos, lookDir * LASER_RANGE, rayParams)
		rightTarget.CFrame = CFrame.new(rHit and rHit.Position or (rPos + lookDir * LASER_RANGE))
		local hit = lHit or rHit
		if hit then
			local char   = hit.Instance and hit.Instance:FindFirstAncestorOfClass("Model")
			local plrHum = char and char:FindFirstChildOfClass("Humanoid")
			local now = tick()
			if plrHum and plrHum.Health > 0 and (now - lastLaserDmg) >= LASER_DAMAGE_INTERVAL then
				lastLaserDmg = now
				plrHum:TakeDamage(LASER_DAMAGE)
			end
		end
	end
end)

-- Flush ProximityPrompt
if head then
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Flush GMAN" prompt.ObjectText = "☠ BOSS"
	prompt.HoldDuration = 1.5 prompt.MaxActivationDistance = 8
	prompt.Parent = head
	prompt.Triggered:Connect(function(player)
		local tv = player:FindFirstChild("Tokens")
		if tv then tv.Value += TOKEN_REWARD end
		humanoid.Health = 0
		task.delay(0.3, function()
			for _, part in ipairs(npc:GetDescendants()) do
				if part:IsA("BasePart") then part.Anchored = true end
			end
		end)
		task.delay(2, function()
			if npc and npc.Parent then npc:Destroy() end
		end)
	end)
end

-- Melee attack
local lastAttack = 0
local function attackNearest()
	local now = tick()
	if now - lastAttack < ATTACK_COOLDOWN then return end
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		local char = player.Character if not char then continue end
		local cRoot = char:FindFirstChild("HumanoidRootPart")
		local cHum  = char:FindFirstChildOfClass("Humanoid")
		if not cRoot or not cHum or cHum.Health <= 0 then continue end
		if (rootPart.Position - cRoot.Position).Magnitude <= ATTACK_RANGE then
			lastAttack = now cHum:TakeDamage(DAMAGE) break
		end
	end
end

local function getNearestPlayer()
	local nearest, nearestDist = nil, math.huge
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		local char = player.Character if not char then continue end
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
