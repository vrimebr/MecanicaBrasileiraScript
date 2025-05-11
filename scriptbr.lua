-- Script Lua para Mecânica Brasileira com interface gráfica
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

-- Obtém o jogador
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid", 5)

-- Verifica se o humanoid foi encontrado
if not humanoid then
    print("Erro: Humanoid não encontrado.")
    return
end

-- Parâmetros do carro
local carParams = {
    maxSpeed = 15, -- Velocidade máxima inicial (m/s)
    acceleration = 3, -- Aceleração (m/s²)
    speedIncrement = 0.5, -- Incremento de velocidade por segundo
    maxSpeedCap = 50, -- Limite máximo de velocidade
    currentSpeed = 0, -- Velocidade atual
    cheatDetected = false
}
local moveInput = 0 -- Entrada do jogador (W/S)

-- Função para encontrar o veículo
local function getVehicle()
    if humanoid.SeatPart and (humanoid.SeatPart:IsA("VehicleSeat") or humanoid.SeatPart:IsA("BasePart")) then
        local vehicle = humanoid.SeatPart.Parent
        if vehicle then
            -- Define PrimaryPart se não estiver configurado
            if not vehicle.PrimaryPart then
                vehicle.PrimaryPart = vehicle:FindFirstChildWhichIsA("BasePart") or humanoid.SeatPart
            end
            if vehicle.PrimaryPart then
                vehicle.PrimaryPart.Anchored = false -- Garante que o veículo não está ancorado
                return vehicle
            end
        end
    end
    return nil
end

-- Função para atualizar parâmetros
local function updateParam(key, value)
    local newValue = tonumber(value)
    if newValue then
        carParams[key] = newValue
        if key == "maxSpeed" and carParams.currentSpeed > newValue then
            carParams.currentSpeed = newValue
        end
        print("Parâmetro atualizado: " .. key .. " = " .. newValue)
    end
end

-- Função para simular cheat
local function simulateCheat()
    carParams.currentSpeed = carParams.maxSpeed + 5 -- Boost suave
    carParams.cheatDetected = true
    print("Simulando cheat...")
    wait(2)
    carParams.cheatDetected = false
    carParams.currentSpeed = carParams.maxSpeed
end

-- Função de atualização da física
local function updatePhysics(deltaTime)
    local vehicle = getVehicle()
    if not vehicle then
        print("Nenhum veículo encontrado. Sente-se em um carro.")
        return
    end

    -- Incrementa maxSpeed
    carParams.maxSpeed = math.min(carParams.maxSpeed + carParams.speedIncrement * deltaTime, carParams.maxSpeedCap)

    -- Calcula nova velocidade
    local newSpeed = carParams.currentSpeed
    if moveInput > 0 then
        newSpeed = newSpeed + carParams.acceleration * deltaTime
    elseif moveInput < 0 then
        newSpeed = newSpeed - carParams.acceleration * 2 * deltaTime
    else
        newSpeed = newSpeed - carParams.acceleration * deltaTime
    end

    -- Limita a velocidade
    newSpeed = math.clamp(newSpeed, -carParams.maxSpeed * 0.5, carParams.maxSpeed)

    -- Verificação anti-cheat
    local speedJump = math.abs(newSpeed - carParams.currentSpeed)
    if speedJump > 10 and not carParams.cheatDetected then
        carParams.cheatDetected = true
        newSpeed = carParams.currentSpeed
        print("Cheat detectado internamente: Salto de velocidade = " .. speedJump)
    end
    carParams.currentSpeed = newSpeed

    -- Aplica movimento ao veículo
    local bodyVelocity = vehicle.PrimaryPart:FindFirstChild("BodyVelocity") or Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
    bodyVelocity.Velocity = vehicle.PrimaryPart.CFrame.LookVector * newSpeed
    bodyVelocity.Parent = vehicle.PrimaryPart
end

