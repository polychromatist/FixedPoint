-- this is very accurate approx of 2^x on the interval 0 < x < 1
-- from http://mathworld.wolfram.com/PadeApproximant.html, [3/3] Padé approximant of exp
-- note x is 6 digits at most, so multiplying directly is OK
-- error is most as x approaches 1
local function pade_exp(self, x)
	-- note 69314718 represents ln(2)
	x = x * 69314718
	x = self:roundAt(x, 8, "HALF_TO_EVEN") / 1e8
	
	local xsq = self:mult(x, x, "HALF_TO_EVEN")
	local xcu = self:mult(x, xsq, "HALF_TO_EVEN")
	
	local cterm1 = 120 * self.RADIX_RHS_VAL + 12 * xsq
	local cterm2 = 60 * x + xcu

	return self:div(cterm1 + cterm2, cterm1 - cterm2, "HALF_TO_EVEN")
end

-- same above for lg(x) on the interval 1/2 < x < 2
-- error is most as x approaches 2
local function pade_lg(self, x)
	-- f(x) = (x + (3/2) * x ^ 2 + (13/21) * x ^ 3 + (5/84) * x ^ 4) / (1 + 2x + (9/7) * x ^ 2 + (2/7) * x ^ 3 + (1 / 70) * x ^ 4)
	-- above is ln(1 + x) Pade approximant [4/4].
	-- result is f(x - 1) / ln(2)
	local ONE = self.RADIX_RHS_VAL
	
	x = x - ONE
	local xsq = self:mult(x, x, "HALF_TO_EVEN")
	local xcu = self:mult(xsq, x, "HALF_TO_EVEN")
	local xsqsq = self:mult(xsq, xsq, "HALF_TO_EVEN")
	
	local P = (126 * xsq + 52 * xcu + 5 * xsqsq)
	--P = x + (P - (P % 84)) / 84
	P = x + self:div(P, self._INTERNALS.EIGHTYFOUR, "HALF_TO_EVEN")
	
	local Q = (140 * x + 90 * xsq + 20 * xcu + xsqsq)
	--Q = ONE + (Q - (Q % 70)) / 70
	Q = ONE + self:div(Q, self._INTERNALS.SEVENTY, "HALF_TO_EVEN")
	
	--print(P, Q)
	local r = 144269504 * self:div(P, Q, "HALF_TO_EVEN")
	--local r = P * ONE
	--r = 144269504 * ((r - (r % Q)) / Q)
	
	return self:roundAt(r, 8, "HALF_TO_EVEN") / 1e8
end

local abs = math.abs
local sign = math.sign
if not sign then
   sign = function(x)
      return x > 0 and 1 or x < 0 and -1 or 0
   end
end

