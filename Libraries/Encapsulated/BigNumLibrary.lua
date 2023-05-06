local module: BigNumLibrary = {}
module.__index = module

local FORMATS = {
	SCIENTIFIC = 0,
	ABBREVIATION = 1,
}

function module:__tostring()
	local str = self.positive and "" or "-"
	if -4 < self.mag and self.mag < 0 then
		return str .. string.format("%.3f", self.num * 10 ^ self.mag)
	elseif self.mag < 4 then
		return str .. string.format("%d", self.num * 10 ^ self.mag)
	elseif self.format == FORMATS.SCIENTIFIC then
		return str .. string.format("%.2fe%d", self.num, self.mag)
	end
	return str
end

function module:__unm()
	local new = self:clone()
	new.positive = not new.positive
	return new
end

function module:abs()
	local new = self:clone()
	new.positive = true
	return new
end

function module:__add(o: BigNumLibrary)
	if self < o then
		return o + self
	end
	-- self is bigger
	if math.abs(self.mag - o.mag) > 10 then
		return self
	end
	if self.positive and o.positive then
		local new = self:clone()
		local diffMag = self.mag - o.mag
		local oNum = o.num / 10 ^ diffMag
		new.num += oNum
		return new:goToStandard()
	elseif not self.positive and not self.positive then
		return -(-self + -o)
	else
		-- self and -o
		if self:abs() > o:abs() then
			local new = self:clone()
			local diffMag = self.mag - o.mag
			local oNum = o.num / 10 ^ diffMag
			new.num -= oNum
			return new:goToStandard()
		else
			return -(-o - self)
		end
	end
end

function module:__sub(o: BigNumLibrary)
	return self + -o
end

function module:__lt(o: BigNumLibrary)
	if self.positive and not o.positive then
		return false
	elseif not self.positive and o.positive then
		return true
	elseif self.positive and o.positive then
		if self.mag < o.mag then
			return true
		elseif self.mag > o.mag then
			return false
		end
		if self.num < o.num then
			return true
		elseif self.num > o.num then
			return false
		end
		-- Equal
		return false
	elseif not self.positive and not o.positive then
		return -o < -self
	end
end

function module:__le(o: BigNumLibrary)
	return self == o or self < o
end

function module:__eq(o: BigNumLibrary)
	return self.positive == o.positive and self.num == o.num and self.mag == o.mag
end

function module:__mul(o: BigNumLibrary)
	if (self.positive and not o.positive) or (not self.positive and o.positive) then
		return -(self:abs() * o:abs())
	end
	return module.new(true, self.num * o.num, self.mag + o.mag, self.format):goToStandard()
end

function module:goToStandard()
	while self.num >= 10 do
		self.num /= 10
		self.mag += 1
	end
	while self.num < 1 do
		self.num *= 10
		self.mag -= 1
	end
	return self
end

function module:__div(o: BigNumLibrary)
	if o.num == 0 then
		error("Cannot divide by 0")
	end
	if (self.positive and not o.positive) or (not self.positive and o.positive) then
		return -(self:abs() / o:abs())
	end
	return module.new(true, self.num / o.num, self.mag - o.mag, self.format):goToStandard()
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

function module.newFromNum(num: number)
	local pos = num >= 0 and true or false
	local log10 = math.log10(math.abs(num))
	local num = 10 ^ (log10 % 1)
	local mag = math.floor(log10)
	return module.new(pos, num, mag)
end

function module:log10()
	return self:pos() * math.log10(self.num) + self.mag
end

function module:pos()
	return (self.positive and 1 or -1)
end

function module:isZero()
	return self.num == 0
end

function module.newFromInit(params: init): BigNumLibrary
	local self: init = {
		positive = params.positive,
		num = params.num or 0,
		mag = params.mag or 0,
		format = params.format or FORMATS.SCIENTIFIC,
	}
	if self.positive == nil then
		self.positive = true
	end
	setmetatable(self, module)
	return self:goToStandard()
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
	newFromNum = module.newFromNum,
	FORMATS = FORMATS,
}
