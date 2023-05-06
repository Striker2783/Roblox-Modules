local module: BigNumLibrary = {}
module.__index = module

local FORMATS = {
	SCIENTIFIC = 0,
	ABBREVIATION = 1,
}

function module:__tostring()
	local str = self.positive and "" or "-"
	if -4 < self.mag and self.mag < 4 then
		return str .. string.format("%d", self.num * 10 ^ self.mag)
	end
	if self.format == FORMATS.SCIENTIFIC then
		return str .. string.format("%.2fe%d", self.num, self.mag)
	end
	return str
end

function module:__unm()
	return module.new(not self.positive, self.num, self.mag, self.format)
end

function module:__lt(o: BigNumLibrary)
	if self.positive and not o.positive then
		return false
	elseif not self.positive and o.positive then
		return true
	end
end

function module:getInit(): init
	return {
		positive = self.positive,
		num = self.num,
		mag = self.mag,
		format = self.format,
	}
end

function module.new(pos: boolean?, num: number?, mag: number?, format: number?)
	return module.newFromInit({
		positive = pos,
		num = num,
		mag = mag,
		format = format,
	})
end

function module.newFromInit(params: init): BigNumLibrary
	local self: init = {
		positive = params.positive or true,
		num = params.num or 0,
		mag = params.mag or 0,
		format = params.format or FORMATS.SCIENTIFIC,
	}

	setmetatable(self, module)
	return self
end

function module:clone()
	return module.newFromInit(self:getInit())
end

export type init = {
	positive: boolean,
	num: number,
	mag: number,
	format: number,
}
export type BigNumLibrary = init & typeof(module)

return {
	newFromInit = module.newFromInit,
	new = module.new,
	FORMATS = FORMATS,
}
