--# Blood Effects Module - Made by RiseBit
--!strict

export type BloodConfig = {
	originPos: Vector3,
	minAmount: number,
	maxAmount: number,
	force: number?
}

export type DrippingBloodConfig = {
	originPos: Vector3,
	minAmount: number,
	maxAmount: number,
	maxBloodDistance: number,
	bloodDuration: number
}

export type WholeBloodConfig = {
	originPos: Vector3,
	minAmount: number,
	maxAmount: number,
	force: number,
	bloodDuration: number
}

-- Services
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

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
local function getFloorPosition(startPos: Vector3): Vector3?
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = PartToIgnore
	params.FilterType = Enum.RaycastFilterType.Exclude

	local ray = workspace:Raycast(startPos, Vector3.new(0, -50, 0), params)
	if not ray then return nil end

	return ray.Position
end

local function createBloodPart(position: Vector3, size: Vector3?, shape: Enum.PartType?, anchored: boolean?, transparency: number?)
	local part = Instance.new("Part")
	part.Name = "BloodDrop"
	part.Size = size or Vector3.new(0.218, 0.218, 0.218)
	part.Shape = shape or Enum.PartType.Ball
	part.Material = Enum.Material.Neon
	part.BrickColor = BrickColor.new("Really red")
	part.CanCollide = false
	part.Anchored = anchored or false
	part.Transparency = transparency or 0
	part.Position = position
	part.Parent = workspace
	return part
end

-- Main Module
local BloodModule = {}

-- Small Blood: Blood that spreads around but no drips
function BloodModule.SmallBlood(config: BloodConfig)
	if RunService:IsServer() then warn("For Smoother Result Run this on Client") end
	if not config.minAmount or not config.maxAmount then warn("please add MINAMOUNT AND MAXAMOUNT to your Config") return end
	if not config.originPos then warn("please add ORIGIN POSITION to your Config") return end
	if not config.force then warn("please add FORCE to your Config") return end

	local bloodAmount = math.random(config.minAmount, config.maxAmount)
	local force = config.force or 1

	for _ = 1, bloodAmount do
		local offset = Vector3.new(math.random(-1, 1) * 0.5, math.random(-1, 1) * 0.5, math.random(-1, 1) * 0.5)
		local part = createBloodPart(config.originPos + offset, nil, nil, false, 1)

		task.wait()
		local impulse = Vector3.new(math.random(-1, 1) * force, math.random(0, 1) * force, math.random(-1, 1) * force)
		part:ApplyImpulse(part.AssemblyMass * impulse)
		part.Transparency = 0
		Debris:AddItem(part, 3)
	end
end

-- Dripping Blood: Blood that drips and gone in floor (no drop)
function BloodModule.DrippingBlood(config: DrippingBloodConfig)
	if RunService:IsServer() then warn("For Smoother Result Run this on Client") end
	if not config.minAmount or not config.maxAmount then warn("please add MINAMOUNT AND MAXAMOUNT to your Config") return end
	if not config.originPos then warn("please add ORIGIN POSITION to your Config") return end
	if not config.bloodDuration then warn("please add BLOOD DURATION to your Config") return end
	if not config.maxBloodDistance then warn("please add MAX BLOOD DISTANCE to your Config") return end

	local bloodAmount = math.random(config.minAmount, config.maxAmount)

	for _ = 1, bloodAmount do
		local x = config.originPos.X + math.random(-config.maxBloodDistance, config.maxBloodDistance)
		local z = config.originPos.Z + math.random(-config.maxBloodDistance, config.maxBloodDistance)

		local floorPos = getFloorPosition(Vector3.new(x, config.originPos.Y, z))
		if not floorPos then continue end

		local partPos = Vector3.new(x, floorPos.Y + floorPos.Y / 2, z)
		local part = createBloodPart(partPos, Vector3.new(0.5, 0.35, 0.5), Enum.PartType.Cylinder, true, 1)
		part.Rotation = Vector3.new(0, 0, 90)

		local originalSize = part.Size
		local scaleUpInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local scaleUp = TweenService:Create(part, scaleUpInfo, { Size = Vector3.new(originalSize.X * 0.25, originalSize.Y * 5, originalSize.Z * 6), Transparency = 0 })
		scaleUp:Play()

		scaleUp.Completed:Once(function()
			local scaleDownInfo = TweenInfo.new(config.bloodDuration - 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			local scaleDown = TweenService:Create(part, scaleDownInfo, { Transparency = 1 })
			scaleDown:Play()
		end)

		Debris:AddItem(part, config.bloodDuration)
	end
end

-- Whole Blood: Blood that falls and drips in floor
function BloodModule.WholeBlood(config: WholeBloodConfig)
	if RunService:IsServer() then warn("For Smoother Result Run this on Client") end
	if not config.minAmount or not config.maxAmount then warn("please add MINAMOUNT AND MAXAMOUNT to your Config") return end
	if not config.originPos then warn("please add ORIGIN POSITION to your Config") return end
	if not config.bloodDuration then warn("please add BLOOD DURATION to your Config") return end
	if not config.force then warn("please add FORCE to your Config") return end

	local bloodAmount = math.random(config.minAmount, config.maxAmount)

	for _ = 1, bloodAmount do
		task.spawn(function()
			local offset = Vector3.new(math.random(-1, 1) * 0.5, math.random(-1, 1) * 0.5, math.random(-1, 1) * 0.5)
			local part = createBloodPart(config.originPos + offset)

			local impulse = Vector3.new(math.random(-1, 1) * config.force, math.random(0, 2) * config.force, math.random(-1, 1) * config.force)
			part:ApplyImpulse(part.AssemblyMass * impulse)

			part.Touched:Connect(function(hit)
				if hit.Parent and hit.Parent:IsA("Accessory") then return end
				if hit.Parent and hit.Parent:FindFirstChild("Humanoid") or hit.Name == "BloodDrop" then return end

				part.Anchored = true
				part.Position += Vector3.yAxis -- required so that it above on the Floor slightly so that the ray can found the floor
				local floorPos = getFloorPosition(part.Position)
				if not floorPos then return end

				part.Shape = Enum.PartType.Cylinder
				part.CFrame = CFrame.new(Vector3.new(part.Position.X, floorPos.Y, part.Position.Z))
				part.Rotation = Vector3.new(0, 0, 90)

				local originalSize = part.Size
				local scaleUpInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				local scaleUp = TweenService:Create(part, scaleUpInfo, { Size = Vector3.new(originalSize.X * 0.25, originalSize.Y * 7, originalSize.Z * 9), Transparency = 0.4 })
				scaleUp:Play()

				scaleUp.Completed:Once(function()
					local scaleDownInfo = TweenInfo.new(config.bloodDuration - 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
					local scaleDown = TweenService:Create(part, scaleDownInfo, { Size = Vector3.new(part.Size.X * 1.1, part.Size.Y * 0.9, part.Size.Z * 0.85), Transparency = 1 })
					scaleDown:Play()

					scaleDown.Completed:Once(function()
						part:Destroy()
					end)
				end)
			end)
		end)
	end
end

return BloodModule
