-- GUI temporal para seleccionar personajes
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Importar sistemas
local TetoTypes = require(ReplicatedStorage.TetoTypes)
local PlayerData = require(ReplicatedStorage.PlayerData)

-- Crear RemoteEvent para cambiar personaje
local changeCharacterEvent = ReplicatedStorage:FindFirstChild("ChangeCharacterEvent")
if not changeCharacterEvent then
	changeCharacterEvent = Instance.new("RemoteEvent")
	changeCharacterEvent.Name = "ChangeCharacterEvent"
	changeCharacterEvent.Parent = ReplicatedStorage
end

-- Crear GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CharacterSelectorGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Frame principal
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 400, 0, 300)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

-- Esquinas redondeadas
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

-- Título
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0, 50)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🎭 SELECTOR DE PERSONAJES"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

-- Botón para cerrar
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -40, 0, 10)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextScaled = true
closeButton.Font = Enum.Font.GothamBold
closeButton.BorderSizePixel = 0
closeButton.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeButton

-- Contenedor de personajes
local charactersFrame = Instance.new("ScrollingFrame")
charactersFrame.Name = "CharactersFrame"
charactersFrame.Size = UDim2.new(1, -20, 1, -70)
charactersFrame.Position = UDim2.new(0, 10, 0, 60)
charactersFrame.BackgroundTransparency = 1
charactersFrame.BorderSizePixel = 0
charactersFrame.ScrollBarThickness = 6
charactersFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
charactersFrame.Parent = mainFrame

-- Layout para los personajes
local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = charactersFrame

-- Función para crear botón de personaje
local function createCharacterButton(tetoType, tetoConfig, layoutOrder)
	local button = Instance.new("TextButton")
	button.Name = tetoType .. "Button"
	button.Size = UDim2.new(1, -12, 0, 80)
	button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	button.BorderSizePixel = 0
	button.LayoutOrder = layoutOrder
	button.Parent = charactersFrame

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = button

	-- Nombre del personaje
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -20, 0, 30)
	nameLabel.Position = UDim2.new(0, 10, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = tetoConfig.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = button

	-- Stats del personaje
	local statsLabel = Instance.new("TextLabel")
	statsLabel.Name = "StatsLabel"
	statsLabel.Size = UDim2.new(1, -20, 0, 40)
	statsLabel.Position = UDim2.new(0, 10, 0, 35)
	statsLabel.BackgroundTransparency = 1
	statsLabel.Text = string.format("❤️ %d HP | 🏃 %d Velocidad | ⚡ %d Stamina", 
		tetoConfig.Stats.MaxHealth, 
		tetoConfig.Stats.WalkSpeed, 
		tetoConfig.Stats.MaxStamina)
	statsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	statsLabel.TextScaled = true
	statsLabel.Font = Enum.Font.Gotham
	statsLabel.TextXAlignment = Enum.TextXAlignment.Left
	statsLabel.Parent = button

	-- Indicador de seleccionado
	local selectedIndicator = Instance.new("Frame")
	selectedIndicator.Name = "SelectedIndicator"
	selectedIndicator.Size = UDim2.new(0, 4, 1, 0)
	selectedIndicator.Position = UDim2.new(0, 0, 0, 0)
	selectedIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
	selectedIndicator.BorderSizePixel = 0
	selectedIndicator.Visible = false
	selectedIndicator.Parent = button

	-- Función para actualizar estado seleccionado
	local function updateSelectedState()
		local currentSelected = PlayerData.getSelectedTeto(player)
		selectedIndicator.Visible = (currentSelected == tetoType)

		if selectedIndicator.Visible then
			button.BackgroundColor3 = Color3.fromRGB(80, 120, 80)
		else
			button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		end
	end

	-- Actualizar estado inicial
	updateSelectedState()

	-- Efectos hover
	button.MouseEnter:Connect(function()
		if not selectedIndicator.Visible then
			local hoverTween = TweenService:Create(
				button,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{BackgroundColor3 = Color3.fromRGB(80, 80, 80)}
			)
			hoverTween:Play()
		end
	end)

	button.MouseLeave:Connect(function()
		if not selectedIndicator.Visible then
			local leaveTween = TweenService:Create(
				button,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{BackgroundColor3 = Color3.fromRGB(60, 60, 60)}
			)
			leaveTween:Play()
		end
	end)

	-- Función de click
	button.MouseButton1Click:Connect(function()
		-- Cambiar personaje
		changeCharacterEvent:FireServer(tetoType)

		-- Actualizar todos los botones
		for _, child in pairs(charactersFrame:GetChildren()) do
			if child:IsA("TextButton") and child:FindFirstChild("SelectedIndicator") then
				local indicator = child.SelectedIndicator
				indicator.Visible = (child.Name == tetoType .. "Button")

				if indicator.Visible then
					child.BackgroundColor3 = Color3.fromRGB(80, 120, 80)
				else
					child.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
				end
			end
		end

		-- Cerrar GUI después de seleccionar
		spawn(function()
			wait(0.5)
			mainFrame.Visible = false
		end)
	end)

	return button
end

-- Crear botones para cada tipo de Teto
local layoutOrder = 1
for tetoType, tetoConfig in pairs(TetoTypes) do
	createCharacterButton(tetoType, tetoConfig, layoutOrder)
	layoutOrder = layoutOrder + 1
end

-- Ajustar tamaño del ScrollingFrame
charactersFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	charactersFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
end)

-- Botón para abrir el selector (temporal)
local openButton = Instance.new("TextButton")
openButton.Name = "OpenSelectorButton"
openButton.Size = UDim2.new(0, 200, 0, 50)
openButton.Position = UDim2.new(0, 20, 0, 20)
openButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
openButton.Text = "🎭 CAMBIAR PERSONAJE"
openButton.TextColor3 = Color3.fromRGB(255, 255, 255)
openButton.TextScaled = true
openButton.Font = Enum.Font.GothamBold
openButton.BorderSizePixel = 0
openButton.Parent = screenGui

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0, 8)
openCorner.Parent = openButton

-- Funciones para abrir/cerrar
local function openSelector()
	mainFrame.Visible = true
	mainFrame.Size = UDim2.new(0, 0, 0, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

	local openTween = TweenService:Create(
		mainFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{
			Size = UDim2.new(0, 400, 0, 300),
			Position = UDim2.new(0.5, -200, 0.5, -150)
		}
	)
	openTween:Play()
end

local function closeSelector()
	local closeTween = TweenService:Create(
		mainFrame,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			Size = UDim2.new(0, 0, 0, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0)
		}
	)
	closeTween:Play()

	closeTween.Completed:Connect(function()
		mainFrame.Visible = false
	end)
end

-- Conectar eventos
openButton.MouseButton1Click:Connect(openSelector)
closeButton.MouseButton1Click:Connect(closeSelector)

-- Efectos hover para el botón de abrir
openButton.MouseEnter:Connect(function()
	local hoverTween = TweenService:Create(
		openButton,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundColor3 = Color3.fromRGB(120, 170, 255)}
	)
	hoverTween:Play()
end)

openButton.MouseLeave:Connect(function()
	local leaveTween = TweenService:Create(
		openButton,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundColor3 = Color3.fromRGB(100, 150, 255)}
	)
	leaveTween:Play()
end)

print("GUI de selector de personajes cargado")