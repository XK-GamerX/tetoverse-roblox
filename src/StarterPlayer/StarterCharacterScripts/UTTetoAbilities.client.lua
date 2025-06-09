-- Habilidades específicas para UT Teto (Ataque)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Importar el sistema de movimiento compartido
local TetoMovementSystem = require(script.Parent.TetoMovementSystem)
local TetoTypes = require(ReplicatedStorage.TetoTypes)

local player = Players.LocalPlayer

-- Función para configurar las habilidades cuando el personaje carga
local function setupCharacter()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

	-- Esperar a que el Animator esté disponible
	local animator = humanoid:WaitForChild("Animator")

	-- Obtener stats desde la configuración
	local tetoType = humanoid:GetAttribute("TetoType") or "UT"
	local tetoConfig = TetoTypes[tetoType]
	local stats = tetoConfig.Stats

	-- Stats específicos de UT Teto
	local extendedStats = {
		WalkSpeed = stats.WalkSpeed,
		RunSpeed = stats.RunSpeed,
		MaxHealth = stats.MaxHealth,
		MaxStamina = stats.MaxStamina,
		StaminaRegenRate = stats.StaminaRegenRate,
		StaminaRunCost = stats.StaminaRunCost,
		-- Habilidades específicas
		BaguetteCooldown = tetoConfig.Abilities.Primary.Cooldown,
		BaguetteCastTime = tetoConfig.Abilities.Primary.CastTime,
		BaguetteProjectileDelay = tetoConfig.Abilities.Primary.ProjectileDelay,
		BaguetteDamage = tetoConfig.Abilities.Primary.Damage,
		MineCooldown = tetoConfig.Abilities.Secondary.Cooldown,
		MineCastTime = tetoConfig.Abilities.Secondary.CastTime,
		MineDamage = tetoConfig.Abilities.Secondary.Damage,
		-- Efectos de habilidades
		BaguetteSlowness = 0.3, -- 30% de lentitud
		BaguetteSlowDuration = 3, -- 3 segundos
		StunDuration = 2, -- 2 segundos de stun
	}

	-- Aplicar stats básicos
	humanoid.WalkSpeed = extendedStats.WalkSpeed
	humanoid.MaxHealth = extendedStats.MaxHealth
	humanoid.Health = extendedStats.MaxHealth

	-- Configurar atributos de stamina
	humanoid:SetAttribute("MaxStamina", extendedStats.MaxStamina)
	humanoid:SetAttribute("Stamina", extendedStats.MaxStamina)

	-- Inicializar sistema de movimiento compartido
	local movementSystem = TetoMovementSystem.setup(character, extendedStats)

	-- Cargar animaciones específicas de UT Teto
	local baguetteThrowAnimation = Instance.new("Animation")
	baguetteThrowAnimation.AnimationId = "rbxassetid://123109313245375"
	local baguetteThrowTrack = animator:LoadAnimation(baguetteThrowAnimation)
	baguetteThrowTrack.Priority = Enum.AnimationPriority.Action

	-- Variables de cooldown y estado
	local baguetteCooldownActive = false
	local mineCooldownActive = false
	local placedMine = nil -- Referencia a la mina colocada
	local baguetteSlowActive = false

	-- Sistema de prevención de habilidades múltiples
	local function isAnyAbilityActive()
		return humanoid:GetAttribute("IsLaunchingBaguette") or humanoid:GetAttribute("IsPlacingMine")
	end

	-- Función para aplicar lentitud después de lanzar baguette
	local function applyBaguetteSlowness()
		if baguetteSlowActive then return end

		baguetteSlowActive = true

		-- Aplicar lentitud del 30%
		local slownessMultiplier = 1 - extendedStats.BaguetteSlowness -- 0.7
		movementSystem.setSpeedMultiplier(slownessMultiplier)

		print("Lentitud aplicada por lanzar baguette (-30% velocidad por " .. extendedStats.BaguetteSlowDuration .. " segundos)")

		-- Remover lentitud después del tiempo especificado
		spawn(function()
			wait(extendedStats.BaguetteSlowDuration)

			-- Restaurar multiplicador normal
			movementSystem.setSpeedMultiplier(1.0)

			baguetteSlowActive = false
			print("Lentitud de baguette terminada")
		end)
	end

	-- Función para crear proyectil de baguette
	local function createBaguetteProjectile(startPosition, direction)
		-- Verificar si existe el modelo en ReplicatedStorage
		local baguetteModel = ReplicatedStorage.Models:FindFirstChild("BaguetteProjectile")
		local baguette

		if baguetteModel then
			-- Usar el modelo personalizado
			baguette = baguetteModel:Clone()
			baguette.Name = "BaguetteProjectile"
		else
			-- Crear baguette básico si no existe el modelo
			baguette = Instance.new("Part")
			baguette.Name = "BaguetteProjectile"
			baguette.Size = Vector3.new(0.5, 0.5, 2) -- Forma de baguette
			baguette.Material = Enum.Material.SmoothPlastic
			baguette.BrickColor = BrickColor.new("Nougat") -- Color de pan
			baguette.Shape = Enum.PartType.Cylinder
			baguette.TopSurface = Enum.SurfaceType.Smooth
			baguette.BottomSurface = Enum.SurfaceType.Smooth
		end

		baguette.CanCollide = false

		-- Posicionar y orientar el baguette
		baguette.CFrame = CFrame.lookAt(startPosition, startPosition + direction) * CFrame.Angles(0, math.rad(90), 0)
		baguette.Parent = workspace

		-- Obtener la parte principal para el movimiento
		local mainPart = baguette:IsA("Model") and baguette.PrimaryPart or baguette
		if baguette:IsA("Model") and not mainPart then
			mainPart = baguette:FindFirstChild("Handle") or baguette:GetChildren()[1]
		end

		-- Crear BodyVelocity para el movimiento
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
		bodyVelocity.Velocity = direction * 50 -- Velocidad del proyectil
		bodyVelocity.Parent = mainPart

		-- Efecto visual de rotación
		local rotationTween = TweenService:Create(
			mainPart,
			TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
			{CFrame = mainPart.CFrame * CFrame.Angles(0, 0, math.rad(360))}
		)
		rotationTween:Play()

		-- Crear efecto de partículas
		local attachment = Instance.new("Attachment")
		attachment.Parent = mainPart

		local particles = Instance.new("ParticleEmitter")
		particles.Parent = attachment
		particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		particles.Color = ColorSequence.new(Color3.fromRGB(255, 200, 100))
		particles.Size = NumberSequence.new(0.1)
		particles.Lifetime = NumberRange.new(0.3, 0.6)
		particles.Rate = 10
		particles.SpreadAngle = Vector2.new(45, 45)
		particles.Speed = NumberRange.new(1, 3)

		-- Función para aplicar stun a un dummy
		local function applyStunToDummy(targetHumanoid, targetCharacter)
			-- Detener movimiento
			targetHumanoid.WalkSpeed = 0
			targetHumanoid.JumpPower = 0

			-- Cargar animaciones de stun
			local targetAnimator = targetHumanoid:FindFirstChild("Animator")
			if targetAnimator then
				-- Animación de stun loop
				local stunLoopAnim = Instance.new("Animation")
				stunLoopAnim.AnimationId = "rbxassetid://77852621647650"
				local stunLoopTrack = targetAnimator:LoadAnimation(stunLoopAnim)
				stunLoopTrack.Priority = Enum.AnimationPriority.Action4
				stunLoopTrack.Looped = true

				-- Animación de fin de stun
				local stunEndAnim = Instance.new("Animation")
				stunEndAnim.AnimationId = "rbxassetid://114280798518642"
				local stunEndTrack = targetAnimator:LoadAnimation(stunEndAnim)
				stunEndTrack.Priority = Enum.AnimationPriority.Action4

				-- Reproducir animación de stun loop
				stunLoopTrack:Play()

				-- Remover stun después del tiempo especificado
				spawn(function()
					wait(extendedStats.StunDuration)

					-- Detener animación de loop y reproducir animación de fin
					stunLoopTrack:Stop()
					stunEndTrack:Play()

					-- Esperar a que termine la animación de fin
					stunEndTrack.Ended:Wait()

					-- Restaurar movimiento
					if targetHumanoid and targetHumanoid.Parent then
						targetHumanoid.WalkSpeed = 16 -- Velocidad normal de dummy
						targetHumanoid.JumpPower = 50
						print("Stun terminado en dummy")
					end
				end)
			else
				-- Si no hay animator, solo hacer stun básico
				spawn(function()
					wait(extendedStats.StunDuration)
					if targetHumanoid and targetHumanoid.Parent then
						targetHumanoid.WalkSpeed = 16
						targetHumanoid.JumpPower = 50
						print("Stun básico terminado en dummy")
					end
				end)
			end
		end

		-- Detectar colisión con dummies
		local function onTouched(hit)
			local hitCharacter = hit.Parent
			local hitHumanoid = hitCharacter:FindFirstChild("Humanoid")

			-- Verificar que sea un dummy y no el propio jugador
			if hitHumanoid and hitCharacter ~= character and hitCharacter.Name:find("Dummy") then
				print("¡Baguette impactó en dummy!")

				-- Aplicar daño
				hitHumanoid.Health = math.max(0, hitHumanoid.Health - extendedStats.BaguetteDamage)

				-- Aplicar stun con animaciones
				applyStunToDummy(hitHumanoid, hitCharacter)

				-- Crear efecto de impacto
				local impactEffect = Instance.new("Explosion")
				impactEffect.Position = mainPart.Position
				impactEffect.BlastRadius = 5
				impactEffect.BlastPressure = 0
				impactEffect.Parent = workspace

				-- Destruir el baguette
				baguette:Destroy()
			end
		end

		-- Conectar evento de colisión a todas las partes del baguette
		if baguette:IsA("Model") then
			for _, part in pairs(baguette:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Touched:Connect(onTouched)
				end
			end
		else
			baguette.Touched:Connect(onTouched)
		end

		-- Destruir el baguette después de 5 segundos si no impacta
		spawn(function()
			wait(5)
			if baguette and baguette.Parent then
				baguette:Destroy()
			end
		end)
	end

	-- Función para lanzar baguette (Q)
	local function launchBaguette()
		if baguetteCooldownActive or isAnyAbilityActive() then
			if baguetteCooldownActive then
				print("No se puede lanzar baguette: habilidad en cooldown")
			else
				print("No se puede lanzar baguette: otra habilidad está activa")
			end
			return
		end

		baguetteCooldownActive = true
		humanoid:SetAttribute("IsLaunchingBaguette", true)

		-- Detener animación actual del movimiento
		movementSystem.stopCurrentAnimation()

		-- Reducir velocidad durante el cast
		local originalWalkSpeed = humanoid.WalkSpeed
		humanoid.WalkSpeed = originalWalkSpeed * 0.5

		-- Reproducir animación de lanzar baguette
		baguetteThrowTrack:Play()

		print("Preparando lanzamiento de baguette...")

		spawn(function()
			-- Tiempo de cast
			wait(extendedStats.BaguetteCastTime)

			-- Verificar que el personaje sigue existiendo
			if not character.Parent or not humanoidRootPart.Parent then
				return
			end

			-- Esperar el delay del proyectil
			wait(extendedStats.BaguetteProjectileDelay - extendedStats.BaguetteCastTime)

			-- Lanzar el baguette en dirección recta hacia adelante
			local launchDirection = humanoidRootPart.CFrame.LookVector
			local launchPosition = humanoidRootPart.Position + launchDirection * 2 + Vector3.new(0, 1, 0)

			createBaguetteProjectile(launchPosition, launchDirection)
			print("¡Baguette lanzado!")

			-- Detener animación de lanzar
			baguetteThrowTrack:Stop()

			-- Restaurar velocidad
			humanoid.WalkSpeed = originalWalkSpeed
			humanoid:SetAttribute("IsLaunchingBaguette", false)

			-- Aplicar lentitud después de lanzar
			applyBaguetteSlowness()

			-- Cooldown
			wait(extendedStats.BaguetteCooldown - extendedStats.BaguetteProjectileDelay)
			baguetteCooldownActive = false
			print("Lanzar baguette disponible nuevamente")
		end)
	end

	-- Función para crear mina
	local function createMine(position)
		local mine = Instance.new("Part")
		mine.Name = "TetoMine"
		mine.Size = Vector3.new(2, 0.5, 2)
		mine.Material = Enum.Material.Metal
		mine.BrickColor = BrickColor.new("Really red")
		mine.CanCollide = false
		mine.Anchored = true
		mine.Shape = Enum.PartType.Cylinder
		mine.CFrame = CFrame.new(position) * CFrame.Angles(math.rad(90), 0, 0)
		mine.Parent = workspace

		-- Efecto visual de la mina (luz parpadeante)
		local pointLight = Instance.new("PointLight")
		pointLight.Color = Color3.fromRGB(255, 0, 0)
		pointLight.Brightness = 1
		pointLight.Range = 10
		pointLight.Parent = mine

		-- Animación de parpadeo
		local blinkTween = TweenService:Create(
			pointLight,
			TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{Brightness = 0.2}
		)
		blinkTween:Play()

		-- Partículas de advertencia
		local attachment = Instance.new("Attachment")
		attachment.Parent = mine

		local particles = Instance.new("ParticleEmitter")
		particles.Parent = attachment
		particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		particles.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
		particles.Size = NumberSequence.new(0.1)
		particles.Lifetime = NumberRange.new(0.5, 1.0)
		particles.Rate = 5
		particles.SpreadAngle = Vector2.new(360, 360)
		particles.Speed = NumberRange.new(1, 2)

		return mine
	end

	-- Función para explotar mina
	local function explodeMine(mine)
		if not mine or not mine.Parent then
			return
		end

		local minePosition = mine.Position

		-- Crear explosión visual
		local explosion = Instance.new("Explosion")
		explosion.Position = minePosition
		explosion.BlastRadius = 15
		explosion.BlastPressure = 0 -- Sin empuje físico
		explosion.Parent = workspace

		-- Función para aplicar stun a un dummy (reutilizada)
		local function applyStunToDummy(targetHumanoid, targetCharacter)
			-- Detener movimiento
			targetHumanoid.WalkSpeed = 0
			targetHumanoid.JumpPower = 0

			-- Cargar animaciones de stun
			local targetAnimator = targetHumanoid:FindFirstChild("Animator")
			if targetAnimator then
				-- Animación de stun loop
				local stunLoopAnim = Instance.new("Animation")
				stunLoopAnim.AnimationId = "rbxassetid://77852621647650"
				local stunLoopTrack = targetAnimator:LoadAnimation(stunLoopAnim)
				stunLoopTrack.Priority = Enum.AnimationPriority.Action4
				stunLoopTrack.Looped = true

				-- Animación de fin de stun
				local stunEndAnim = Instance.new("Animation")
				stunEndAnim.AnimationId = "rbxassetid://114280798518642"
				local stunEndTrack = targetAnimator:LoadAnimation(stunEndAnim)
				stunEndTrack.Priority = Enum.AnimationPriority.Action4

				-- Reproducir animación de stun loop
				stunLoopTrack:Play()

				-- Remover stun después del tiempo especificado
				spawn(function()
					wait(extendedStats.StunDuration)

					-- Detener animación de loop y reproducir animación de fin
					stunLoopTrack:Stop()
					stunEndTrack:Play()

					-- Esperar a que termine la animación de fin
					stunEndTrack.Ended:Wait()

					-- Restaurar movimiento
					if targetHumanoid and targetHumanoid.Parent then
						targetHumanoid.WalkSpeed = 16 -- Velocidad normal de dummy
						targetHumanoid.JumpPower = 50
						print("Stun de mina terminado en dummy")
					end
				end)
			else
				-- Si no hay animator, solo hacer stun básico
				spawn(function()
					wait(extendedStats.StunDuration)
					if targetHumanoid and targetHumanoid.Parent then
						targetHumanoid.WalkSpeed = 16
						targetHumanoid.JumpPower = 50
						print("Stun básico de mina terminado en dummy")
					end
				end)
			end
		end

		-- Detectar dummies en el área de explosión
		for _, obj in pairs(workspace:GetChildren()) do
			if obj.Name:find("Dummy") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
				local distance = (obj.HumanoidRootPart.Position - minePosition).Magnitude

				if distance <= 15 then -- Radio de explosión
					print("¡Mina explotó cerca de dummy!")

					-- Aplicar daño
					obj.Humanoid.Health = math.max(0, obj.Humanoid.Health - extendedStats.MineDamage)

					-- Aplicar stun con animaciones
					applyStunToDummy(obj.Humanoid, obj)
				end
			end
		end

		-- Destruir la mina
		mine:Destroy()
	end

	-- Función para colocar/explotar mina (E)
	local function handleMine()
		if mineCooldownActive or isAnyAbilityActive() then
			if mineCooldownActive then
				print("No se puede usar mina: habilidad en cooldown")
			else
				print("No se puede usar mina: otra habilidad está activa")
			end
			return
		end

		-- Si ya hay una mina colocada, explotarla
		if placedMine and placedMine.Parent then
			print("Explotando mina...")
			explodeMine(placedMine)
			placedMine = nil
			return
		end

		-- Colocar nueva mina
		mineCooldownActive = true
		humanoid:SetAttribute("IsPlacingMine", true)

		-- Detener animación actual del movimiento
		movementSystem.stopCurrentAnimation()

		-- Reducir velocidad durante el cast
		local originalWalkSpeed = humanoid.WalkSpeed
		humanoid.WalkSpeed = originalWalkSpeed * 0.3

		print("Colocando mina...")

		spawn(function()
			-- Tiempo de cast
			wait(extendedStats.MineCastTime)

			-- Verificar que el personaje sigue existiendo
			if not character.Parent or not humanoidRootPart.Parent then
				return
			end

			-- Colocar la mina en el suelo frente al personaje
			local minePosition = humanoidRootPart.Position + humanoidRootPart.CFrame.LookVector * 3
			minePosition = Vector3.new(minePosition.X, minePosition.Y - 2, minePosition.Z) -- Bajar al suelo

			placedMine = createMine(minePosition)
			print("¡Mina colocada! Presiona E nuevamente para explotar")

			-- Restaurar velocidad
			humanoid.WalkSpeed = originalWalkSpeed
			humanoid:SetAttribute("IsPlacingMine", false)

			-- Cooldown
			wait(extendedStats.MineCooldown - extendedStats.MineCastTime)
			mineCooldownActive = false
			print("Colocar mina disponible nuevamente")
		end)
	end

	-- Detectar entrada de teclas para habilidades
	local function onInputBegan(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.Q then
			launchBaguette()
		elseif input.KeyCode == Enum.KeyCode.E then
			handleMine()
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

-- Marcar como deshabilitado por defecto (se habilitará cuando se clone)
script.Disabled = true