local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Crear la GUI de stamina
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StaminaGUI"
screenGui.Parent = playerGui

-- Frame principal
local mainFrame = Instance.new("Frame")
mainFrame.Name = "StaminaFrame"
mainFrame.Size = UDim2.new(0, 200, 0, 20)
mainFrame.Position = UDim2.new(0, 20, 1, -60)
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mainFrame.BackgroundTransparency = 0.3
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Esquinas redondeadas
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

-- Barra de stamina
local staminaBar = Instance.new("Frame")
staminaBar.Name = "StaminaBar"
staminaBar.Size = UDim2.new(1, 0, 1, 0)
staminaBar.Position = UDim2.new(0, 0, 0, 0)
staminaBar.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
staminaBar.BorderSizePixel = 0
staminaBar.Parent = mainFrame

-- Esquinas redondeadas para la barra
local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 10)
barCorner.Parent = staminaBar

-- Texto de stamina
local staminaText = Instance.new("TextLabel")
staminaText.Name = "StaminaText"
staminaText.Size = UDim2.new(1, 0, 1, 0)
staminaText.Position = UDim2.new(0, 0, 0, 0)
staminaText.BackgroundTransparency = 1
staminaText.Text = "100/100"
staminaText.TextColor3 = Color3.fromRGB(255, 255, 255)
staminaText.TextScaled = true
staminaText.Font = Enum.Font.GothamBold
staminaText.Parent = mainFrame

-- Función para actualizar la GUI
local function updateStaminaGUI()
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	local currentStamina = humanoid:GetAttribute("Stamina") or 100
	local maxStamina = humanoid:GetAttribute("MaxStamina") or 100

	-- Actualizar texto
	staminaText.Text = math.floor(currentStamina) .. "/" .. maxStamina

	-- Actualizar barra con animación suave
	local targetSize = UDim2.new(currentStamina / maxStamina, 0, 1, 0)

	local tween = TweenService:Create(
		staminaBar,
		TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = targetSize}
	)
	tween:Play()

	-- Cambiar color según el nivel de stamina
	local staminaPercent = currentStamina / maxStamina
	local targetColor

	if staminaPercent > 0.6 then
		targetColor = Color3.fromRGB(100, 200, 100) -- Verde
	elseif staminaPercent > 0.3 then
		targetColor = Color3.fromRGB(200, 200, 100) -- Amarillo
	else
		targetColor = Color3.fromRGB(200, 100, 100) -- Rojo
	end

	local colorTween = TweenService:Create(
		staminaBar,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundColor3 = targetColor}
	)
	colorTween:Play()
end

-- Conectar la actualización
local connection
connection = RunService.Heartbeat:Connect(function()
	if player.Character then
		updateStaminaGUI()
	end
end)

-- Limpiar cuando el jugador se va
player.AncestryChanged:Connect(function()
	if not player.Parent then
		connection:Disconnect()
	end
end)