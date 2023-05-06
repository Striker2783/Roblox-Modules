local RunService = game:GetService("RunService")
local module: init & any = {}
module.__index = module
module.__tostring = function()
	return "BezierCurve"
end

type VectPoint = BasePart | Vector3

export type IBezier = {
	tweenModel: (self: BezierCurve, model: Model, args: BasicTweenParams) -> RBXScriptConnection,
	tweenPart: (self: BezierCurve, part: BasePart, args: BasicTweenParams) -> RBXScriptConnection,
	points: { VectPoint },
}

function module.new(...: VectPoint): IBezier
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

function module.getCFrame(points: { Vector3 }, a: number): CFrame
	local deg = #points - 1
	assert(deg >= 0)
	for _ = 1, deg - 1 do
		local newPts: { Vector3 } = {}
		for i = 1, #points - 1 do
			local v = points[i]
			newPts[i] = v:Lerp(points[i + 1], a)
		end
		points = newPts
	end
	return CFrame.new(points[1]:Lerp(points[2], a), points[2])
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

function module:getC(t: number)
	return self.getDSC(self.points, t)
end

function module.getDSC(pts: { VectPoint }, t: number)
	local newTb = module.convertToVects(pts)
	return module.getCFrame(newTb, t)
end

function module:getP(t: number)
	return self.getDSP(self.points, t)
end

function module.getDSP(pts: { VectPoint }, t: number)
	local newTb = module.convertToVects(pts)
	return module.getPos(newTb, t)
end

export type BasicTweenParams = {
	endEvent: () -> (),
	time: number,
	type: "CFrame" | "Vector3",
}
function module:tweenPart(part: BasePart, args: BasicTweenParams)
	if args.type == "Vector3" then
		return self:tweenThingy(part, args, function(pos)
			part.Position = pos
		end)
	elseif args.type == "CFrame" then
		return self:tweenThingy(part, args, function(cframe)
			part.CFrame = cframe
		end)
	end
	error("No args.type")
end

function module:tweenModel(model: Model, args: BasicTweenParams)
	if args.type == "Vector3" then
		return self:tweenThingy(model, args, function(pos)
			model:MoveTo(pos)
		end)
	elseif args.type == "CFrame" then
		return self:tweenModelCFrame(model, args, function(cframe)
			model:PivotTo(cframe)
		end)
	end
	error("No args.type")
end

function module:tweenThingy(part: BasePart | Model, args: BasicTweenParams, fn: (CFrame | Vector3) -> ())
	local connection
	connection = self:tween(function(cframe)
		if not part then
			connection:Disconnect()
		end
		fn(cframe)
	end, args)
	return connection
end

function module:tween(setPos: (Vector3 | CFrame) -> (), args: BasicTweenParams)
	local connection
	local t = 0
	connection = RunService.Heartbeat:Connect(function(dt)
		t += dt
		if t >= args.time then
			connection:Disconnect()
			args.endEvent()
			return
		end
		local pos = args.type == "CFrame" and self:getC(t / args.time) or self:getP(t / args.time)
		setPos(pos)
	end)
	return connection
end

export type init = {
	points: { VectPoint },
	degree: number,
}
export type BezierCurve = init & typeof(module)

return {
	new = module.new,
}
