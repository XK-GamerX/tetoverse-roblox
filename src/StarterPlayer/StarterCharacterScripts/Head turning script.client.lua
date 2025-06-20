--[[
	VALERIU2005PRO
--]]

wait()

--[Pre-Funcs]:

local Ang = CFrame.Angles	--[Storing these as variables so I dont have to type them out.]
local aSin = math.asin
local aTan = math.atan

--[Constants]:

local Cam = game.Workspace.CurrentCamera

local Plr = game.Players.LocalPlayer
local Mouse = Plr:GetMouse()
local Body = Plr.Character or Plr.CharacterAdded:wait()
local Head = Body:WaitForChild("Head")
local Hum = Body:WaitForChild("Humanoid")
local Core = Body:WaitForChild("HumanoidRootPart")
local IsR6 = (Hum.RigType.Value==0)	--[Checking if the player is using R15 or R6.]
local Trso = (IsR6 and Body:WaitForChild("Torso")) or Body:WaitForChild("UpperTorso")
local Neck = (IsR6 and Trso:WaitForChild("Neck")) or Head:WaitForChild("Neck")	--[Once we know the Rig, we know what to find.]
local Waist = (not IsR6 and Trso:WaitForChild("Waist"))	--[R6 doesn't have a waist joint, unfortunately.]

--[[
	[Whether rotation follows the camera or the mouse.]
	[Useful with tools if true, but camera tracking runs smoother.]
--]]
local MseGuide = false
--[[
	[Whether the whole character turns to face the mouse.]
	[If set to true, MseGuide will be set to true and both HeadHorFactor and BodyHorFactor will be set to 0]
--]]
local TurnCharacterToMouse = false
--[[
	[Horizontal and Vertical limits for head and body tracking.]
	[Setting to 0 negates tracking, setting to 1 is normal tracking, and setting to anything higher than 1 goes past real life head/body rotation capabilities.]
--]]
local HeadHorFactor = 1
local HeadVertFactor = 0.6
local BodyHorFactor = 0.5
local BodyVertFactor = 0.4

--[[
	[How fast the body rotates.]
	[Setting to 0 negates tracking, and setting to 1 is instant rotation. 0.5 is a nice in-between that works with MseGuide on or off.]
	[Setting this any higher than 1 causes weird glitchy shaking occasionally.]
--]]
local UpdateSpeed = 0.5

local NeckOrgnC0 = Neck.C0	--[Get the base C0 to manipulate off of.]
local WaistOrgnC0 = (not IsR6 and Waist.C0)	--[Get the base C0 to manipulate off of.]

--[Setup]:

Neck.MaxVelocity = 1/3

-- Activation]:
if TurnCharacterToMouse == true then
	MseGuide = true
	HeadHorFactor = 0
	BodyHorFactor = 0
end

game:GetService("RunService").RenderStepped:Connect(function()
	local CamCF = Cam.CoordinateFrame
	if ((IsR6 and Body["Torso"]) or Body["UpperTorso"])~=nil and Body["Head"]~=nil then	--[Check for the Torso and Head...]
		local TrsoLV = Trso.CFrame.lookVector
		local HdPos = Head.CFrame.p
		if IsR6 and Neck or Neck and Waist then	--[Make sure the Neck still exists.]
			if Cam.CameraSubject:IsDescendantOf(Body) or Cam.CameraSubject:IsDescendantOf(Plr) then
				local Dist = nil;
				local Diff = nil;
				if not MseGuide then	--[If not tracking the Mouse then get the Camera.]
					Dist = (Head.CFrame.p-CamCF.p).magnitude
					Diff = Head.CFrame.Y-CamCF.Y
					if not IsR6 then	--[R6 and R15 Neck rotation C0s are different; R15: X axis inverted and Z is now the Y.]
						Neck.C0 = Neck.C0:lerp(NeckOrgnC0*Ang((aSin(Diff/Dist)*HeadVertFactor), -(((HdPos-CamCF.p).Unit):Cross(TrsoLV)).Y*HeadHorFactor, 0), UpdateSpeed/2)
						Waist.C0 = Waist.C0:lerp(WaistOrgnC0*Ang((aSin(Diff/Dist)*BodyVertFactor), -(((HdPos-CamCF.p).Unit):Cross(TrsoLV)).Y*BodyHorFactor, 0), UpdateSpeed/2)
					else	--[R15s actually have the properly oriented Neck CFrame.]
						Neck.C0 = Neck.C0:lerp(NeckOrgnC0*Ang(-(aSin(Diff/Dist)*HeadVertFactor), 0, -(((HdPos-CamCF.p).Unit):Cross(TrsoLV)).Y*HeadHorFactor),UpdateSpeed/2)
					end
				else
					local Point = Mouse.Hit.p
					Dist = (Head.CFrame.p-Point).magnitude
					Diff = Head.CFrame.Y-Point.Y
					if not IsR6 then
						Neck.C0 = Neck.C0:lerp(NeckOrgnC0*Ang(-(aTan(Diff/Dist)*HeadVertFactor), (((HdPos-Point).Unit):Cross(TrsoLV)).Y*HeadHorFactor, 0), UpdateSpeed/2)
						Waist.C0 = Waist.C0:lerp(WaistOrgnC0*Ang(-(aTan(Diff/Dist)*BodyVertFactor), (((HdPos-Point).Unit):Cross(TrsoLV)).Y*BodyHorFactor, 0), UpdateSpeed/2)
					else
						Neck.C0 = Neck.C0:lerp(NeckOrgnC0*Ang((aTan(Diff/Dist)*HeadVertFactor), 0, (((HdPos-Point).Unit):Cross(TrsoLV)).Y*HeadHorFactor), UpdateSpeed/2)
					end
				end
			end
		end
	end
	if TurnCharacterToMouse == true then
		Hum.AutoRotate = false
		Core.CFrame = Core.CFrame:lerp(CFrame.new(Core.Position, Vector3.new(Mouse.Hit.p.x, Core.Position.Y, Mouse.Hit.p.z)), UpdateSpeed / 2)
	else
		Hum.AutoRotate = true
	end
end)