local RunService = game:GetService("RunService")
local module = {}

function module.randomFloat(min: number, max: number)
	return math.random() * (max - min) - min
end

function module.findHumanoid(part: BasePart): Humanoid?
	local char = part:FindFirstAncestorOfClass("Model")
	return char and char:FindFirstChildOfClass("Humanoid")
end

function module.touch(part: BasePart, fn: (BasePart) -> ())
	return part.Touched:Connect(function(otherPart)
		if not otherPart or not otherPart.Parent then
			return
		end
		fn(otherPart)
	end)
end

function module.firstTouch(part: BasePart, fn: (BasePart) -> ())
	local c
	local bool = false
	c = module.touch(part, function(otherPart)
		if bool then
			return
		end
		bool = true
		c:Disconnect()
		fn(otherPart)
	end)
	return c
end

function module.touchHumanoid(part: BasePart, fn: (Humanoid) -> ())
	return module.touch(part, function(oPart)
		local h = module.findHumanoid(oPart)
		if not h then
			return
		end
		fn(h)
	end)
end

function module.touchHumanoidOnce(part: BasePart, fn: (Humanoid) -> ())
	local t: { Humanoid } = {}
	return module.touchHumanoid(part, function(h)
		if table.find(t, h) then
			return
		end
		table.insert(t, h)
		fn(h)
	end)
end

function module.touchFirstHumanoid(part: BasePart, fn: (Humanoid) -> ())
	local c
	local bool = false
	c = module.touchHumanoid(part, function(h)
		if bool then
			return
		end
		bool = true
		c:Disconnect()
		fn(h)
	end)
	return c
end

function module.getHumanoidsInPartArray(arr: { BasePart })
	local humanoids: { Humanoid } = {}
	for _, value in arr do
		local h = module.findHumanoid(value)
		if not h or table.find(humanoids, h) then
			continue
		end
		table.insert(humanoids, h)
	end
	return humanoids
end

function module.getHumanoidsInSphere(pos: Vector3, radius: number, overlap: OverlapParams)
	return module.getHumanoidsInPartArray(workspace:GetPartBoundsInRadius(pos, radius, overlap))
end

function module.getHumanoidsInRectangle(cframe: CFrame, size: Vector3, overlap: OverlapParams)
	return module.getHumanoidsInPartArray(workspace:GetPartBoundsInBox(cframe, size, overlap))
end
-- Works For Rectangular Pieces
function module.heartBeatHitOnce(part: BasePart | Model, overlap: OverlapParams, fn: (Humanoid) -> ())
	local humanoids: { Humanoid } = {}
	local function a(hits: { Humanoid })
		for _, h in hits do
			if table.find(humanoids, h) then
				continue
			end
			table.insert(humanoids, h)
			fn(h)
		end
	end
	local function b(hitFunc: () -> { Humanoid })
		return RunService.Heartbeat:Connect(function()
			a(hitFunc())
		end)
	end
	if part:IsA("BasePart") then
		if part:IsA("Part") and part.Type == Enum.PartType.Ball then
			return b(function()
				return module.getHumanoidsInSphere(
					part.CFrame.Position,
					math.min(part.Size.X, part.Size.Y, part.Size.Z),
					overlap
				)
			end)
		end
		return b(function()
			return module.getHumanoidsInRectangle(part.CFrame, part.Size, overlap)
		end)
	elseif part:IsA("Model") then
		return b(function()
			local cframe, size = part:GetBoundingBox()
			return module.getHumanoidsInRectangle(cframe, size, overlap)
		end)
	end
	error("Part is neither model nor basepart")
end

return module
