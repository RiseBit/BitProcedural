--# Rock Effects Module - Made by RiseBit
--!strict

export type CraterConfig = {
	originPos: Vector3,
	rockAmount: number,
	radius: number,
	size: Vector3,
	material: Enum.Material?,
	popOneByOne: boolean?,
	realisticFade: boolean?
}

export type ExplosiveCraterConfig = {
	originPos: Vector3,
	rockAmount: number,
	layerAmount: number,
	radius: number,
	size: Vector3,
	material: Enum.Material?,
	realisticFade: boolean?
}

export type RockPropelConfig = {
	originPos: Vector3,
	minAmount: number,
	maxAmount: number,
	radius: number,
	size: Vector3,
	force: number,
	material: Enum.Material?
}

-- Services
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Tween configurations
local Tweens = {
	["CircleCraterPop"] = TweenInfo.new(.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	["CircleCraterOut"] = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
	["ExplosiveCraterPop"] = TweenInfo.new(.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
}

-- Table to ignore parts/models in raycasts
local PartToIgnore: {Instance} = {}

-- Setup ignore list for raycasting
local function setupIgnoreListListeners()
	for _, child in workspace:GetChildren() do
		if child:IsA("Model") and child:FindFirstChild("Humanoid") then
			table.insert(PartToIgnore, child)
		end
	end

	Players.PlayerAdded:Connect(function(plr)
		plr.CharacterAdded:Connect(function(char)
			table.insert(PartToIgnore, char)
		end)
	end)

	workspace.ChildAdded:Connect(function(child)
		if child:FindFirstChild("Humanoid") then
			table.insert(PartToIgnore, child)
		end
	end)

	workspace.ChildRemoved:Connect(function(child)
		local index = table.find(PartToIgnore, child)
		if index then
			table.remove(PartToIgnore, index)
		end
	end)
end

setupIgnoreListListeners()

-- Helper Functions
local function createPart(position: Vector3, size: Vector3, material: Enum.Material, cframe: CFrame?, transparency: number?, anchored: boolean?, canCollide: boolean?)
	local part = Instance.new("Part")
	part.Position = position
	part.Size = size
	part.Material = material or Enum.Material.Rock
	part.Transparency = transparency or 0
	part.Anchored = anchored ~= false
	part.CanCollide = canCollide or false

	if cframe then
		part.CFrame = cframe
	end

	part.Parent = workspace
	table.insert(PartToIgnore, part)
	return part
end

local function destroyPart(part: BasePart)
	local index = table.find(PartToIgnore, part)
	if index then
		table.remove(PartToIgnore, index)
	end
	part:Destroy()
end

local function applyShake(part: BasePart, intensity: number, duration: number?)
	local connection = RunService.Heartbeat:Connect(function(dt)
		local x = (math.random() - 0.5) * intensity
		local y = (math.random() - 0.5) * intensity
		local z = (math.random() - 0.5) * intensity
		part.CFrame = part.CFrame * CFrame.Angles(x, y, z)
	end)

	if duration then
		task.delay(duration, function()
			connection:Disconnect()
		end)
	end
end

local function getFloorPosition(startPos: Vector3): Vector3?
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = PartToIgnore
	params.FilterType = Enum.RaycastFilterType.Exclude

	local ray = workspace:Raycast(startPos, Vector3.new(0, -50, 0), params)
	if not ray then return nil end

	return ray.Position
end

local function tweenCraterPart(part: BasePart, popYPoint: number, realisticFade: boolean, popTweenInfo: TweenInfo, outTweenInfo: TweenInfo, scaleFactor: number)
	if realisticFade then
		part.Position += Vector3.yAxis * popYPoint
		part.Transparency = 0

		applyShake(part, 0.02)
		local t1 = TweenService:Create(part, popTweenInfo, { Size = part.Size * scaleFactor })
		t1:Play()

		t1.Completed:Once(function()
			task.wait(0.9)
			applyShake(part, 0.05)
			local t2 = TweenService:Create(part, outTweenInfo, { Position = part.Position - Vector3.yAxis * 10, Size = part.Size / scaleFactor })
			t2:Play()

			t2.Completed:Once(function()
				destroyPart(part)
			end)
		end)
	else
		local t1 = TweenService:Create(part, popTweenInfo, { Position = part.Position + Vector3.yAxis * popYPoint, Size = part.Size * scaleFactor, Transparency = 0 })
		t1:Play()

		t1.Completed:Once(function()
			task.wait(0.9)

			local t2 = TweenService:Create(part, outTweenInfo, { Position = part.Position - Vector3.yAxis * 10, Size = part.Size / scaleFactor, Transparency = 0.6 })
			t2:Play()

			t2.Completed:Once(function()
				destroyPart(part)
			end)
		end)
	end
end

-- Main Module
local RockModule = {}

-- Circle Crater: Evenly spaced rocks in a circle
function RockModule.CircleCrater(config: CraterConfig)
	if not config.radius then warn("please add RADIUS to your Config") return end
	if not config.rockAmount then warn("please add ROCK AMOUNT to your Config") return end
	if not config.size then warn("please add SIZE to your Config") return end

	local popYPoint = .83
	local angleIncrement = (math.pi * 2) / config.rockAmount
	local popOneByOne = config.popOneByOne or false
	local realisticFade = config.realisticFade or false
	local material = config.material or Enum.Material.Rock

	for i = 1, config.rockAmount do
		local x = config.originPos.X + math.cos(angleIncrement * i) * config.radius
		local z = config.originPos.Z + math.sin(angleIncrement * i) * config.radius
		local floorPos = getFloorPosition(Vector3.new(x, config.originPos.Y + config.size.Y/2, z))
		if not floorPos then continue end

		local partPos = Vector3.new(x, (floorPos.Y) - popYPoint, z)
		local cframe = CFrame.new(partPos, config.originPos) * CFrame.Angles(0, 0, math.rad(30)) 
		local part = createPart(partPos, config.size, material, cframe, 0.8, true, false)

		tweenCraterPart(part, popYPoint, realisticFade, Tweens.CircleCraterPop, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), 1.15)

		if popOneByOne then
			task.wait(0.05)
		end
	end
end

-- Overlapping Crater: Random, overlapping rocks with gaps
function RockModule.OverlappingCrater(config: CraterConfig)
	if not config.radius then warn("please add RADIUS to your Config") return end
	if not config.rockAmount then warn("please add ROCK AMOUNT to your Config") return end
	if not config.size then warn("please add SIZE to your Config") return end

	local popYPoint = 1
	local amountRockAppear = math.round(math.random(config.rockAmount / 5, config.rockAmount / 2))
	local alreadyAppear = 0
	local angleIncrement = (math.pi * 2) / config.rockAmount
	local popOneByOne = config.popOneByOne or false
	local realisticFade = config.realisticFade or false
	local material = config.material or Enum.Material.Rock

	for i = 1, config.rockAmount do
		if alreadyAppear >= amountRockAppear then break end
		local gapChance = math.round(math.random(config.rockAmount / 5, config.rockAmount / 2))

		if i % gapChance ~= 0 then continue end
		alreadyAppear += 1

		local x = config.originPos.X + math.cos(angleIncrement * i) * config.radius
		local z = config.originPos.Z + math.sin(angleIncrement * i) * config.radius
		local floorPos = getFloorPosition(Vector3.new(x, config.originPos.Y + config.size.Y/2, z))
		if not floorPos then continue end

		local partPos = Vector3.new(x, (floorPos.Y + config.size.Y/2) - popYPoint, z)
		local cframe = CFrame.new(partPos, config.originPos) * CFrame.Angles(math.rad(math.random(-15, 15)), math.rad(math.random(0, 360)), math.rad(math.random(-45, 45)))
		local part = createPart(partPos, config.size, material, cframe, 0.8, true, false)

		tweenCraterPart(part, popYPoint, realisticFade, Tweens.CircleCraterPop, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), 1.15)

		if popOneByOne then
			task.wait(0.05)
		end
	end
