-- Services --
local Players = game:FindService("Players")

-- Variables --
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local CharacterType = Humanoid.RigType
local R15 = Enum.HumanoidRigType.R15
local R6 = Enum.HumanoidRigType.R6

-- Functions --
local function CreateParticleEmitter(Parent: Instance)
	local NewEmitter = Instance.new("ParticleEmitter")
	NewEmitter.Transparency = NumberSequence.new(0.7, 0.9)
	NewEmitter.Texture = "rbxassetid://129985930"	
	NewEmitter.SpreadAngle = Vector2.new(10, 10)
	NewEmitter.Size = NumberSequence.new(0.3)
	NewEmitter.Lifetime = NumberRange.new(1)
	NewEmitter.EmissionDirection = "Back"
	NewEmitter.Enabled = false
	NewEmitter.Parent = Parent
	return NewEmitter
end

local function SetParticleEmitters()
	if CharacterType == R15 then
		local RightFoot = Character.RightFoot
		local LeftFoot = Character.LeftFoot
		local ParticleEmmiterRight = CreateParticleEmitter(RightFoot)
		local ParticleEmmiterLeft = CreateParticleEmitter(LeftFoot)
		return ParticleEmmiterLeft, ParticleEmmiterRight
	elseif CharacterType == R6 then
		local RightLeg = Character["Right Leg"]
		local LeftLeg = Character["Left Leg"]
		local ParticleEmmiterRight = CreateParticleEmitter(RightLeg)
		local ParticleEmmiterLeft = CreateParticleEmitter(LeftLeg)
		return ParticleEmmiterLeft, ParticleEmmiterRight
	end
end


-- Create Particle Emitters --
local ParticleLeft, ParticleRight = SetParticleEmitters()

-- Connect Events --
Humanoid.Running:Connect(function(RunSpeed)
	if RunSpeed >= 1 then
		ParticleRight.Enabled = true
		ParticleRight.Rate = (RunSpeed * 2.5)
		ParticleLeft.Enabled = true
		ParticleLeft.Rate = (RunSpeed * 2.5)
	elseif RunSpeed <= 1 then
		ParticleRight.Enabled = false
		ParticleLeft.Enabled = false
	end
end)