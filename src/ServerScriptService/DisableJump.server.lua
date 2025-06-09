local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")

		-- Desactiva por completo la habilidad de saltar
		humanoid.JumpPower = 0
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)

		-- Si intenta saltar con tecla, anularlo
		humanoid:GetPropertyChangedSignal("Jump"):Connect(function()
			if humanoid.Jump then
				humanoid.Jump = false
			end
		end)
	end)
end)
