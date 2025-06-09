local plr = game.Players.LocalPlayer
local FuncLib = game.ReplicatedStorage:WaitForChild("FuncLib")
local RunService = game:GetService("RunService")

local Character = plr.Character or plr.CharacterAdded:Wait()
local HumRP = Character.HumanoidRootPart

local RootJoint = Character.LowerTorso.Root

local Force = nil
local Direction = nil
local V1 = 0
local V2 = 0

local RootJointC0 = RootJoint.C0

--RUNSERVICE FUNCTION

RunService.RenderStepped:Connect(function()

	Force = HumRP.Velocity * Vector3.new(1,0,1)
	if Force.Magnitude > 2 then

		Direction = Force.Unit
		V1 = HumRP.CFrame.RightVector:Dot(Direction)
		V2 = HumRP.CFrame.LookVector:Dot(Direction)
	else
		V1 = 0
		V2 = 0
	end

	RootJoint.C0 = RootJoint.C0:Lerp(RootJointC0 * CFrame.Angles(math.rad(-V2 * 30), math.rad(-V1 * 30), 0), 0.2)

end)