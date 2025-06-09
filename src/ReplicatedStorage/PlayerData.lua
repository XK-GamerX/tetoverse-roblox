-- Sistema para manejar datos del jugador (qué Teto tiene seleccionado)
local PlayerData = {}

-- Datos por defecto para cada jugador
local defaultData = {
	selectedTeto = "Default", -- Teto seleccionado actualmente
	ownedTetos = {"Default"}, -- Tetos que posee el jugador
	coins = 0 -- Para la futura tienda
}

-- Almacén temporal de datos (en el futuro será una base de datos)
local playerDataStore = {}

function PlayerData.getPlayerData(player)
	if not playerDataStore[player.UserId] then
		-- Crear datos por defecto para el jugador
		playerDataStore[player.UserId] = {}
		for key, value in pairs(defaultData) do
			playerDataStore[player.UserId][key] = value
		end
	end
	return playerDataStore[player.UserId]
end

function PlayerData.setSelectedTeto(player, tetoType)
	local data = PlayerData.getPlayerData(player)

	-- Verificar que el jugador posee este Teto
	for _, ownedTeto in pairs(data.ownedTetos) do
		if ownedTeto == tetoType then
			data.selectedTeto = tetoType
			return true
		end
	end

	return false -- No posee este Teto
end

function PlayerData.getSelectedTeto(player)
	local data = PlayerData.getPlayerData(player)
	return data.selectedTeto
end

function PlayerData.addTeto(player, tetoType)
	local data = PlayerData.getPlayerData(player)

	-- Verificar que no lo tenga ya
	for _, ownedTeto in pairs(data.ownedTetos) do
		if ownedTeto == tetoType then
			return false -- Ya lo tiene
		end
	end

	table.insert(data.ownedTetos, tetoType)
	return true
end

function PlayerData.getOwnedTetos(player)
	local data = PlayerData.getPlayerData(player)
	return data.ownedTetos
end

-- Limpiar datos cuando el jugador se va
game.Players.PlayerRemoving:Connect(function(player)
	playerDataStore[player.UserId] = nil
end)

return PlayerData