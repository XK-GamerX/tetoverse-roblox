-- Manejador del cambio de personajes en el servidor
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Importar sistemas
local TetoTypes = require(ReplicatedStorage.TetoTypes)
local PlayerData = require(ReplicatedStorage.PlayerData)

-- Crear RemoteEvent si no existe
local changeCharacterEvent = ReplicatedStorage:FindFirstChild("ChangeCharacterEvent")
if not changeCharacterEvent then
	changeCharacterEvent = Instance.new("RemoteEvent")
	changeCharacterEvent.Name = "ChangeCharacterEvent"
	changeCharacterEvent.Parent = ReplicatedStorage
end

-- Tabla para prevenir spam de cambios
local changeCooldowns = {}

-- Función para cambiar el personaje del jugador
local function changePlayerCharacter(player, tetoType)
	-- Verificar cooldown (prevenir spam)
	if changeCooldowns[player.UserId] and tick() - changeCooldowns[player.UserId] < 2 then
		print("Cambio de personaje en cooldown para:", player.Name)
		return
	end

	-- Verificar que el tipo de Teto existe
	if not TetoTypes[tetoType] then
		warn("Tipo de Teto no válido:", tetoType)
		return
	end

	-- Actualizar los datos del jugador
	local success = PlayerData.setSelectedTeto(player, tetoType)
	if not success then
		warn("El jugador no posee este tipo de Teto:", tetoType)
		-- Por ahora, permitir cambio a cualquier Teto (para testing)
		PlayerData.addTeto(player, tetoType)
		PlayerData.setSelectedTeto(player, tetoType)
		print("Teto agregado automáticamente para testing:", tetoType)
	end

	print("Cambiando personaje de", player.Name, "a", TetoTypes[tetoType].Name)

	-- Establecer cooldown
	changeCooldowns[player.UserId] = tick()

	-- Respawnear al jugador para aplicar el cambio
	spawn(function()
		wait(0.1) -- Pequeño delay para evitar problemas
		if player.Character then
			player.Character.Humanoid.Health = 0
		else
			player:LoadCharacter()
		end
	end)
end

-- Limpiar cooldowns cuando el jugador se va
Players.PlayerRemoving:Connect(function(player)
	changeCooldowns[player.UserId] = nil
end)

-- Conectar el evento
changeCharacterEvent.OnServerEvent:Connect(changePlayerCharacter)

print("Manejador de cambio de personajes iniciado")