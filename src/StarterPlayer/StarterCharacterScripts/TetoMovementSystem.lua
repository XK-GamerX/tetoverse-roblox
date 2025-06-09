-- Sistema de movimiento compartido para todas las Tetos
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Sistema de movimiento compartido para todas las Tetos
local TetoMovementSystem = {}

function TetoMovementSystem.setup(character, stats)
	local humanoid = character:WaitForChild("Humanoid")
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

	-- Esperar a que el Animator esté disponible
	local animator = humanoid:WaitForChild("Animator")

	-- Esperar un poco para que el Animator se inicialice completamente
	wait(0.5)

	-- Variables de estado del movimiento
	local isRunning = false
	local shiftLockEnabled = false
	local currentStamina = stats.MaxStamina

	-- Variables de velocidad (para poder actualizarlas con buffs)
	local baseWalkSpeed = stats.WalkSpeed
	local baseRunSpeed = stats.RunSpeed
	local speedMultiplier = 1.0 -- Multiplicador para buffs

	-- Variables para el estado de comer
	local isEating = false
	local eatSpeedMultiplier = 1.0

	-- Variables para animaciones
	local currentAnimationTrack = nil
	local lastMoveVector = Vector3.new()
	local lastAnimationType = nil -- Para detectar cambios de animación

	-- Variables para FOV
	local camera = workspace.CurrentCamera
	local originalFOV = camera.FieldOfView
	local runningFOV = originalFOV + 10

	-- Cargar animaciones de movimiento (compartidas por todas las Tetos)
	local animationIds = {
		Idle = "rbxassetid://92676978575682",
		Walk = "rbxassetid://126517701186016",
		Run = "rbxassetid://107086533359164",
		InjuredIdle = "rbxassetid://115135489106558",
		InjuredWalk = "rbxassetid://126197137923915",
		InjuredRun = "rbxassetid://137935776302445"
	}

	local animations = {}
	local animationsLoaded = false

	-- Función para cargar animaciones de forma segura
	local function loadAnimations()
		print("Intentando cargar animaciones para", character.Name)

		-- Verificar que el Animator esté disponible
		if not animator or not animator.Parent then
			warn("Animator no disponible para", character.Name)
			return false
		end

		local loadedCount = 0
		local totalAnimations = 0

		-- Contar total de animaciones
		for _ in pairs(animationIds) do
			totalAnimations = totalAnimations + 1
		end

		for name, id in pairs(animationIds) do
			local success, result = pcall(function()
				local anim = Instance.new("Animation")
				anim.AnimationId = id
				local track = animator:LoadAnimation(anim)
				track.Priority = Enum.AnimationPriority.Core
				return track
			end)

			if success then
				animations[name] = result
				loadedCount = loadedCount + 1
				print("Animación", name, "cargada exitosamente")
			else
				warn("Error cargando animación", name, ":", result)
			end
		end

		print("Se cargaron", loadedCount, "de", totalAnimations, "animaciones")

		if loadedCount == totalAnimations then
			animationsLoaded = true
			print("✅ Todas las animaciones cargadas exitosamente para", character.Name)
			return true
		else
			warn("❌ Solo se cargaron", loadedCount, "de", totalAnimations, "animaciones")
			return false
		end
	end

	-- Intentar cargar animaciones con reintentos
	spawn(function()
		local attempts = 0
		local maxAttempts = 3 -- Reducir intentos

		while not animationsLoaded and attempts < maxAttempts do
			attempts = attempts + 1
			print("🔄 Intento", attempts, "de cargar animaciones")

			if loadAnimations() then
				break
			end

			wait(1) -- Esperar 1 segundo antes del siguiente intento
		end

		if not animationsLoaded then
			warn("❌ No se pudieron cargar las animaciones después de", maxAttempts, "intentos")
			warn("🔧 Usando animaciones por defecto de Roblox")
		end
	end)

	-- Función para calcular velocidades actuales con buffs y estados
	local function getCurrentSpeeds()
		local finalMultiplier = speedMultiplier

		-- Si está comiendo, aplicar también la lentitud
		if isEating then
			finalMultiplier = finalMultiplier * eatSpeedMultiplier
		end

		return {
			walkSpeed = baseWalkSpeed * finalMultiplier,
			runSpeed = baseRunSpeed * finalMultiplier
		}
	end

	-- Función para actualizar la velocidad del humanoid
	local function updateHumanoidSpeed()
		local speeds = getCurrentSpeeds()
		if isRunning and not isEating then -- No puede correr mientras come
			humanoid.WalkSpeed = speeds.runSpeed
		else
			humanoid.WalkSpeed = speeds.walkSpeed
		end
	end

	-- Sistema de stamina
	local staminaConnection
	staminaConnection = RunService.Heartbeat:Connect(function(deltaTime)
		if not character.Parent then
			staminaConnection:Disconnect()
			return
		end

		if isRunning and humanoid.MoveDirection.Magnitude > 0 and not isEating then
			-- Consumir stamina al correr (no puede correr mientras come)
			currentStamina = math.max(0, currentStamina - stats.StaminaRunCost * deltaTime)
			if currentStamina <= 0 then
				isRunning = false
				updateHumanoidSpeed()
				-- Restaurar FOV
				local fovTween = TweenService:Create(
					camera,
					TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{FieldOfView = originalFOV}
				)
				fovTween:Play()
			end
		else
			-- Regenerar stamina
			currentStamina = math.min(stats.MaxStamina, currentStamina + stats.StaminaRegenRate * deltaTime)
		end

		humanoid:SetAttribute("Stamina", currentStamina)
	end)

	-- Función para hacer transición suave entre animaciones
	local function playAnimationWithTransition(targetAnimation, animationType)
		-- Solo usar animaciones personalizadas si están cargadas
		if not animationsLoaded or not targetAnimation then
			-- Si no hay animaciones personalizadas, dejar que Roblox use las por defecto
			return
		end

		if targetAnimation == currentAnimationTrack then
			return
		end

		-- Si hay una animación actual y es diferente tipo, hacer transición
		if currentAnimationTrack and lastAnimationType ~= animationType then
			-- Detener la animación anterior suavemente
			local success, error = pcall(function()
				currentAnimationTrack:Stop(0.2) -- Fade out de 0.2 segundos
			end)
			if not success then
				warn("Error deteniendo animación:", error)
			end

			-- Esperar un frame antes de iniciar la nueva
			wait()

			-- Iniciar la nueva animación
			currentAnimationTrack = targetAnimation
			local success2, error2 = pcall(function()
				currentAnimationTrack:Play(0.2) -- Fade in de 0.2 segundos
			end)
			if not success2 then
				warn("Error reproduciendo animación:", error2)
			end
		elseif not currentAnimationTrack then
			-- Si no hay animación previa, simplemente reproducir
			currentAnimationTrack = targetAnimation
			local success, error = pcall(function()
				currentAnimationTrack:Play()
			end)
			if not success then
				warn("Error reproduciendo animación inicial:", error)
			end
		else
			-- Si es el mismo tipo de animación, cambiar directamente
			if currentAnimationTrack then
				local success, error = pcall(function()
					currentAnimationTrack:Stop()
				end)
				if not success then
					warn("Error deteniendo animación actual:", error)
				end
			end
			currentAnimationTrack = targetAnimation
			local success2, error2 = pcall(function()
				currentAnimationTrack:Play()
			end)
			if not success2 then
				warn("Error reproduciendo nueva animación:", error2)
			end
		end

		lastAnimationType = animationType
	end

	-- Sistema de animaciones
	local animationConnection
	animationConnection = RunService.Heartbeat:Connect(function()
		if not character.Parent then
			animationConnection:Disconnect()
			return
		end

		-- Solo procesar animaciones personalizadas si están cargadas
		if not animationsLoaded then
			-- Dejar que Roblox maneje las animaciones por defecto
			return
		end

		-- Verificar si hay habilidades activas (usando atributos)
		local isDancing = humanoid:GetAttribute("IsDancing") or false
		local isEatingAbility = humanoid:GetAttribute("IsEating") or false

		-- Solo detener animaciones de movimiento si está bailando
		if isDancing then
			return
		end

		local moveVector = humanoid.MoveDirection
		local isMoving = moveVector.Magnitude > 0.1
		local isInjured = humanoid.Health < humanoid.MaxHealth * 0.3

		local targetAnimation = nil
		local animationType = nil

		if isMoving then
			if isRunning and not isEating then -- No puede correr mientras come
				targetAnimation = isInjured and animations.InjuredRun or animations.Run
				animationType = "run"
			else
				targetAnimation = isInjured and animations.InjuredWalk or animations.Walk
				animationType = "walk"
			end
		else
			targetAnimation = isInjured and animations.InjuredIdle or animations.Idle
			animationType = "idle"
		end

		-- Usar la nueva función de transición suave
		if targetAnimation then
			playAnimationWithTransition(targetAnimation, animationType)
		end

		lastMoveVector = moveVector
	end)

	-- Detectar entrada de teclas para movimiento
	local function onInputBegan(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.LeftShift then
			local isDancing = humanoid:GetAttribute("IsDancing") or false

			-- No puede correr si está comiendo, bailando, o sin stamina
			if currentStamina > 0 and not isDancing and not isEating then
				isRunning = true
				updateHumanoidSpeed()
				-- Cambiar FOV al correr
				local fovTween = TweenService:Create(
					camera,
					TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{FieldOfView = runningFOV}
				)
				fovTween:Play()
			end
		elseif input.KeyCode == Enum.KeyCode.LeftControl then
			shiftLockEnabled = not shiftLockEnabled
			-- El script CtrlShiftLock en StarterPlayerScripts maneja el MouseBehavior
		end
	end

	local function onInputEnded(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.LeftShift then
			isRunning = false
			local isDancing = humanoid:GetAttribute("IsDancing") or false

			-- Solo cambiar velocidad si no está bailando
			if not isDancing then
				updateHumanoidSpeed()
			end
			-- Restaurar FOV
			local fovTween = TweenService:Create(
				camera,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{FieldOfView = originalFOV}
			)
			fovTween:Play()
		end
	end

	-- Conectar eventos de input
	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.InputEnded:Connect(onInputEnded)

	-- Retornar funciones útiles para las habilidades
	return {
		stopCurrentAnimation = function()
			if currentAnimationTrack then
				local success, error = pcall(function()
					currentAnimationTrack:Stop()
				end)
				if not success then
					warn("Error deteniendo animación:", error)
				end
				currentAnimationTrack = nil
			end
		end,
		getCurrentStamina = function()
			return currentStamina
		end,
		setCurrentStamina = function(value)
			currentStamina = value
		end,
		getShiftLockEnabled = function()
			return shiftLockEnabled
		end,
		getIsRunning = function()
			return isRunning
		end,
		-- Nueva función mejorada para actualizar velocidades (para buffs)
		updateSpeeds = function(newWalkSpeed, newRunSpeed)
			baseWalkSpeed = newWalkSpeed
			baseRunSpeed = newRunSpeed
			updateHumanoidSpeed() -- Aplicar inmediatamente
		end,
		-- Nueva función para aplicar multiplicadores de velocidad (buffs)
		setSpeedMultiplier = function(multiplier)
			speedMultiplier = multiplier
			updateHumanoidSpeed() -- Aplicar inmediatamente
		end,
		-- Función para obtener el multiplicador actual
		getSpeedMultiplier = function()
			return speedMultiplier
		end,
		-- Nueva función para manejar el estado de comer
		setEatingState = function(eating, slowMultiplier)
			isEating = eating
			eatSpeedMultiplier = slowMultiplier or 1.0
			updateHumanoidSpeed() -- Aplicar inmediatamente
		end,
		-- Función para verificar si las animaciones están cargadas
		areAnimationsLoaded = function()
			return animationsLoaded
		end
	}
end

return TetoMovementSystem