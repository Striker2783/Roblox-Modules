local RunService = game:GetService("RunService")
local module = {
	base64 = {},
	hits = {},
	others = {},
}

function module.others.randomFloat(min: number, max: number)
	return math.random() * (max - min) - min
end

function module.hit.findHumanoid(part: BasePart): Humanoid?
	local char = part:FindFirstAncestorOfClass("Model")
	return char and char:FindFirstChildOfClass("Humanoid")
end

function module.hit.isPartOfIgnore(instance: Instance, ignore: { Instance }?)
	ignore = ignore or {}
	for _, v in ignore do
		if v:IsAncestorOf(instance) then
			return true
		end
	end
	return false
end

export type HitParams = {
	part: BasePart,
	ignore: { Instance }?,
}

function module.hit.touch(p: HitParams, fn: (BasePart) -> ())
	p.ignore = p.ignore or {}
	return p.part.Touched:Connect(function(otherPart)
		if not otherPart or not otherPart.Parent then
			return
		end
		if module.hit.isPartOfIgnore(p.part, p.ignore) then
			return
		end
		fn(otherPart)
	end)
end

function module.hit.firstTouch(p: HitParams, fn: (BasePart) -> ())
	local c
	local bool = false
	c = module.hit.touch(p, function(otherPart)
		if bool then
			return
		end
		bool = true
		c:Disconnect()
		fn(otherPart)
	end)
	return c
end

function module.hit.touchHumanoid(p: HitParams, fn: (Humanoid) -> ())
	return module.hit.touch(p, function(oPart)
		local h = module.hit.findHumanoid(oPart)
		if not h then
			return
		end
		fn(h)
	end)
end

function module.hit.touchHumanoidOnce(p: HitParams, fn: (Humanoid) -> ())
	local t: { Humanoid } = {}
	return module.hit.touchHumanoid(p, function(h)
		if table.find(t, h) then
			return
		end
		table.insert(t, h)
		fn(h)
	end)
end

function module.hit.touchFirstHumanoid(p: HitParams, fn: (Humanoid) -> ())
	local c
	local bool = false
	c = module.hit.touchHumanoid(p, function(h)
		if bool then
			return
		end
		bool = true
		c:Disconnect()
		fn(h)
	end)
	return c
end

function module.hit.getHumanoidsInPartArray(arr: { BasePart })
	local humanoids: { Humanoid } = {}
	for _, value in arr do
		local h = module.hit.findHumanoid(value)
		if not h or table.find(humanoids, h) then
			continue
		end
		table.insert(humanoids, h)
	end
	return humanoids
end

function module.hit.getHumanoidsInSphere(pos: Vector3, radius: number, overlap: OverlapParams)
	return module.hit.getHumanoidsInPartArray(workspace:GetPartBoundsInRadius(pos, radius, overlap))
end

function module.hit.getHumanoidsInRectangle(cframe: CFrame, size: Vector3, overlap: OverlapParams)
	return module.hit.getHumanoidsInPartArray(workspace:GetPartBoundsInBox(cframe, size, overlap))
end
-- Works For Rectangular Pieces
function module.hit.heartBeatHitOnce(part: BasePart | Model, overlap: OverlapParams, fn: (Humanoid) -> ())
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
				return module.hit.getHumanoidsInSphere(
					part.CFrame.Position,
					math.min(part.Size.X, part.Size.Y, part.Size.Z),
					overlap
				)
			end)
		end
		return b(function()
			return module.hit.getHumanoidsInRectangle(part.CFrame, part.Size, overlap)
		end)
	elseif part:IsA("Model") then
		return b(function()
			local cframe, size = part:GetBoundingBox()
			return module.hit.getHumanoidsInRectangle(cframe, size, overlap)
		end)
	end
	error("Part is neither model nor basepart")
end
--
function module.base64.to_base64(data)
	local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	return (
		(data:gsub(".", function(x)
			local r, b = "", x:byte()
			for i = 8, 1, -1 do
				r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and "1" or "0")
			end
			return r
		end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
			if #x < 6 then
				return ""
			end
			local c = 0
			for i = 1, 6 do
				c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
			end
			return b:sub(c + 1, c + 1)
		end) .. ({ "", "==", "=" })[#data % 3 + 1]
	)
end

-- this function converts base64 to string
function module.base64.from_base64(data)
	local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	data = string.gsub(data, "[^" .. b .. "=]", "")
	return (
		data:gsub(".", function(x)
			if x == "=" then
				return ""
			end
			local r, f = "", (b:find(x) - 1)
			for i = 6, 1, -1 do
				r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0")
			end
			return r
		end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
			if #x ~= 8 then
				return ""
			end
			local c = 0
			for i = 1, 8 do
				c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0)
			end
			return string.char(c)
		end)
	)
end

return module
