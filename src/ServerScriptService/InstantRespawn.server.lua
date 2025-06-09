local respawnDelay = 0 -- You can change this but I said it to 0 to make no delay
 

 -- for the experts --


game.Players.CharacterAutoLoads = false
 
game.Players.PlayerAdded:connect(function(player)
	player.CharacterAdded:connect(function(character)
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Died:connect(function()
				wait(respawnDelay)
				player:LoadCharacter()
			end)
		end
	end)
	player:LoadCharacter() 
end)


-- TheSuabtomicalWorld