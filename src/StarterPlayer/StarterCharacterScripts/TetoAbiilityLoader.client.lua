-- Script que carga las habilidades específicas según el tipo de Teto
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Importar sistemas
local TetoTypes = require(ReplicatedStorage.TetoTypes)

local function setupCharacterAbilities()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")

	-- Esperar a que el atributo TetoType esté disponible (con timeout)
	local tetoType = nil
	local attempts = 0
	local maxAttempts = 50 -- 5 segundos máximo

	while not tetoType and attempts < maxAttempts do
		tetoType = humanoid:GetAttribute("TetoType")
		if not tetoType then
			wait(0.1)
			attempts = attempts + 1
		end
	end

	if not tetoType then
		warn("No se pudo obtener el tipo de Teto después de 5 segundos, usando Default")
		tetoType = "Default"
	end

	local tetoConfig = TetoTypes[tetoType]
	if not tetoConfig then
		warn("Configuración de Teto no válida:", tetoType, "- usando Default")
		tetoType = "Default"
		tetoConfig = TetoTypes["Default"]
	end

	print("Cargando habilidades para:", tetoConfig.Name, "- Tipo:", tetoType)

	-- Cargar el script de habilidades específico
	local abilityScript = script.Parent:FindFirstChild(tetoConfig.ScriptName)
	if abilityScript then
		-- Verificar que el script no esté ya ejecutándose
		local existingScript = character:FindFirstChild(tetoConfig.ScriptName)
		if existingScript then
			print("Script de habilidades ya existe, removiendo el anterior")
			existingScript:Destroy()
			wait(0.1)
		end

		-- Clonar y ejecutar el script de habilidades
		local clonedScript = abilityScript:Clone()
		clonedScript.Parent = character
		clonedScript.Disabled = false
		print("Script de habilidades cargado:", tetoConfig.ScriptName)

		-- Esperar un poco para que el script se inicialice
		wait(0.2)

	else
		warn("No se encontró el script de habilidades:", tetoConfig.ScriptName)

		-- Intentar cargar script por defecto si no se encuentra el específico
		local defaultScript = script.Parent:FindFirstChild("TetoDefaultAbilities")
		if defaultScript and tetoType ~= "Default" then
			warn("Cargando habilidades por defecto como fallback")

			-- Verificar que el script por defecto no esté ya ejecutándose
			local existingDefaultScript = character:FindFirstChild("TetoDefaultAbilities")
			if existingDefaultScript then
				existingDefaultScript:Destroy()
				wait(0.1)
			end

			local clonedScript = defaultScript:Clone()
			clonedScript.Parent = character
			clonedScript.Disabled = false
		end
	end
end

-- Configurar cuando el personaje carga por primera vez
if player.Character then
	spawn(function()
		setupCharacterAbilities()
	end)
end

-- Reconfigurar cada vez que el personaje respawnea
player.CharacterAdded:Connect(function()
	spawn(function()
		setupCharacterAbilities()
	end)
end)