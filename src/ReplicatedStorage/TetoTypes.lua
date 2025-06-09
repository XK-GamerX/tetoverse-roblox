-- Sistema de tipos de Teto disponibles
local TetoTypes = {
	Default = {
		Name = "Teto Default",
		ModelName = "TetoDefault", -- Nombre del modelo en ReplicatedStorage.Models
		ScriptName = "TetoDefaultAbilities", -- Script de habilidades específico
		Stats = {
			WalkSpeed = 12,
			RunSpeed = 24,
			MaxHealth = 100,
			MaxStamina = 100,
			StaminaRegenRate = 10,
			StaminaRunCost = 15,
		},
		Abilities = {
			Primary = {
				Name = "Bailar",
				Key = "Q",
				Cooldown = 30,
				Duration = 5,
				Description = "Baila para obtener un buff de velocidad"
			},
			Secondary = {
				Name = "Comer Baguette",
				Key = "E", 
				Cooldown = 40,
				CastTime = 3,
				Description = "Come para recuperar 25 HP"
			}
		}
	},

	UT = {
		Name = "UT Teto (Ataque)",
		ModelName = "UTTeto", -- El nuevo modelo que vas a subir
		ScriptName = "UTTetoAbilities", -- Script de habilidades específico
		Stats = {
			WalkSpeed = 9,
			RunSpeed = 18, -- Calculado como WalkSpeed * 2
			MaxHealth = 120,
			MaxStamina = 100,
			StaminaRegenRate = 10,
			StaminaRunCost = 15,
		},
		Abilities = {
			Primary = {
				Name = "Lanzar Baguette",
				Key = "Q",
				Cooldown = 40,
				CastTime = 1.5,
				ProjectileDelay = 1.0, -- 1 segundo después de usar la habilidad
				Damage = 20,
				Description = "Lanza un baguette que atraviesa paredes y stunea"
			},
			Secondary = {
				Name = "Colocar Mina",
				Key = "E",
				Cooldown = 50,
				CastTime = 2.0,
				Damage = 20,
				Description = "Coloca una mina que explota al reactivar la habilidad"
			}
		}
	}
}

return TetoTypes