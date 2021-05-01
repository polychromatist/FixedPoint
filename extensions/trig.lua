-- polychromatist

-- do not expect identities to hold perfectly.
-- at radix point 6, cos(a + b) = cos(a)cos(b) - sin(a)sin(b) has error on the order of 0.000100.
-- it could very well be that cos^2(x) + sin^2(x) = 1.000100 . ( note: i have not checked! )

-- one thing to know: to get an accurate desired radian value, it is best not to multiply portions of pi--rather, use TAU directly.
-- that is, instead of:
-- three_thirds_pi = 3 * fix.CONSTANT.HALFPI
-- you should instead write:
-- three_thirds_pi = fix:div(3 * fix.CONSTANT.TAU, fix:convertInt(4))
-- OR
-- three_thirds_pi = fix:rad(fix:convertInt(270))
-- when you divide the larger value, you get an extraneous fractional value that can be used to round toward the most correct
-- representation of the smaller value possible. this value is missing when you multiply a smaller portion.

local function floor(fix, raw)
	return raw - (raw % fix.RADIX_RHS_VAL)
end

local max, min = math.max, math.min

return {
	rad = function(self, raw)
		return self:div(self:mult(raw % self.CONSTANT.DEGR, self.CONSTANT.TAU), self.CONSTANT.DEGR)
	end,
	deg = function(self, raw)
		return self:div(self:mult(raw % self.CONSTANT.TAU, self.CONSTANT.DEGR), self.CONSTANT.TAU)
	end,
	sin = function(self, raw)
		-- sine, -pi/4 <= x <= pi/4: 0.999995x - 0.1666016x^3 + 0.0081215x^5    --   due to chebyshev
		-- cosine, -pi/4 <= x <= pi/4: 0.999995 - 0.4998048x^2 + 0.0406075x^4   --   d/dx
		-- => sine, pi/4 <= x <= pi/2: cos(pi/2 - x)                            --   second octant wrt x-axis (sin) -> first octant wrt y-axis (cos)
		raw = raw % self.CONSTANT.TAU
		
		local positive = true
		
		if raw >= self.CONSTANT.PI then
			raw = raw - self.CONSTANT.PI
			positive = false
		end
		
		if raw > self.CONSTANT.HALFPI then
			raw = self.CONSTANT.PI - raw
		elseif raw == self.CONSTANT.HALFPI then
			return positive and self.RADIX_RHS_VAL or -self.RADIX_RHS_VAL 
		end
		
		local x, xsq
		local result
		if raw <= self.CONSTANT.FOURTHPI then
			x = raw
			xsq = self:mult(x, x, "HALF_TO_EVEN")
			local xcu = self:mult(xsq, x, "HALF_TO_EVEN")
			result = 9999950 * x - 1666016 * xcu + 81215 * self:mult(xcu, xsq, "HALF_TO_EVEN")
		else
			x = self.CONSTANT.HALFPI - raw
			xsq = self:mult(x, x, "HALF_TO_EVEN")
			result = 9999950 * self.RADIX_RHS_VAL - 4998048 * xsq + 406075 * self:mult(xsq, xsq, "HALF_TO_EVEN")
		end
		
		result = self:roundAt(result, 7, "HALF_TO_EVEN") / 1e7
		
		return positive and result or -result
	end,
	cos = function(self, raw)
		return self:sin(self.CONSTANT.HALFPI - raw)
	end,
	tan = function(self, raw)
		return self:div(self:sin(raw), self:cos(raw))
	end,
	cot = function(self, raw)
		return self:div(self:cos(raw), self:sin(raw))
	end,
	sec = function(self, raw)
		return self:div(self.RADIX_RHS_VAL, self:cos(raw))
	end,
	csc = function(self, raw)
		return self:div(self.RADIX_RHS_VAL, self:sin(raw))
	end,
	atan2 = function(self, y, x)
		self.class.static.assert_int("y", y)
		self.class.static.assert_int("x", x)
		
		if y == 0 then
			local result = (x < 0 or (x == 0 and 1 / x == -math.huge)) and self.CONSTANT.PI or 0
			return 1 / y == -math.huge and -result or result
		elseif x == 0  then
			return y < 0 and -self.CONSTANT.HALFPI or -self.CONSTANT.HALFPI
		end
		
		-- https://math.stackexchange.com/questions/1098487/atan2-faster-approximation
		--[=[
			a := min (|x|, |y|) / max (|x|, |y|)
			s := a * a
			r := ((-0.0464964749 * s + 0.15931422) * s - 0.327622764) * s * a + a
			if |y| > |x| then r := 1.57079637 - r
			if x < 0 then r := 3.14159274 - r
			if y < 0 then r := -r
		--]=]
		local ONE = self.RADIX_RHS_VAL
		
		local absx = x > 0 and x or -x
		local absy = y > 0 and y or -y
		
		local a = self:div(min(absx, absy), max(absx, absy), "HALF_TO_EVEN")
		local s = self:mult(a, a, "HALF_TO_EVEN")
		local c = self:mult(s, a, "HALF_TO_EVEN")
		
		local r = self:roundAt(-46496475 * s + 159314220 * ONE, 9, "HALF_TO_EVEN") / 1e9
		r = self:mult(self:mult(r, s, "HALF_TO_EVEN") - self._INTERNALS.ATAN_TERM1, c, "HALF_TO_EVEN") + a
		if (absy > absx) then
			r = self.CONSTANT.HALFPI - r
		end
		if x < 0 then
			r = self.CONSTANT.PI - r
		end
		return y >= 0 and r or -r
	end,
	atan = function(self, raw)
		return self:atan2(raw, self.RADIX_RHS_VAL)
	end,
	acos = function(self, raw)
		local ONE = self.RADIX_RHS_VAL
		
		if raw < -ONE or raw > ONE then
			error("FixedPoint: arccosine or arcsine out of bounds error. op1: " .. self:toString(raw))
		elseif raw == -ONE then
			return self.CONSTANT.PI
		elseif raw == ONE then
			return 0
		elseif raw == 0 then
			return self.CONSTANT.HALFPI
		end
		
		local result = self:atan2(self:sqrt(ONE - self:mult(raw, raw, "HALF_TO_EVEN")), raw)
		
		return result
	end,
	asin = function(self, raw)
		-- asin(x) = pi/2 - acos(x)
		return self.CONSTANT.HALFPI - self:acos(raw)
	end,
	-- the following functions require exponentation: sinh, cosh, tanh, asinh, acosh, atanh
	sinh = function(self, raw, policy, ignoreOverflow)
		if ignoreOverflow == nil then
			ignoreOverflow = self.class.static.IGN_OVF
		end
		self.class.static.assert_int("raw", raw)
		assert(self.exp ~= "nil", "FixedPoint: hyperbolic functions require the exponentiation library")
		
		policy = policy or "HALF_TO_EVEN"
		
		local exp = self:exp(raw, policy, true)
		local inv_exp = self:exp(-raw, policy, true)
		if not ignoreOverflow and (exp > 9e15 or inv_exp > 9e15) then
			error("FixedPoint: OVERFLOW (hyperbolic sine). op1: " .. self:toString(raw))
		end
		local result = self:mult(exp - inv_exp, self.CONSTANT.HALF, policy, true)
		
		if not ignoreOverflow and self:chk_overflow(result) then
			error("FixedPoint: OVERFLOW (hyperbolic sine). op1: " .. self:toString(raw))
		end
		
		return result
	end,
	cosh = function(self, raw, policy, ignoreOverflow)
		if ignoreOverflow == nil then
			ignoreOverflow = self.class.static.IGN_OVF
		end
		self.class.static.assert_int("raw", raw)
		assert(self.exp ~= "nil", "FixedPoint: hyperbolic functions require the exponentiation library")
		
		policy = policy or "HALF_TO_EVEN"
		
		local exp = self:exp(raw, policy, true)
		local inv_exp = self:exp(-raw, policy, true)
		if not ignoreOverflow and (exp > 9e15 or inv_exp > 9e15) then
			error("FixedPoint: OVERFLOW (hyperbolic cosine). op1: " .. self:toString(raw))
		end
		local result = self:mult(exp + inv_exp, self.CONSTANT.HALF, policy, true)
		
		if not ignoreOverflow and self:chk_overflow(result) then
			error("FixedPoint: OVERFLOW (hyperbolic cosine). op1: " .. self:toString(raw))
		end
		
		return result
	end,
	tanh = function(self, raw, policy, ignoreOverflow)
		if ignoreOverflow == nil then
			ignoreOverflow = self.class.static.IGN_OVF
		end
		self.class.static.assert_int("raw", raw)
		assert(self.exp ~= "nil", "FixedPoint: hyperbolic functions require the exponentiation library")
		if (raw == math.huge) then
			return 1
		elseif (raw == -math.huge) then
			return -1
		elseif raw ~= raw then
			return 0/0
		end
		
		policy = policy or "HALF_TO_EVEN"
		
		local exp = self:exp(raw, policy, true)
		local inv_exp = self:exp(-raw, policy, true)
		if not ignoreOverflow and (exp > 9e15 or inv_exp > 9e15) then
			error("FixedPoint: OVERFLOW (hyperbolic tangent). op1: " .. self:toString(raw))
		end
		local result = self:div(exp - inv_exp, exp + inv_exp, policy, true)
		
		if not ignoreOverflow and self:chk_overflow(result) then
			error("FixedPoint: OVERFLOW (hyperbolic tangent). op1: " .. self:toString(raw))
		end
		
		return result
	end,
}