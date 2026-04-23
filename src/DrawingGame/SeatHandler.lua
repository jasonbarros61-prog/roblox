--[[
    SeatHandler — LocalScript
    Place in: StarterPlayerScripts/SeatHandler

    Watches for the local player sitting in any Seat that is tagged as a
    drawing seat (Name == "DrawingSeat"  OR  Attribute "IsDrawingSeat" = true).

    When the player sits, fires PlayerSat to the server so a game session begins.

    Workspace setup guide
    ──────────────────────────────────────────────────────────────────────────
    1. Create a Model named "DrawingTable_1" (or any unique name).
    2. Inside, add a Part for the table surface and two Seat parts facing each
       other. Name each Seat "DrawingSeat".
    3. Optionally set a string Attribute "Shape" on each Seat to lock it to a
       specific shape ("Circle", "Triangle", or "Pentagon"). Leave it unset to
       randomise each round.
    4. Duplicate the model for more tables (use different model names so each
       gets its own session).
--]]

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local Events    = ReplicatedStorage:WaitForChild("DrawingGameEvents")
local RE_Sat    = Events:WaitForChild("PlayerSat")

local function isDrawingSeat(obj)
    return obj:IsA("Seat")
        and (obj.Name == "DrawingSeat" or obj:GetAttribute("IsDrawingSeat") == true)
end

local function hookSeat(seat)
    seat:GetPropertyChangedSignal("Occupant"):Connect(function()
        local occ = seat.Occupant
        if not occ then return end
        local seated = Players:GetPlayerFromCharacter(occ.Parent)
        if seated ~= player then return end
        local shapeName = seat:GetAttribute("Shape") or nil
        RE_Sat:FireServer(seat, shapeName)
    end)
end

-- Scan existing seats
for _, obj in ipairs(workspace:GetDescendants()) do
    if isDrawingSeat(obj) then hookSeat(obj) end
end

-- Watch for seats added later (streamed content)
workspace.DescendantAdded:Connect(function(obj)
    if isDrawingSeat(obj) then hookSeat(obj) end
end)
