-- MorphHandler: Script in ServerScriptService
local ServerStorage  = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players        = game:GetService("Players")

-- Wait for RemoteEvents created by WaveManager
local buyMorph       = ReplicatedStorage:WaitForChild("BuyMorph",       10)
local equipMorph     = ReplicatedStorage:WaitForChild("EquipMorph",      10)
local morphConfirmed = ReplicatedStorage:WaitForChild("MorphConfirmed",  10)

if not buyMorph or not equipMorph or not morphConfirmed then
	warn("[MorphHandler] RemoteEvents not found — did WaveManager load first?")
	return
end

print("[MorphHandler] RemoteEvents found")

local morphCosts = {
	CameraMan = 500,
}

local function applyMorph(player, morphName)
	local char = player.Character
	if not char then
		warn("[MorphHandler] No character for", player.Name)
		return
	end

	local model = ServerStorage:FindFirstChild(morphName)
	if not model then
		warn("[MorphHandler] Morph model not found in ServerStorage:", morphName)
		return
	end

	local playerRoot = char:WaitForChild("HumanoidRootPart", 5)
	if not playerRoot then
		warn("[MorphHandler] HumanoidRootPart not found")
		return
	end

	-- Hide original character parts
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Transparency = 1
		elseif part:IsA("Decal") then
			part.Transparency = 1
		end
	end

	local morphRoot = model:FindFirstChild("HumanoidRootPart")
	if not morphRoot then
		warn("[MorphHandler] Morph has no HumanoidRootPart:", morphName)
		return
	end

	-- Remove old morph parts tagged with MorphPart
	for _, old in ipairs(char:GetChildren()) do
		if old:GetAttribute("MorphPart") then
			old:Destroy()
		end
	end

	-- Clone and weld morph parts
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			local offset   = morphRoot.CFrame:ToObjectSpace(part.CFrame)
			local newPart  = part:Clone()
			newPart.Anchored = false
			newPart.CanCollide = false
			newPart.CFrame = playerRoot.CFrame * offset
			newPart:SetAttribute("MorphPart", true)
			newPart.Parent = char

			local weld = Instance.new("WeldConstraint")
			weld.Part0 = playerRoot
			weld.Part1 = newPart
			weld.Parent = newPart
		end
	end

	print("[MorphHandler] Applied morph", morphName, "to", player.Name)
	morphConfirmed:FireClient(player, morphName)
end

-- ── Buy morph ─────────────────────────────────────────────────────────────────
buyMorph.OnServerEvent:Connect(function(player, morphName)
	print("[MorphHandler] BuyMorph request:", player.Name, morphName)
	local cost = morphCosts[morphName]
	if not cost then
		warn("[MorphHandler] Unknown morph:", morphName)
		return
	end

	local tokenValue = player:FindFirstChild("Tokens")
	if not tokenValue then
		warn("[MorphHandler] Player has no Tokens value:", player.Name)
		return
	end

	if tokenValue.Value < cost then
		print("[MorphHandler] Not enough tokens:", tokenValue.Value, "need", cost)
		return
	end

	tokenValue.Value -= cost
	applyMorph(player, morphName)
end)

-- ── Equip already-owned morph ─────────────────────────────────────────────────
equipMorph.OnServerEvent:Connect(function(player, morphName)
	print("[MorphHandler] EquipMorph request:", player.Name, morphName)
	applyMorph(player, morphName)
end)

print("[MorphHandler] Loaded")
