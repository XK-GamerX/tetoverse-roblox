-- ServerScriptService/RemoveDefaultAnims
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		local animate = char:FindFirstChild("Animate")
		if animate then
			animate:Destroy()
		end
	end)
end)