-- Cria a interface gráfica
local function createGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CarControlPanel"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui", 5)

    if not screenGui.Parent then
        print("Erro: Não foi possível acessar PlayerGui.")
        return
    end

    -- Frame principal
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 400)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    -- Título
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Text = "Controle do Carro"
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 20
    title.Parent = frame

    -- Função para criar campos de entrada
    local function createInput(labelText, key, min, max, step, yOffset)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 20)
        label.Position = UDim2.new(0, 0, 0, yOffset)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.Text = labelText
        label.TextSize = 14
        label.Parent = frame

        local input = Instance.new("TextBox")
        input.Size = UDim2.new(0, 60, 0, 20)
        input.Position = UDim2.new(0, 10, 0, yOffset + 20)
        input.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        input.TextColor3 = Color3.fromRGB(255, 255, 255)
        input.Text = tostring(carParams[key])
        input.TextSize = 14
        input.Parent = frame

        input.FocusLost:Connect(function()
            local value = tonumber(input.Text)
            if value then
                value = math.clamp(value, min, max)
                updateParam(key, value)
                input.Text = tostring(value)
            else
                input.Text = tostring(carParams[key])
            end
        end)
    end

    -- Cria campos de entrada
    createInput("Velocidade Máxima (m/s)", "maxSpeed", 10, 100, 1, 30)
    createInput("Aceleração (m/s²)", "acceleration", 1, 20, 0.5, 70)
    createInput("Incremento de Velocidade (m/s)", "speedIncrement", 0.1, 2, 0.1, 110)

    -- Botão de simular cheat
    local cheatButton = Instance.new("TextButton")
    cheatButton.Size = UDim2.new(0, 100, 0, 30)
    cheatButton.Position = UDim2.new(0, 10, 0, 160)
    cheatButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    cheatButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    cheatButton.Text = "Simular Cheat"
    cheatButton.TextSize = 14
    cheatButton.Parent = frame
    cheatButton.MouseButton1Click:Connect(simulateCheat)

    -- Status
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 50)
    statusLabel.Position = UDim2.new(0, 0, 0, 200)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.Text = "Velocidade Atual: 0 km/h"
    statusLabel.TextSize = 14
    statusLabel.Parent = frame

    -- Instruções
    local instructions = Instance.new("TextLabel")
    instructions.Size = UDim2.new(1, 0, 0, 30)
    instructions.Position = UDim2.new(0, 0, 0, 260)
    instructions.BackgroundTransparency = 1
    instructions.TextColor3 = Color3.fromRGB(150, 150, 150)
    instructions.Text = "Use W/Seta Cima para acelerar, S/Seta Baixo para frear."
    instructions.TextSize = 12
    instructions.Parent = frame

    -- Atualiza status
    RunService.Heartbeat:Connect(function()
        statusLabel.Text = "Velocidade Atual: " .. math.round(carParams.currentSpeed * 3.6) .. " km/h"
        if carParams.cheatDetected then
            statusLabel.Text = statusLabel.Text .. "\nCHEAT DETECTADO!"
            statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        else
            statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end)

    print("Interface gráfica criada com sucesso.")
end

-- Tenta criar a GUI
local success, errorMsg = pcall(createGui)
if not success then
    print("Erro ao criar GUI: " .. errorMsg)
end

-- Conecta a física
local physicsConnection = RunService.Heartbeat:Connect(function(deltaTime)
    local success, errorMsg = pcall(updatePhysics, deltaTime)
    if not success then
        print("Erro na física: " .. errorMsg)
        physicsConnection:Disconnect()
    end
end)

-- Controles de entrada
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.Up then
            moveInput = 1
            print("Acelerando...")
        elseif input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.Down then
            moveInput = -1
            print("Freiando...")
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.Up or
           input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.Down then
            moveInput = 0
            print("Parado.")
        end
    end
end)

-- Mensagem inicial
print("Script carregado com sucesso! Sente-se em um carro e use W/S para mover.")