-- there are multiple places which a rounding policy can be applied, which may cause disparity between any one choice
-- fractional exponential/logarithm approximations use HALF_TO_EVEN under the hood for unbiased rounding
return {
	-- m * 2^raw
	-- if m is nil, this is the power of two function
	ldexp = function(self, m, raw, policy, ignoreOverflow)
		if not ignoreOverflow then
			ignoreOverflow = self.class.static.IGN_OVF
		end
		self.class.static.assert_int("raw", raw)
		
		if m == 0 then
			return 0
		end
		
		local exp1 = raw % self.RADIX_RHS_VAL
		local exp0 = (raw - exp1) / self.RADIX_RHS_VAL
		
		local result = 0
		
		if exp0 < -24 then
			return 0
		elseif exp0 < 0 then
			result = self:div(self.RADIX_RHS_VAL, 2^(-exp0) * self.RADIX_RHS_VAL, policy)
		else
			result = 2^exp0 * self.RADIX_RHS_VAL
		end
		
		if exp1 ~= 0 then
			result = self:mult(result, pade_exp(self, exp1), policy, true)
		end
		
		if m ~= nil then
			result = self:mult(m, result, policy, true)
		end
		
		if not ignoreOverflow and self:chk_overflow(result) then
			error("FixedPoint: OVERFLOW (exponentiation/ldexp). m: " .. self:toString(m or self.RADIX_RHS_VAL) .. " exp: " .. self:toString(raw))
		end
		
		return result
	end,
	-- binary logarithm
	lg = function(self, raw)
		self.class.static.assert_int("raw", raw)
		
		local ONE = self.RADIX_RHS_VAL
		local HALF = self.CONSTANT.HALF
		
		if raw == self.CONSTANT.E then
			return self._INTERNALS.RECIP_LN2
		end
		
		local result = 0
		if raw < 0 then
			return 0/0
		elseif raw == 0 then
			return -math.huge
		elseif raw == ONE then
			return 0
		elseif raw < ONE then
			while raw <= HALF do
				result = result - 1
				raw = raw * 2
			end
			result = result * ONE
			if raw == ONE then
				return result
			else
				return result + pade_lg(self, raw)
			end
		end
		
		local POWER_LOOKUP = self.LOOKUP.POWERS_OF_TWO_SCALED_ONE
	
		local rawrepl0 = ONE
		local rawrepl1 = POWER_LOOKUP[3]
		while raw >= rawrepl1 do
			result = result + 3
			rawrepl0 = rawrepl1
			rawrepl1 = POWER_LOOKUP[result + 3]
		end
		rawrepl1 = POWER_LOOKUP[result + 1]
		while raw >= rawrepl1 do
			result = result + 1
			rawrepl0 = rawrepl1
			rawrepl1 = POWER_LOOKUP[result + 1]
		end
		result = result * ONE
		if raw == rawrepl0 then
			return result
		end
		local rawreplratio = self:div(raw, rawrepl0, "HALF_TO_EVEN")
		return result + pade_lg(self, rawreplratio)
	end,
	-- given a floating point value, this returns two values m, e such that fix:ldexp(m, e) is about equal to raw
	-- similar to binary log, but neglects use of any pade approximant
	frexp = function(self, raw)
		self.class.static.assert_int("raw", raw)
		
		local ONE = self.RADIX_RHS_VAL
		
		local absraw = raw >= 0 and raw or -raw
		if raw == 0 then
			return 0, 0
		elseif raw ~= raw then
			return 0/0, -ONE
		elseif absraw == math.huge then
			return raw, -ONE
		end
		
		local HALF = self.CONSTANT.HALF
		
		if raw == self.CONSTANT.E then
			return self._INTERNALS.RECIP_LN2
		end
		
		local result = 0
		
		if absraw < ONE then
			while absraw <= HALF do
				result = result - 1
				absraw = absraw * 2
			end
			result = result * ONE
			return sign(raw) * absraw, result
		end
		
		local POWER_LOOKUP = self.LOOKUP.POWERS_OF_TWO_SCALED_ONE
	
		local rawrepl0 = ONE
		local rawrepl1 = POWER_LOOKUP[3]
		while absraw >= rawrepl1 do
			result = result + 3
			rawrepl0 = rawrepl1
			rawrepl1 = POWER_LOOKUP[result + 3]
		end
		rawrepl1 = POWER_LOOKUP[result + 1]
		while absraw >= rawrepl1 do
			result = result + 1
			rawrepl0 = rawrepl1
			rawrepl1 = POWER_LOOKUP[result + 1]
		end
		result = result * ONE
		if absraw == rawrepl0 then
			return ONE, result
		end
		local rawreplratio = self:div(rawrepl1, raw, "HALF_TO_EVEN")
		return rawreplratio, result + 1
	end,
	-- generic exponential/power function
	-- i compute a^b = 2^(lg(a)*b), where lg is log base 2
	pow = function(self, raw1, raw2, policy, ignoreOverflow)
		if ignoreOverflow == nil then
			ignoreOverflow = self.class.static.IGN_OVF
		end
		self.class.static.assert_int("raw1", raw1)
		self.class.static.assert_int("raw2", raw2)
		
		local ONE = self.RADIX_RHS_VAL
		
		local exp1 = raw2 % ONE
		local raw1_int = raw1 - (raw1 % ONE)
		
		local result
		if raw2 == 0 or raw1 == ONE then
			return ONE
		elseif raw1 == 0 then
			return raw2 == raw2 and 0 or 0/0
		elseif raw1 == -ONE then
			return raw2 % 2 == 1 and -ONE or ONE
		elseif raw1 < 0 and exp1 ~= 0 then
		-- this corresponds to a negative base risen to a power with nonzero fractional part
			return 0/0
		elseif exp1 == 0 and raw1 == raw1_int then
		-- integer power simplification
			if raw2 < 0 then
				result = self:div(ONE, ((raw1 / ONE)^(-raw2 / ONE)) * ONE, policy)
			else
				result = ((raw1 / ONE)^(raw2 / ONE)) * ONE
			end
		else
			local TWO = self.CONSTANT.TWO
			
			if raw1 == TWO or raw1 == -TWO then
				result = self:ldexp(nil, raw2, policy, true)
			else
				result = self:ldexp(nil, self:mult(self:lg(raw1 < 0 and -raw1 or raw1), raw2, policy, true), policy, true)
			end
			
			if raw1 < 0 and exp1 == 0 and raw2 % TWO == ONE then
				result = -result
			end
		end
		
		if not ignoreOverflow and self:chk_overflow(result) then
			error("FixedPoint: OVERFLOW (exponentiation/pow). op1: " .. self:toString(raw1) .. " op2: " .. self:toString(raw2))
		end
		
		return result
	end,
	-- log is ln if no base is provided, just as normal
	log = function(self, raw, base, policy, ignoreOverflow)
		if ignoreOverflow == nil then
			ignoreOverflow = self.class.static.IGN_OVF
		end
		self.class.static.assert_int("raw", raw)
		base = base or self.CONSTANT.E
		
		local result = self:div(self:lg(raw), self:lg(base), policy, true)
		
		if not ignoreOverflow and self:chk_overflow(result) then
			error("FixedPoint: OVERFLOW (logarithm). op1: " .. self:toString(raw) .. " base: " .. self:toString(base))
		end
		
		return result
	end,
	log10 = function(self, raw, policy, ignoreOverflow)
		return self:log(raw, self.CONSTANT.TEN, policy, ignoreOverflow)
	end,
	-- e^x, as normal
	exp = function(self, raw, policy, ignoreOverflow)
		if ignoreOverflow == nil then
			ignoreOverflow = self.class.static.IGN_OVF
		end
		self.class.static.assert_int("raw", raw)
		assert(raw < self._INTERNALS.EXP_OVF, "FixedPoint: chosen exponent may result in dangerous overflow. op1: " .. raw)
		
		if raw < self:convertInt(-17) then
			return 0
		end
		
		-- convert power of e to a power of two by multiplying the exponent by log_2(e)
		
		return self:ldexp(nil, self:roundAt(1442695 * raw, 6, policy) / 1e6, policy, ignoreOverflow)
	end,
}