end

-- Explosive Crater: Multi-layered expanding craters
function RockModule.ExplosiveCrater(config: ExplosiveCraterConfig)
	if not config.radius then warn("please add RADIUS to your Config") return end
	if not config.rockAmount then warn("please add ROCK AMOUNT to your Config") return end
	if not config.size then warn("please add SIZE to your Config") return end

	if config.layerAmount <= 1 then return end
	local popYPoint = 1.5
	local realisticFade = config.realisticFade or false
	local material = config.material or Enum.Material.Rock

	local layers = {}
	for i = 1, config.layerAmount do
		local layerRadius = (i == 1) and config.radius * 1.3 or config.radius * i * 2
		local layerRockAmount = (i == 1) and config.rockAmount or config.rockAmount * i
		local layerSize = (i == 1) and config.size or config.size * (i / 1.5)
		table.insert(layers, { radius = layerRadius, rockAmount = layerRockAmount, size = layerSize })
	end

	for _, layer in layers do
		local angleIncrement = (math.pi * 2) / layer.rockAmount
		for z = 1, layer.rockAmount do
			local x = config.originPos.X + math.cos(angleIncrement * z) * layer.radius
			local zz = config.originPos.Z + math.sin(angleIncrement * z) * layer.radius

			local floorPos = getFloorPosition(Vector3.new(x, config.originPos.Y + config.size.Y/2, zz))
			if not floorPos then continue end

			local partPos = Vector3.new(x, (floorPos.Y + config.size.Y/2) - popYPoint, zz)
			local cframe = CFrame.new(partPos, floorPos) * CFrame.Angles(math.rad(math.random(50, 90)), 0, math.rad(math.random(50, 90)))
			local part = createPart(partPos, layer.size, material, cframe, 0.8, true, false)

			tweenCraterPart(part, popYPoint, realisticFade, Tweens.ExplosiveCraterPop, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), 1.35)
		end
		task.wait(math.random(1, 5) / 100)
	end
