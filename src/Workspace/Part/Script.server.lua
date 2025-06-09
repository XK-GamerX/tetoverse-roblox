local DAMAGE = 5
local COOLDOWN = 2

local parentPart = script.Parent

local recentlyDamagedCharacters = {}

local function onTouch(otherPart)
	
	local character = otherPart.Parent
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	local player = game:GetService("Players"):GetPlayerFromCharacter(character)
	
	if player and humanoid and not recentlyDamagedCharacters[character] then
		humanoid:TakeDamage(DAMAGE)
		recentlyDamagedCharacters[character] = true
		wait(COOLDOWN_IN_SECONDS)
		recentlyDamagedCharacters[character] = nil
	end
end

parentPart.Touched:Connect(onTouch)