local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Importar el sistema de movimiento compartido
local TetoMovementSystem = require(script.Parent.TetoMovementSystem)

local player = Players.LocalPlayer

-- Función para configurar las habilidades cuando el personaje carga
local function setupCharacter()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

	-- Esperar a que el Animator esté disponible
	local animator = humanoid:WaitForChild("Animator")

	-- Stats del personaje (específicos de Teto Default)
	local stats = {
		WalkSpeed = 12,
		RunSpeed = 24,
		MaxHealth = 100,
		MaxStamina = 100,
		StaminaRegenRate = 10, -- stamina por segundo
		StaminaRunCost = 15, -- stamina por segundo corriendo
		DanceCooldown = 30,
		EatCooldown = 40,
		DanceDuration = 5,
		EatCastTime = 3,
		DanceSpeedBuff = 0.2, -- 20% de velocidad extra
		DanceBuffDuration = 4, -- 4 segundos de buff
		EatSlowness = 0.3, -- 30% de lentitud al comer
	}

	-- Aplicar stats básicos
	humanoid.WalkSpeed = stats.WalkSpeed
	humanoid.MaxHealth = stats.MaxHealth
	humanoid.Health = stats.MaxHealth

	-- Configurar atributos de stamina
	humanoid:SetAttribute("MaxStamina", stats.MaxStamina)
	humanoid:SetAttribute("Stamina", stats.MaxStamina)

	-- Inicializar sistema de movimiento compartido
	local movementSystem = TetoMovementSystem.setup(character, stats)

	-- Cargar animaciones de habilidades (específicas de cada Teto)
	local danceAnimation = Instance.new("Animation")
	danceAnimation.AnimationId = "rbxassetid://132143907803840"
	local danceAnimationTrack = animator:LoadAnimation(danceAnimation)
	danceAnimationTrack.Priority = Enum.AnimationPriority.Action

	local eatAnimation = Instance.new("Animation")
	eatAnimation.AnimationId = "rbxassetid://95911847263961"
	local eatAnimationTrack = animator:LoadAnimation(eatAnimation)
	eatAnimationTrack.Priority = Enum.AnimationPriority.Action

	-- Cargar sonido de baile
	local danceSound = Instance.new("Sound")
	danceSound.SoundId = "rbxassetid://105626105493246"
	danceSound.Volume = 0.5
	danceSound.Parent = humanoidRootPart

	-- Variables de cooldown y buffs
	local danceCooldownActive = false
	local eatCooldownActive = false
	local danceBuffActive = false

	-- Sistema de prevención de habilidades múltiples
	local function isAnyAbilityActive()
		return humanoid:GetAttribute("IsDancing") or humanoid:GetAttribute("IsEating")
	end

	-- Función para aplicar buff de velocidad después del baile
	local function applyDanceSpeedBuff()
		if danceBuffActive then return end

		danceBuffActive = true
		humanoid:SetAttribute("DanceBuffActive", true)

		-- Aplicar buff de velocidad usando el nuevo sistema de multiplicadores
		local buffMultiplier = 1 + stats.DanceSpeedBuff
		movementSystem.setSpeedMultiplier(buffMultiplier)

		-- Crear efecto visual del buff (partículas doradas alrededor del personaje)
		local buffEffect = Instance.new("Attachment")
		buffEffect.Name = "DanceBuffEffect"
		buffEffect.Parent = humanoidRootPart

		-- Efecto de partículas doradas
		local particles = Instance.new("ParticleEmitter")
		particles.Parent = buffEffect
		particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		particles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0)) -- Dorado
		particles.Size = NumberSequence.new(0.2)
		particles.Lifetime = NumberRange.new(0.5, 1.0)
		particles.Rate = 20
		particles.SpreadAngle = Vector2.new(360, 360)
		particles.Speed = NumberRange.new(2, 4)

		print("¡Buff de velocidad activado! +20% velocidad por " .. stats.DanceBuffDuration .. " segundos")

		-- Remover buff después del tiempo especificado
		spawn(function()
			wait(stats.DanceBuffDuration)

			-- Restaurar multiplicador normal
			movementSystem.setSpeedMultiplier(1.0)

			-- Remover efecto visual
			if buffEffect and buffEffect.Parent then
				-- Fade out de las partículas
				local fadeOutTween = TweenService:Create(
					particles,
					TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{Rate = 0}
				)
				fadeOutTween:Play()

				fadeOutTween.Completed:Connect(function()
					buffEffect:Destroy()
				end)
			end

			danceBuffActive = false
			humanoid:SetAttribute("DanceBuffActive", false)
			print("Buff de velocidad terminado")
		end)
	end

	-- Función para bailar (Q) - CON SOLUCIÓN MEJORADA
	local function doDance()
		-- VERIFICACIÓN CORRECTA: Solo verificar su propio cooldown y habilidades activas
		if danceCooldownActive or isAnyAbilityActive() then
			if danceCooldownActive then
				print("No se puede bailar: baile en cooldown")
			else
				print("No se puede bailar: otra habilidad está activa")
			end
			return
		end

		danceCooldownActive = true
		humanoid:SetAttribute("IsDancing", true)

		-- Detener animación actual del movimiento
		movementSystem.stopCurrentAnimation()

		-- Detener movimiento
		local originalWalkSpeed = humanoid.WalkSpeed
		humanoid.WalkSpeed = 0

		-- SOLUCIÓN MEJORADA: Usar PlatformStand + BodyPosition + BodyGyro
		humanoid.PlatformStand = true

		-- Crear BodyGyro para fijar orientación (evita rotaciones)
		local gyro = Instance.new("BodyGyro")
		gyro.Name = "DanceGyro"
		gyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)     -- fuerza para resistir rotaciones
		gyro.P = 1e4                                     -- suavidad
		gyro.CFrame = humanoidRootPart.CFrame           -- objetivo: mantener la orientación actual
		gyro.Parent = humanoidRootPart

		-- Crear BodyPosition para mantener posición fija (mejor que BodyForce)
		local bodyPosition = Instance.new("BodyPosition")
		bodyPosition.Name = "DancePosition"
		bodyPosition.MaxForce = Vector3.new(1e5, 1e5, 1e5)  -- Fuerza máxima
		bodyPosition.P = 1e4                                 -- Suavidad
		bodyPosition.D = 500                                 -- Amortiguación (evita oscilaciones)
		bodyPosition.Position = humanoidRootPart.Position   -- Mantener posición actual
		bodyPosition.Parent = humanoidRootPart

		-- Reproducir animación y sonido
		danceAnimationTrack:Play()
		danceSound:Play()

		spawn(function()
			wait(stats.DanceDuration)

			-- Fade-out del sonido
			local fadeOutTween = TweenService:Create(
				danceSound,
				TweenInfo.new(1, Enum.EasingStyle.Linear),
				{Volume = 0}
			)
			fadeOutTween:Play()

			fadeOutTween.Completed:Connect(function()
				danceSound:Stop()
				danceSound.Volume = 0.5
			end)

			-- Detener animación
			danceAnimationTrack:Stop()

			-- LIMPIAR ESTABILIZADORES MEJORADOS
			-- Quitar BodyGyro
			if gyro and gyro.Parent then 
				gyro:Destroy() 
			end
			-- Quitar BodyPosition
			if bodyPosition and bodyPosition.Parent then 
				bodyPosition:Destroy() 
			end

			-- Restaurar movimiento y quitar inmunidad
			humanoid.WalkSpeed = originalWalkSpeed
			humanoid.PlatformStand = false -- Quitar inmunidad
			humanoid:SetAttribute("IsDancing", false)

			-- ¡APLICAR BUFF DE VELOCIDAD!
			applyDanceSpeedBuff()

			-- Cooldown
			wait(stats.DanceCooldown - stats.DanceDuration)
			danceCooldownActive = false
			print("Baile disponible nuevamente")
		end)
	end

	-- Función para comer baguette (E)
	local function eatBaguette()
		-- VERIFICACIÓN CORRECTA: Solo verificar su propio cooldown y habilidades activas
		if eatCooldownActive or isAnyAbilityActive() then
			if eatCooldownActive then
				print("No se puede comer: comer en cooldown")
			else
				print("No se puede comer: otra habilidad está activa")
			end
			return
		end

		eatCooldownActive = true
		humanoid:SetAttribute("IsEating", true)

		-- Detener animación actual del movimiento
		movementSystem.stopCurrentAnimation()

		-- Aplicar lentitud del 30% y bloquear correr
		local eatSlownessMultiplier = 1 - stats.EatSlowness -- 0.7 (30% más lento)
		movementSystem.setEatingState(true, eatSlownessMultiplier)

		-- Reproducir animación de comer
		eatAnimationTrack:Play()

		spawn(function()
			wait(stats.EatCastTime)

			-- Curar 25 HP
			local newHealth = math.min(humanoid.Health + 25, humanoid.MaxHealth)
			humanoid.Health = newHealth

			-- Detener animación
			eatAnimationTrack:Stop()

			-- Quitar lentitud y permitir correr nuevamente
			movementSystem.setEatingState(false, 1.0)

			humanoid:SetAttribute("IsEating", false)

			-- Cooldown
			wait(stats.EatCooldown - stats.EatCastTime)
			eatCooldownActive = false
			print("Comer disponible nuevamente")
		end)
	end

	-- Detectar entrada de teclas para habilidades
	local function onInputBegan(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.Q then
			doDance()
		elseif input.KeyCode == Enum.KeyCode.E then
			eatBaguette()
		end
	end

	-- Conectar eventos de input para habilidades
	UserInputService.InputBegan:Connect(onInputBegan)
end

-- Configurar cuando el personaje carga por primera vez
if player.Character then
	setupCharacter()
end

-- Reconfigurar cada vez que el personaje respawnea
player.CharacterAdded:Connect(setupCharacter)