end

-- Rock Propel: Propel rocks outward
function RockModule.RockPropel(config: RockPropelConfig)
	if RunService:IsServer() then warn("For Smoother Result Run this on Client") end
	if not config.minAmount or not config.maxAmount then warn("please add MINAMOUNT AND MAXAMOUNT to your Config") return end
	if not config.originPos then warn("please add ORIGIN POSITION to your Config") return end
	if not config.force then warn("please add FORCE to your Config") return end

	local rockAmount = math.random(config.minAmount, config.maxAmount)
	local angleIncrement = (math.pi * 2) / rockAmount
	local material = config.material or Enum.Material.Rock

	for i = 1, rockAmount do
		local x = math.cos(angleIncrement * (math.random(-1, 1) * rockAmount)) * config.radius
		local z = math.sin(angleIncrement * (math.random(-1, 1) * rockAmount)) * config.radius

		local floorPos = getFloorPosition(Vector3.new(x, config.originPos.Y + config.size.Y/2, z))
		if not floorPos then continue end

		local partPos = config["originPos"]
		local cframe = CFrame.new(partPos, floorPos) * CFrame.Angles(math.rad(math.random(50, 90)), 0, math.rad(math.random(50, 90)))
		local part = createPart(partPos, config.size, material, cframe, 0, false, false)

		local impulse = Vector3.new(math.random(-1, 1) * config.force, math.random(0, 2) * config.force, math.random(-1, 1) * config.force)
		part:ApplyImpulse(part.AssemblyMass * impulse)

		local fadeTween = TweenService:Create(part, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = 1 })
		fadeTween:Play()

		fadeTween.Completed:Once(function()
			destroyPart(part)
		end)
	end
end

return RockModule
