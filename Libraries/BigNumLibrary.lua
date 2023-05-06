local module = {}
module.__index = module
module.__tostring = function(l: BigNumLibrary)
	local str = l.positive and "" or "-"
	str = str .. string.format("%.2f", l.num) .. tostring(l.mag)
	return str
end

module.__unm = function(l: BigNumLibrary)
	l.positive = not l.positive
	return l
end

module.__lt = function(l1: BigNumLibrary, l2: number | BigNumLibrary)
	if l1.positive and not l2.positive then
		return false
	elseif not l1.positive and l2.positive then
		return true
	end
end

function module.getInit(self: BigNumLibrary): init
	return {
		positive = self.positive,
		num = self.num,
		mag = self.mag,
	}
end

function module.new(params: init): BigNumLibrary
	local self: init = params or {
		positive = true,
		num = 0,
		mag = 0,
	}

	setmetatable(self, module)
	return self
end

export type init = {
	positive: boolean,
	num: number,
	mag: number,
}
export type BigNumLibrary = init & typeof(module)

return module
