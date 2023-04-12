local RunService = game:GetService("RunService")
local module = {}
module.__index = module
module.__tostring = function()
	return "BezierCurve"
end

type VectPoint = BasePart | Vector3

function module.new(...: VectPoint): BezierVector3
	local a: { VectPoint } = { ... }
	local self: init = {
		points = {},
		degree = #a - 1,
	}

	for i = 1, #a do
		self.points[i] = a[i]
	end

	setmetatable(self, module)
	return self
end
-- Gets pos from points
function module.getPos(points: { Vector3 }, a: number): Vector3
	local deg = #points - 1
	assert(deg >= 0)
	for _ = 1, deg do
		local newPts: { Vector3 } = {}
		for i = 1, #points - 1 do
			local v = points[i]
			newPts[i] = v:Lerp(points[i + 1], a)
		end
		points = newPts
	end
	return points[1]
end

function module.convertToVects(points: { VectPoint }): { Vector3 }
	local newTable: { Vector3 } = {}
	for i = 1, #points do
		local pt = points[i]
		if typeof(pt) == "Vector3" then
			newTable[i] = pt
		elseif pt:IsA("BasePart") then
			newTable[i] = pt.CFrame.Position
		end
	end
	return newTable
end

function module.get(self: BezierVector3, t: number)
	return self.getDS(self.points, t)
end

function module.getDS(pts: { VectPoint }, t: number)
	local newTb = module.convertToVects(pts)
	return module.getPos(newTb, t)
end

export type BasicTweenParams = {
	endEvent: () -> (),
	time: number,
}
function module.tweenPart(self: BezierVector3, part: BasePart, args: BasicTweenParams)
	return self:tween(function(pos)
		part.Position = pos
	end, args)
end

function module.tweenModel(self: BezierVector3, model: Model, args: BasicTweenParams)
	return self:tween(function(pos)
		model:MoveTo(pos)
	end, args)
end

function module.tween(self: BezierVector3, setPos: (Vector3) -> (), args: BasicTweenParams)
	local connection
	local t = 0
	connection = RunService.Heartbeat:Connect(function(dt)
		t += dt
		if t >= args.time then
			connection:Disconnect()
			args.endEvent()
			return
		end
		local pos = self:get(t)
		setPos(pos)
	end)
	return connection
end

export type init = {
	points: { VectPoint },
}
export type BezierVector3 = init & typeof(module)

return module
