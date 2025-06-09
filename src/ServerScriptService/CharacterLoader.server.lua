local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Importar sistemas
local TetoTypes = require(ReplicatedStorage.TetoTypes)
local PlayerData = require(ReplicatedStorage.PlayerData)

-- Desactivar la carga automática de apariencia
StarterPlayer.LoadCharacterAppearance = false

-- Crear carpeta Models si no existe
if not ReplicatedStorage:FindFirstChild("Models") then
	local modelsFolder = Instance.new("Folder")
	modelsFolder.Name = "Models"
	modelsFolder.Parent = ReplicatedStorage
	print("Carpeta Models creada en ReplicatedStorage")
end

-- Tabla para rastrear jugadores que ya están siendo procesados
local playersBeingProcessed = {}

local function onPlayerAdded(player)
	local function onCharacterAdded(character)
		-- PREVENIR BUCLE INFINITO
		if playersBeingProcessed[player.UserId] then
			print("Ya procesando personaje para", player.Name, "- ignorando")
			return
		end

		playersBeingProcessed[player.UserId] = true

		wait(0.1)

		if not character.Parent then
			playersBeingProcessed[player.UserId] = false
			return
		end

		local humanoid = character:FindFirstChild("Humanoid")
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

		if not humanoid or not humanoidRootPart then
			playersBeingProcessed[player.UserId] = false
			return
		end

		-- Obtener la posición actual
		local currentPosition = humanoidRootPart.CFrame

		-- Obtener el tipo de Teto seleccionado por el jugador
		local selectedTetoType = PlayerData.getSelectedTeto(player)
		local tetoConfig = TetoTypes[selectedTetoType]

		if not tetoConfig then
			warn("Tipo de Teto no válido:", selectedTetoType)
			playersBeingProcessed[player.UserId] = false
			return
		end

		print("Cargando personaje:", tetoConfig.Name, "para:", player.Name)

		-- Verificar que el modelo existe
		local tetoModel = ReplicatedStorage.Models:FindFirstChild(tetoConfig.ModelName)
		if not tetoModel then
			warn("No se encontró el modelo", tetoConfig.ModelName, "en ReplicatedStorage.Models")
			warn("Usando personaje por defecto de Roblox...")

			-- Si no hay modelo personalizado, usar el personaje por defecto pero con stats personalizados
			local newHumanoid = humanoid
			local newRootPart = humanoidRootPart

			-- IMPORTANTE: Establecer el atributo TetoType ANTES de aplicar stats
			newHumanoid:SetAttribute("TetoType", selectedTetoType)
			print("Atributo TetoType establecido:", selectedTetoType)

			-- Aplicar stats del tipo de Teto
			newHumanoid.WalkSpeed = tetoConfig.Stats.WalkSpeed
			newHumanoid.MaxHealth = tetoConfig.Stats.MaxHealth
			newHumanoid.Health = tetoConfig.Stats.MaxHealth
			newHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

			-- Configurar atributos específicos del tipo
			for statName, statValue in pairs(tetoConfig.Stats) do
				newHumanoid:SetAttribute(statName, statValue)
			end

			-- Asegurar que el Animator existe
			if not newHumanoid:FindFirstChild("Animator") then
				local animator = Instance.new("Animator")
				animator.Parent = newHumanoid
			end

			print("Personaje por defecto configurado con stats de", tetoConfig.Name, "para:", player.Name)
			print("TetoType atributo verificado:", newHumanoid:GetAttribute("TetoType"))

			-- Liberar el lock
			spawn(function()
				wait(1)
				playersBeingProcessed[player.UserId] = false
				print("Procesamiento completado para:", player.Name)
			end)

			return
		end

		-- Clonar el modelo del Teto seleccionado
		local newTetoModel = tetoModel:Clone()
		newTetoModel.Name = player.Name

		-- Asegurar que el modelo tenga todos los componentes necesarios
		local newHumanoid = newTetoModel:FindFirstChild("Humanoid")
		local newRootPart = newTetoModel:FindFirstChild("HumanoidRootPart")

		if not newHumanoid or not newRootPart then
			warn("El modelo", tetoConfig.ModelName, "no tiene Humanoid o HumanoidRootPart")
			playersBeingProcessed[player.UserId] = false
			return
		end

		-- Posicionar el nuevo modelo
		newRootPart.CFrame = currentPosition

		-- IMPORTANTE: Establecer el atributo TetoType ANTES de aplicar stats
		newHumanoid:SetAttribute("TetoType", selectedTetoType)
		print("Atributo TetoType establecido:", selectedTetoType)

		-- Aplicar stats del tipo de Teto
		newHumanoid.WalkSpeed = tetoConfig.Stats.WalkSpeed
		newHumanoid.MaxHealth = tetoConfig.Stats.MaxHealth
		newHumanoid.Health = tetoConfig.Stats.MaxHealth
		newHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

		-- Configurar atributos específicos del tipo
		for statName, statValue in pairs(tetoConfig.Stats) do
			newHumanoid:SetAttribute(statName, statValue)
		end

		-- Asegurar que el Animator existe
		if not newHumanoid:FindFirstChild("Animator") then
			local animator = Instance.new("Animator")
			animator.Parent = newHumanoid
			print("Animator creado para", newTetoModel.Name)
		end

		-- NO TOCAR LOS JOINTS EXISTENTES - Los modelos ya vienen con la estructura correcta

		-- IMPORTANTE: Destruir el personaje anterior ANTES de asignar el nuevo
		local oldCharacter = character

		-- Asignar el nuevo personaje al jugador
		player.Character = newTetoModel
		newTetoModel.Parent = workspace

		-- Configurar la cámara para seguir al nuevo Humanoid
		if workspace.CurrentCamera then
			workspace.CurrentCamera.CameraSubject = newHumanoid
		end

		-- Destruir el personaje anterior inmediatamente
		if oldCharacter and oldCharacter.Parent and oldCharacter ~= newTetoModel then
			oldCharacter:Destroy()
		end

		print("Personaje", tetoConfig.Name, "cargado exitosamente para:", player.Name)
		print("TetoType atributo verificado:", newHumanoid:GetAttribute("TetoType"))

		-- Liberar el lock después de un pequeño delay
		spawn(function()
			wait(1) -- Esperar 1 segundo antes de permitir otro cambio
			playersBeingProcessed[player.UserId] = false
			print("Procesamiento completado para:", player.Name)
		end)
	end

	player.CharacterAdded:Connect(onCharacterAdded)

	-- Forzar la carga del personaje si no tiene uno
	if not player.Character then
		player:LoadCharacter()
	end
end

-- Limpiar datos cuando el jugador se va
Players.PlayerRemoving:Connect(function(player)
	playersBeingProcessed[player.UserId] = nil
end)

-- Manejar jugadores que ya están en el juego
for _, player in pairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)

print("CharacterLoader iniciado")