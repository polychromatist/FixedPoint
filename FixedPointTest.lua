-- Roblox only
local FixedPoint = require(game:GetService("ReplicatedStorage").Physics.FixedPoint)

-- default rounding policy
local drp = "HALF_AWAY_FROM_ZERO"

local rng = Random.new()

local randfn = function(fix)
	return rng:NextInteger(-fix.OVERFLOW_VAL + 1, fix.OVERFLOW_VAL + 1)
end
local randfn2 = function(u, l)
	return rng:NextInteger(u, l)
end

-- changing radius below 7 will cause problems
local test_radius = 14
-- changing radix point will cause problems, because rounding testing is sort of embedded in other test contexts where it is used
-- this radix point is not always used, like for example in Trigonometry
local test_radix_point = 4

FixedPointTest = {
	Consistency = function()
		local fix = FixedPoint:new(test_radius, test_radix_point, drp)
		
		print("Test: convertInt has identity on zero")
		assert(fix:convertInt(0) == 0)
		print("Good")
	end,
	Addition = function()
		local fix = FixedPoint:new(test_radius, test_radix_point, drp)
		print("Fixed point context: " .. fix:describe())
		
		local ONE = fix:convertInt(1)
		local BIG = fix.OVERFLOW_VAL - 1
		local BIG_n = -fix.OVERFLOW_VAL + 1
		local ONE_n = fix:convertInt(-1)
		local TWO = fix:convertInt(2)
		local FOUR = fix:convertInt(4)
		local HUNDRED = fix:convertInt(100)
		local ZERO = fix:convertInt(0)
		local RAND1, RAND2, RAND3 = fix:genRand(randfn) % fix.RADIX_RHS_VAL, fix:genRand(randfn) % fix.RADIX_RHS_VAL, math.fmod(fix:genRand(randfn), fix.RADIX_RHS_VAL)
		
		local function str(v)
			return fix:toString(v)
		end
		
		
		print("Test: one plus one")
		
		local result1 = fix:add(ONE, ONE)
		print(str(ONE) .. " + " .. str(ONE) .. " = " .. str(result1))
		assert(result1 == TWO)
		print("Good")
		
		
		print("Test: one plus negative one")
		
		local result2 = fix:add(ONE, ONE_n)
		print(str(ONE) .. " + (" .. str(ONE_n) ..") = ".. str(result2))
		assert(result2 == ZERO)
		print("Good")
		
		
		print("Test: overflow error")
		
		print("Attempting: " .. str(BIG) .. " + " .. str(ONE))
		assert(not pcall(function()
			print(fix:toString(fix:add(BIG, ONE)))
		end))
		print("Good")
		
		print("Attempting: (" .. str(BIG_n) .. ") + (".. str(ONE_n) .. ")")
		assert(not pcall(function()
			fix:add(BIG_n, ONE_n)
		end))
		print("Good")
		
		
		print("Test: associativity")
		
		print("Attempting simple check.")
		local result3_1 = fix:add(fix:add(ONE, TWO), ONE)
		print(str(ONE) .. " + ( " .. str(TWO) .. " + " .. str(ONE) .. " ) = " .. str(result3_1))
		
		local result3_2 = fix:add(ONE, fix:add(TWO, ONE))
		print("( " .. str(ONE) .. " + " .. str(TWO) .. " ) + " .. str(ONE) .. " = " .. str(result3_2))
		
		assert(result3_1 == result3_2)
		assert(result3_1 == FOUR)
		print("Good")
		
		print("Attempting randomized check.")
		local result3_3 = fix:add(fix:add(RAND1, RAND2), RAND3)
		print(str(RAND1) .. " + ( " .. str(RAND2) .. " + " .. str(RAND3) .. " ) = " .. str(result3_3))
		
		local result3_4 = fix:add(RAND1, fix:add(RAND2, RAND3))
		print("( " .. str(RAND1) .. " + " .. str(RAND2) .. " ) + " .. str(RAND3) .. " = " .. str(result3_4))
		
		assert(result3_3 == result3_4)
		print("Good")
		
		print("Test: iterated addition")
		local N = ZERO
		for i = 1, 100 do
			N = fix:add(N, ONE)
		end
		assert(N == HUNDRED)
		print("Good")
	end,
	Subtraction = function()
		local fix = FixedPoint:new(test_radius, 4, drp)
		print("Fixed point context: " .. fix:describe())
		
		local ONE = fix:convertInt(1)
		local BIG = fix.OVERFLOW_VAL - 1
		local BIG_n = -fix.OVERFLOW_VAL + 1
		local ONE_n = fix:convertInt(-1)
		local TWO = fix:convertInt(2)
		local FOUR = fix:convertInt(4)
		local HUNDRED = fix:convertInt(100)
		local ZERO = fix:convertInt(0)
		
		local function str(v)
			return fix:toString(v)
		end
		
		
		print("Test: one minus one")
		
		local result1 = fix:sub(ONE, ONE)
		print(str(ONE) .. " - " .. str(ONE) .. " = " .. str(result1))
		assert(result1 == ZERO)
		print("Good")
		
		
		print("Test: one minus negative one")
		
		local result2 = fix:sub(ONE, ONE_n)
		print(str(ONE) .. " - (" .. str(ONE_n) ..") = ".. str(result2))
		assert(result2 == TWO)
		print("Good")
		
		
		print("Test: overflow error")
		
		print("Attempting: " .. str(BIG_n) .. " - " .. str(ONE))
		assert(not pcall(function()
			print(fix:toString(fix:sub(BIG_n, ONE)))
		end))
		print("Good")
		
		print("Attempting: (" .. str(BIG) .. ") - (".. str(ONE_n) .. ")")
		assert(not pcall(function()
			fix:sub(BIG, ONE_n)
		end))
		print("Good")
		
		
		print("Test: non-associativity")
		
		print("Attempting simple check.")
		local result3_1 = fix:sub(fix:sub(ONE, TWO), ONE)
		print("( " .. str(ONE) .. " - " .. str(TWO) .. " ) - " .. str(ONE) .. " = " .. str(result3_1))
		
		local result3_2 = fix:sub(ONE, fix:sub(TWO, ONE))
		print(str(ONE) .. " - ( " .. str(TWO) .. " - " .. str(ONE) .. " ) = " .. str(result3_2))
		
		assert(result3_1 ~= result3_2)
		assert(result3_1 == -TWO)
		assert(result3_2 == ZERO)
		print("Good")
		
		print("Test: iterated subtraction")
		local N = ZERO
		for i = 1, 100 do
			N = fix:sub(N, ONE)
		end
		assert(N == -HUNDRED)
		print("Good")
	end,
	Multiplication = function()
		local fix = FixedPoint:new(test_radius, test_radix_point, drp)
		print("Fixed point context: " .. fix:describe())
		
		local ONE = fix:convertInt(1)
		local OVF_TENTH = fix.OVERFLOW_VAL / 10
		local ONE_n = fix:convertInt(-1)
		local TWO = fix:convertInt(2)
		local FOUR = fix:convertInt(4)
		local HUNDRED = fix:convertInt(100)
		local ZERO = fix:convertInt(0)
		local HALF = fix.RADIX_RHS_VAL / 2
		local THREE_HALFS = fix:add(ONE, HALF)
		local THREE_FOURTHS = THREE_HALFS / 2
		local HUNDREDTH = fix.RADIX_RHS_VAL / 100
		local TENTHOUSANDTH = fix.RADIX_RHS_VAL / 10000
		local NINE = fix:convertInt(9)
		local RAND1, RAND2, RAND3 = fix:genRand(randfn) % fix.RADIX_RHS_VAL, fix:genRand(randfn) % fix.RADIX_RHS_VAL, math.fmod(fix:genRand(randfn), fix.RADIX_RHS_VAL)
		
		local function str(v)
			return fix:toString(v)
		end
		
		print("Test: one times one")
		local result1 = fix:mult(ONE, ONE)
		print(str(ONE) .. " * " .. str(ONE) .. " = " .. str(result1))
		assert(result1 == ONE)
		print("Good")
		
		print("Test: one times negative one")
		local result2 = fix:mult(ONE, ONE_n)
		print(str(ONE) .. " * ( " .. str(ONE_n) .. " ) = " .. str(result2))
		assert(result2 == ONE_n)
		print("Good")
		
		print("Test: negative one times negative one")
		local result3 = fix:mult(ONE_n, ONE_n)
		print("( ".. str(ONE_n) .. " ) * ( " .. str(ONE_n) .. " ) = " .. str(result3))
		assert(result3 == ONE)
		print("Good")
		
		print("Test: one times a half")
		local result4 = fix:mult(ONE, HALF)
		print(str(ONE) .. " * " .. str(HALF) .. " = " .. str(result4))
		assert(result4 == HALF)
		print("Good")
		
		print("Test: one point five times a half")
		local result5 = fix:mult(THREE_HALFS, HALF)
		print(str(THREE_HALFS) .. " * " .. str(HALF) .. " = " .. str(result5))
		assert(result5 == THREE_FOURTHS)
		print("Good")
		
		print("Test: a hundredth times a hundredth")
		local result6 = fix:mult(HUNDREDTH, HUNDREDTH)
		print(str(HUNDREDTH) .. " * " .. str(HUNDREDTH) .. " = " .. str(result6))
		assert(result6 == TENTHOUSANDTH)
		print("Good")
		
		print("Test: a negative tenthousandth times a half with HALF_AWAY_FROM_ZERO rounding policy")
		local result7 = fix:mult(-TENTHOUSANDTH, HALF)
		print(str(-TENTHOUSANDTH) .. " * " .. str(HALF) .. " = " .. str(result7))
		assert(result7 == -TENTHOUSANDTH)
		print("Good")
		
		print("Test: a negative tenthousandth times a half with HALF_UP rounding policy")
		local result8 = fix:mult(-TENTHOUSANDTH, HALF, "HALF_UP")
		print(str(-TENTHOUSANDTH) .. " * " .. str(HALF) .. " = " .. str(result8))
		assert(result8 == ZERO)
		print("Good")
		
		print("Test: a negative tenthousandth times a negative half with HALF_UP rounding policy")
		local result9 = fix:mult(-TENTHOUSANDTH, -HALF, "HALF_UP")
		print(str(-TENTHOUSANDTH) .. " * " .. str(-HALF) .. " = " .. str(result9))
		assert(result9 == TENTHOUSANDTH)
		print("Good")
		
		print("Test: three tenthousandths times a half with HALF_TO_EVEN rounding policy")
		local result10 = fix:mult(3 * TENTHOUSANDTH, HALF, "HALF_TO_EVEN")
		print(str(3 * TENTHOUSANDTH) .. " * " .. str(HALF) .. " = " .. str(result10))
		assert(result10 == 2 * TENTHOUSANDTH)
		print("Good")
		
		print("Test: five tenthousandths times a half with HALF_TO_EVEN rounding policy")
		local result10 = fix:mult(5 * TENTHOUSANDTH, HALF, "HALF_TO_EVEN")
		print(str(5 * TENTHOUSANDTH) .. " * " .. str(HALF) .. " = " .. str(result10))
		assert(result10 == 2 * TENTHOUSANDTH)
		print("Good")
		
		print("Test: tenth of overflow value times nine")
		local result11 = fix:mult(OVF_TENTH, NINE)
		print(str(OVF_TENTH) .. " * " .. str(NINE) .. " = " .. str(result11))
		assert(result11 == 9 * OVF_TENTH)
		print("Good")
		
		print("Test: tenth of overflow and tenthousandth times nine and hundredth with default policy")
		local result12 = fix:mult(OVF_TENTH+TENTHOUSANDTH, NINE+HUNDREDTH)
		print(str(OVF_TENTH+TENTHOUSANDTH) .. " * " .. str(NINE+HUNDREDTH) .. " = " .. str(result12))
		assert(result12 == 90100000000009)
		print("Good")
		
		print("Test: tenth of overflow and tenthousandth times nine and hundredth with NEXT_INT policy")
		local result12 = fix:mult(OVF_TENTH+TENTHOUSANDTH, NINE+HUNDREDTH, "NEXT_INT")
		print(str(OVF_TENTH+TENTHOUSANDTH) .. " * " .. str(NINE+HUNDREDTH) .. " = " .. str(result12))
		assert(result12 == 90100000000010)
		print("Good")
		
		print("Test: overflow error")
		
		print("Attempting: tenth of overflow times ten")
		assert(not pcall(function()
			fix:mult(OVF_TENTH, NINE+ONE)
		end))
		print("Good")
		
		print("Attempting: negative tenth of overflow times ten")
		assert(not pcall(function()
			fix:mult(-OVF_TENTH, NINE+ONE)
		end))
		print("Good")
		
		print("Attempting: overflow times a half")
		assert(not pcall(function()
			fix:mult(fix.OVERFLOW_VAL, HALF)
		end))
		print("Good")
		
		print("Test: near-associativity")
		
		print("Attempting: associativity margin check with random fractional numbers using HALF_TO_EVEN")
		local result13_1 = fix:mult(fix:mult(RAND1, RAND2, "HALF_TO_EVEN"), RAND3, "HALF_TO_EVEN")
		local result13_2 = fix:mult(RAND1, fix:mult(RAND2, RAND3, "HALF_TO_EVEN"), "HALF_TO_EVEN")
		print("( " .. str(RAND1) .. " * " .. str(RAND2) .. " ) * " .. str(RAND3) .. " = " .. str(result13_1))
		print(str(RAND1) .. " * ( " .. str(RAND2) .. " * " .. str(RAND3) .. " ) = " .. str(result13_2))
		print(">>> the associativity margin is " .. (result13_1 - result13_2))
		assert(math.abs(result13_1 - result13_2) < 10)
		print("Good")
		
		print("Test: iterated multiplication")
		local N = 1
		local I = 0
		for i = 1, 100 do
			N = fix:mult(N, ONE)
		end
		assert(N == 1)
		while N < OVF_TENTH do
			N = fix:mult(N, TWO)
			I = I + 1
		end
		print("N began at "..str(1).." and became " .. str(N) .. " after " .. I .. " iterated multiplications by 2")
		assert(N == 2^44)
		print("Good")
		
		print("Test: near-distributivity")
		
		print("Attempting: distributivity margin check with random fractional numbers using HALF_TO_EVEN")
		local result14_1 = fix:mult(RAND1, fix:add(RAND2, RAND3), "HALF_TO_EVEN")
		local result14_2 = fix:add(fix:mult(RAND1, RAND2, "HALF_TO_EVEN"), fix:mult(RAND1, RAND3, "HALF_TO_EVEN"))
		print(str(RAND1) .. " * ( " ..str(RAND2) .. " + " .. str(RAND3) .. " ) = " .. str(result14_1))
		print("( " .. str(RAND1) .. " * " .. str(RAND2) .. " ) + ( " .. str(RAND1) .. " * " .. str(RAND3) .. " ) = " .. str(result14_2))
		print(">>> the distributivity margin is " .. (result14_1 - result14_2))
		assert(math.abs(result14_1 - result14_2) < 10)
		print("Good")
		
		print("Test: edge cases")
		
		print("Attempting: 0002069999.9999 * 0000001990.9999")
		local EDGE1_1 = fix:asValue(2069999, 999900)
		local EDGE1_2 = fix:asValue(1990, 999900)
		local result15 = fix:mult(EDGE1_1, EDGE1_2)
		print(str(EDGE1_1) .. " * " .. str(EDGE1_2) .. " = " .. str(result15))
		assert(result15 == fix:asValue(4121369792, 800900))
		print("Good")
		
		print("Test: multOvf")
		
		local fix9_3 = FixedPoint:new(9, 3, drp)
		print("Notice: Switching fixed point context to " .. fix9_3:describe())
		
		print("Attempting: overmultiply two large numbers in radius 9 radix 3")
		local r16op1 = fix9_3:asValue(123456, 789000)
		local r16op2 = fix9_3:asValue(987654, 321000)
		local result16 = fix9_3:multOvf(r16op1, r16op2)
		print("multOvf( " .. fix9_3:toString(r16op1) .. " , " .. fix9_3:toString(r16op2) .. " ) = " .. fix9_3:toString(result16))
		assert(result16 == fix9_3:asValue(121932, 631000))
		print("Good")
		
		local fix14_6 = FixedPoint:new(14, 6, drp)
		print("Notice: Switching fixed point context to " .. fix14_6:describe())
		
		print("Attempting: overmultiply two large numbers in radius 14 radix 6")
		local r17op1 = fix14_6:asValue(12345678, 901234)
		local r17op2 = fix14_6:asValue(98765432, 109876)
		local result17 = fix14_6:multOvf(r17op1, r17op2)
		print("multOvf( " .. fix14_6:toString(r17op1) .. " , " .. fix14_6:toString(r17op2) .. " ) = " .. fix14_6:toString(result17))
		assert(result17 == fix14_6:asValue(12193263, 113701))
		print("Good")
		
		print("Attempting: overmultiply near-overflow and one")
		local r18op1 = fix14_6.OVERFLOW_VAL - 1
		local r18op2 = fix14_6.RADIX_RHS_VAL
		local result18 = fix14_6:multOvf(r18op1, r18op2)
		print("multOvf( " .. fix14_6:toString(r18op1) .." , " .. fix14_6:toString(r18op2) .. " ) = " .. fix14_6:toString(result18))
		assert(result18 == fix14_6.RADIX_RHS_VAL)
		print("Good")
	end,
	Division = function()
		local fix = FixedPoint:new(test_radius, test_radix_point, drp)
		print("Fixed point context: " .. fix:describe())
		
		local ONE = fix:convertInt(1)
		local OVF_TENTH = fix.OVERFLOW_VAL / 10
		local OVF_TENTHOUSANDTH = fix.OVERFLOW_VAL / 10000
		local ONE_n = fix:convertInt(-1)
		local TWO = fix:convertInt(2)
		local FOUR = fix:convertInt(4)
		local HUNDRED = fix:convertInt(100)
		local ZERO = fix:convertInt(0)
		local HALF = fix.RADIX_RHS_VAL / 2
		local THREE_HALFS = fix:add(ONE, HALF)
		local THREE_FOURTHS = THREE_HALFS / 2
		local TENTH = fix.RADIX_RHS_VAL / 10
		local HUNDREDTH = fix.RADIX_RHS_VAL / 100
		local TENTHOUSANDTH = fix.RADIX_RHS_VAL / 10000
		local NINE = fix:convertInt(9)
		local RAND1, RAND2, RAND3, RAND4 = math.fmod(fix:genRand(randfn), fix.RADIX_RHS_VAL * 10),
			math.fmod(fix:genRand(randfn), fix.RADIX_RHS_VAL * 10),
			math.fmod(fix:genRand(randfn), fix.RADIX_RHS_VAL * 10),
			math.fmod(fix:genRand(randfn), fix.RADIX_RHS_VAL * 10)
		local BIGRAND1, BIGRAND2 = (RAND1 + fix.RADIX_RHS_VAL) * 1000000, (RAND2 + fix.RADIX_RHS_VAL) * 1000000
		local SAFERAND3 = RAND3 + fix.RADIX_RHS_VAL
		
		local function str(v)
			return fix:toString(v)
		end
		
		print("Test: one by one")
		
		local result1 = fix:div(ONE, ONE)
		print(str(ONE) .. " / " .. str(ONE) .. " = " .. str(result1))
		assert(result1 == ONE)
		print("Good")
		
		print("Test: negative one by one")
		
		local result2 = fix:div(ONE_n, ONE)
		print(str(ONE_n) .. " / " .. str(ONE) .. " = " .. str(result2))
		assert(result2 == ONE_n)
		print("Good")
		
		print("Test: one by negative one")
		
		local result3 = fix:div(ONE, ONE_n)
		print(str(ONE) .. " / " .. str(ONE_n) .. " = " .. str(result3))
		assert(result3 == ONE_n)
		print("Good")
		
		print("Test: division by zero")
		
		print("Attempting: nonzero value by zero")
		local result4 = fix:div(ONE, ZERO)
		print(str(ONE) .. " / " .. str(ZERO) .. " = " .. str(result4))
		assert(result4 == math.huge)
		print("Good")
		
		print("Attempting: zero by zero")
		local result5 = fix:div(ZERO, ZERO)
		print(str(ZERO) .. " / " .. str(ZERO) .. " = " .. str(result5))
		assert(not (result5 < 0 or result5 >= 0))
		print("Good")
		
		print("Test: one by two")
		local result6 = fix:div(ONE, TWO)
		print(str(ONE) .. " / " .. str(TWO) .. " = " .. str(result6))
		assert(result6 == HALF)
		print("Good")
		
		print("Test: tenth of overflow by two")
		local result7 = fix:div(OVF_TENTH, TWO)
		print(str(OVF_TENTH) .. " / " .. str(TWO) .. " = " .. str(result7))
		assert(result7 == OVF_TENTH / 2)
		print("Good")
		
		print("Test: tenth of overflow by half")
		local result8 = fix:div(OVF_TENTH, HALF)
		print(str(OVF_TENTH) .. " / " .. str(HALF) .. " = " .. str(result8))
		assert(result8 == 2 * OVF_TENTH)
		print("Good")
		
		print("Test: overflow error")
		
		print("Attempting: tenth of overflow by tenth")
		assert(not pcall(function()
			fix:div(OVF_TENTH, TENTH)
		end))
		print("Good")
		
		print("Attempting: tenthousandth of overflow by tenthousandth")
		assert(not pcall(function()
			fix:div(OVF_TENTHOUSANDTH, TENTHOUSANDTH)
		end))
		print("Good")
		
		print("Attempting: tenth of overflow by negative hundredth")
		assert(not pcall(function()
			fix:div(OVF_TENTH, -HUNDREDTH)
		end))
		print("Good")
		--[=[
		print("Test: tenthousandth by ten with round policy NEXT_INT")
		local result10 = fix:div(TENTHOUSANDTH, NINE+ONE, "NEXT_INT")
		print(str(TENTHOUSANDTH) .. " / " .. str(NINE+ONE) .. " = " .. str(result10))
		assert(result10 == TENTHOUSANDTH)
		print("Good")
		print("Test: iterated division")
		
		local N = 2^40
		for i = 1, 100 do
			N = fix:div(N, ONE)
		end
		assert(N == 2^40)
		
		print("Attempting: N = 2^40. divide by two until N = 1, checking for 2^i == N")
		
		local I = 40
		while N > 1 do
			N = fix:div(N, TWO)
			I = I - 1
			assert(N == 2^I)
		end
		print("Good")
		]=]
		
		
		print("Test: near-distributivity")
		
		print("Attempting: like denominators, using small random values, with HALF_TO_EVEN policy")
		local result11_1 = fix:add(fix:div(RAND1, RAND3, "HALF_TO_EVEN"), fix:div(RAND2, RAND3, "HALF_TO_EVEN"))
		local result11_2 = fix:div(fix:add(RAND1, RAND2), RAND3, "HALF_TO_EVEN")
		print("( " .. str(RAND1) .. " / " .. str(RAND3) .. " ) + ( " .. str(RAND2) .. " / " .. str(RAND3) .. " ) = " .. str(result11_1))
		print("( " .. str(RAND1) .. " + " .. str(RAND2) .. " ) / " .. str(RAND3) .. " = " .. str(result11_2))
		print(">>> the distributivity margin is " .. (result11_1 - result11_2))
		assert(math.abs(result11_1 - result11_2) < 10)
		print("Good")
		
		print("Attempting: like denominators, using big numerator small denominator, with HALF_TO_EVEN policy")
		local result12_1 = fix:add(fix:div(BIGRAND1, SAFERAND3, "HALF_TO_EVEN"), fix:div(BIGRAND2, SAFERAND3, "HALF_TO_EVEN"))
		local result12_2 = fix:div(fix:add(BIGRAND1, BIGRAND2), SAFERAND3, "HALF_TO_EVEN")
		print("( " .. str(BIGRAND1) .. " / " .. str(SAFERAND3) .. " ) + ( " .. str(BIGRAND2) .. " / " .. str(SAFERAND3) .. " ) = " .. str(result12_1))
		print("( " .. str(BIGRAND1) .. " + " .. str(BIGRAND2) .. " ) / " .. str(SAFERAND3) .. " = " .. str(result12_2))
		print(">>> the distributivity margin is " .. (result12_1 - result12_2))
		assert(math.abs(result12_1 - result12_2) < 10)
		print("Good")
		
		print("Attempting: unlike denominators, using small random values, HALF_TO_EVEN policy")
		local result13_1 = fix:add(fix:div(RAND1, RAND3, "HALF_TO_EVEN"), fix:div(RAND2, RAND4, "HALF_TO_EVEN"))
		local result13_2 = fix:div(fix:add(
			fix:mult(RAND1, RAND4, "HALF_TO_EVEN"),
			fix:mult(RAND2, RAND3, "HALF_TO_EVEN")), fix:mult(RAND3, RAND4, "HALF_TO_EVEN"), "HALF_TO_EVEN")
		print("( " .. str(RAND1) .. " / " .. str(RAND3) .. " ) + ( " .. str(RAND2) .. " / " ..str(RAND4) .. " ) = " .. str(result13_1))
		print("( ( " .. str(RAND1) .. " * " .. str(RAND4) .. " ) + ( " .. str(RAND2) .. " * " .. str(RAND3) .. " ) ) / ( " .. str(RAND3) .. " * " .. str(RAND4) .. " ) = " .. str(result13_2))
		print(">>> the distributivity margin is " .. (result13_1 - result13_2))
		assert(math.abs(result13_1 - result13_2) < 15)
		print("Good")
		
		print("Test: comparison with native Lua division")
		
		print("Attempting: 2048 random pairs")
		local r14_result_largest_error = 0
		local r14_result_errormost_val_a, r14_result_errormost_val_b
		for i = 1,2048 do
			local r14RANDi_a = math.fmod(fix:genRand(randfn), fix.OVERFLOW_VAL)
			local r14RANDi_b = math.fmod(fix:genRand(randfn), fix.OVERFLOW_VAL)
			
			local r14_result_1 = fix:div(r14RANDi_a, r14RANDi_b) / ONE
			local r14_result_2 = r14RANDi_a / r14RANDi_b
			local r14_result_err = math.abs(r14_result_1 - r14_result_2)
			if r14_result_largest_error < r14_result_err then
				r14_result_largest_error = r14_result_err
				r14_result_errormost_val_a = r14RANDi_a
				r14_result_errormost_val_b = r14RANDi_b
			end
		end
		print(">>> the largest error is " .. r14_result_largest_error)
		print(">>> the expression producing the error is div( " .. str(r14_result_errormost_val_a) .. " , " .. str(r14_result_errormost_val_b) .. " ) = "
		.. str(fix:div(r14_result_errormost_val_a, r14_result_errormost_val_b)))
		assert(r14_result_largest_error < 1e-3)
		print("Good")
	end,
	Exponential = function()
		local fix = FixedPoint:new(test_radius, 6, drp)
		print("Fixed point context: " .. fix:describe())
		
		local ZERO = 0
		local ONE = fix:convertInt(1)
		local TWO = fix:convertInt(2)
		local HALF = fix:asValue(0, 5e5)
		local SQRT2 = fix.CONSTANT.SQRT2
		local INV_SQRT2 = fix:asValue(0, 707107)
		local INV_SQRT2_SCALED = fix:asValue(70710678, 118655)
		local TENTH = ONE / 10
		local THREE = fix:convertInt(3)
		local THREE_TENTHS = 3 * TENTH
		local TEN = 10 * ONE
		local FIVE = 5 * ONE
		
		local E = fix.CONSTANT.E
		local INT_RAND = (1 + fix:genRand(randfn) % 25) * fix.RADIX_RHS_VAL
		local INT_RAND_SQ = fix:mult(INT_RAND, INT_RAND)
		
		local function str(v)
			return fix:toString(v)
		end
		
		print("Test: basic sqrt properties")
		
		print("Attempting: square root of 0")
		local result_1 = fix:sqrt(ZERO)
		print("sqrt( " .. str(ZERO) .. " ) = " .. str(result_1))
		assert(result_1 == 0)
		print("Good")
		
		print("Attempting: square root of one")
		local result_2 = fix:sqrt(fix.RADIX_RHS_VAL)
		print("sqrt( " .. str(fix.RADIX_RHS_VAL) .. " ) = " .. str(result_2))
		assert(result_2 == fix.RADIX_RHS_VAL)
		print("Good")
		
		print("Attempting: square root of a random square")
		local result_3 = fix:sqrt(INT_RAND_SQ)
		print("sqrt( " .. str(INT_RAND_SQ) .. " ) = " .. str(result_3))
		assert(math.abs(result_3 - INT_RAND) < 400)
		print("Good")
		
		print("Attempting: square root of a negative value")
		local result_4 = fix:sqrt(-INT_RAND_SQ)
		print("sqrt( " .. str(-INT_RAND_SQ) .. ") = " .. str(result_4))
		assert(result_4 ~= result_4)
		print("Good")
		
		print("Attempting: square root of largest value")
		local result_5 = fix:sqrt(fix.OVERFLOW_VAL - 1)
		print("sqrt( " .. str(fix.OVERFLOW_VAL - 1) .. " ) = " .. str(result_5))
		-- test to see if result of re-squaring the root yields result with error within threshold of RADIX_RHS_VAL aka 1
		assert(math.abs(fix:mult(result_5, result_5) - (fix.OVERFLOW_VAL - 1)) < fix.RADIX_RHS_VAL)
		print("Good")
		
		print("Attempting: square root of tenth of largest value")
		local result_6 = fix:sqrt(fix.OVERFLOW_VAL / 10)
		print("sqrt( " .. str(fix.OVERFLOW_VAL / 10) .. " ) = " .. str(result_6))
		assert(math.abs(fix:mult(result_6, result_6) - (fix.OVERFLOW_VAL / 10)) < fix.RADIX_RHS_VAL)
		print("Good")
		
		print("Attempting: square root of 1024 completely random integer values")
		local result_7_largest_error = 0
		local result_7_errormost_val
		for i = 1,1024 do
			local RANDi = fix:round(fix:genRand(randfn) % fix.OVERFLOW_VAL)
			
			local result_7i = fix:sqrt(RANDi)
			local result_7i_SQERR = math.abs(fix:mult(result_7i, result_7i) - RANDi)
			if (result_7i_SQERR > result_7_largest_error) then
				result_7_largest_error = result_7i_SQERR
				result_7_errormost_val = RANDi
			end
		end
		print(">>> the largest SQRT error is ".. str(result_7_largest_error))
		print(">>> the value producing it is sqrt( " .. str(result_7_errormost_val) .. " ) = " .. str(fix:sqrt(result_7_errormost_val)))
		assert(result_7_largest_error < fix.RADIX_RHS_VAL)
		print("Good")
		
		print("Attempting: square root of 1024 completely random fractional values")
		print("NOTE: error is magnified as squares become small, so that it gets proper representation!")
		local result_8_largest_error = 0
		local result_8_errormost_val
		for i = 1,1024 do
			local RANDi = fix:genRand(randfn) % fix.RADIX_RHS_VAL
			
			local result_8i = fix:sqrt(RANDi)
			local result_8i_SQERR_MAGNIFIED = fix:div(math.abs(fix:mult(result_8i, result_8i) - RANDi), RANDi)
			if result_8i_SQERR_MAGNIFIED > result_8_largest_error then
				result_8_largest_error = result_8i_SQERR_MAGNIFIED
				result_8_errormost_val = RANDi
			end
		end
		print(">>> the largest SQRT error, magnified, is " .. str(result_8_largest_error))
		print(">>> the value producing it is sqrt(" .. str(result_8_errormost_val) .. " ) = " .. str(fix:sqrt(result_8_errormost_val)))
		assert(result_8_largest_error < fix.RADIX_RHS_VAL)
		print("Good")
		
		print("Attempting: square root of 2 almost equals fix.CONSTANT.SQRT2")
		local result_8B = fix:sqrt(TWO)
		local result_8B_err = math.abs(SQRT2 - result_8B)
		print("sqrt( " .. str(TWO) .. " ) = " .. str(result_8B))
		print(">>> the error is " .. str(result_8B_err))
		assert(result_8B_err < 5)
		print("Good")
		
		print("Test: binary exponential")
		
		print("Attempting: ldexp(nil, 0) equals 2^0 (equals one)")
		local result_9 = fix:ldexp(nil, 0)
		print("ldexp( nil , " .. str(0) .." ) = " .. str(result_9))
		assert(result_9 == fix.RADIX_RHS_VAL)
		print("Good")
		
		print("Attempting: ldexp(nil, 1) equals 2^1 (equals two)")
		local result_10 = fix:ldexp(nil, fix.RADIX_RHS_VAL)
		print("ldexp( nil , " .. str(fix.RADIX_RHS_VAL) .. " ) = " .. str(result_10))
		assert(result_10 == 2 * fix.RADIX_RHS_VAL)
		print("Good")
		
		print("Attempting: ldexp(nil, HALF) almost equals fix.CONSTANT.SQRT2")
		local result_11 = fix:ldexp(nil, HALF)
		local result_11_err = math.abs(SQRT2 - result_11)
		print("ldexp( nil, " .. str(HALF) .. " ) = " .. str(result_11))
		print(">>> the error is " .. str(result_11_err))
		assert(result_11_err < fix:asValue(0, 000010))
		print("Good")
		
		print("Attempting: ldexp(nil, -HALF) almost equals reciprocal fix.CONSTANT.SQRT2")
		local result_12 = fix:ldexp(nil, -HALF)
		local result_12_err = math.abs(INV_SQRT2 - result_12)
		print("ldexp( nil , " .. str(-HALF) .. " ) = " .. str(result_12))
		print(">>> the error is " .. str(result_12_err))
		assert(result_12_err < fix:asValue(0, 000010))
		print("Good")
		
		print("Attempting: multiplying ldexp(nil, TENTH) ten times somewhat equals two")
		local result_13_1 = fix:ldexp(nil, ONE / 10)
		local result_13_2 = result_13_1
		for i = 1,9 do
			result_13_2 = fix:mult(result_13_2, result_13_1)
		end
		local result_13_err = math.abs(result_13_2 - TWO)
		print("ldexp( nil , " .. str(ONE / 10) .. " ) = " .. str(result_13_1))
		print(">>> the result of multiplying tenfold is " .. str(result_13_2))
		print(">>> the error is " .. str(result_13_err))
		assert(result_13_err <= fix:asValue(0, 600000))
		print("Good")
		
		print("Attempting: three square roots of ldexp(nil, x) = ldexp(nil, x / 8 ) where x is random in [8, 24]")
		local r14RAND = 8 * ONE + (fix:genRand(randfn) % (16 * ONE))
		local result_14_1 = fix:ldexp(nil, r14RAND)
		local result_14_2 = fix:ldexp(nil, fix:div(r14RAND, 8 * ONE))
		local result_14_3 = fix:sqrt(fix:sqrt(fix:sqrt(result_14_1)))
		local result_14_err = math.abs(result_14_2 - result_14_3)
		print("ldexp( nil , " .. str(r14RAND) .. " ) = " .. str(result_14_1))
		print(">>> the result of three square roots is " .. str(result_14_3))
		print("ldexp( nil , " .. str(fix:div(r14RAND, 8 * ONE)) .. " ) = " .. str(result_14_2))
		print(">>> the error is " .. str(result_14_err))
		assert(result_14_err < fix:asValue(0, 100000))
		print("Good")
		
		print("Test: binary logarithm lg")
		
		print("Attempting: lg(1) == 0")
		local result_15 = fix:lg(ONE)
		print("lg( " .. str(ONE) .. " ) = " .. str(result_15))
		assert(result_15 == 0)
		print("Good")
		
		print("Attempting: lg(0) == -inf")
		local result_16 = fix:lg(0)
		print("lg( " .. str(0) .. " ) = " .. result_16)
		assert(result_16 == -math.huge)
		print("Good")
		
		print("Attempting: lg(x) is nan if x is negative")
		local r17RAND = -(1 + fix:genRand(randfn) % (fix.OVERFLOW_VAL - 1))
		local result_17 = fix:lg(r17RAND)
		print("lg( " .. str(r17RAND) .. " ) = " .. result_17)
		assert(result_17 ~= result_17)
		print("Good")
		
		print("Attempting: lg(HALF) == -1")
		local result_18 = fix:lg(HALF)
		print("lg( " .. str(HALF) .. " ) = " .. str(result_18))
		assert(result_18 == -ONE)
		print("Good")
		
		print("Attempting: lg(TENTH) is about -3.321928")
		local result_19 = fix:lg(ONE / 10)
		local result_19_err = math.abs(result_19 + fix:asValue(3, 321928))
		print("lg( " .. str(ONE / 10) .. " ) = " .. str(result_19))
		print(">>> the error is " .. str(result_19_err))
		assert(result_19_err < 500)
		print("Good")
		
		print("Attempting: lg(TENTH) + lg(THREE) == lg(THREE_TENTHS)")
		local result_20_1 = fix:lg(TENTH)
		local result_20_2 = fix:lg(THREE)
		local result_20_3 = fix:lg(THREE_TENTHS)
		local result_20_4 = result_20_1 + result_20_2
		local result_20_err = math.abs(result_20_4 - result_20_3)
		print("lg( " .. str(TENTH) .. " ) + lg( " .. str(THREE) .. " ) = " .. str(result_20_4))
		print("lg( " .. str(THREE_TENTHS) .. " ) = " .. str(result_20_3))
		print(">>> the error is " .. str(result_20_err))
		assert(result_20_err < fix:asValue(0, 000050))
		print("Good")
		
		print("Attempting: compare lg( x ) of 1024 random whole number values with Lua math.log( x , 2 )")
		local result_21_largest_error = 0
		local result_21_errormost_val
		for i = 1,1024 do
			local RANDi = fix:round((fix:genRand(randfn) + 1) % (fix.OVERFLOW_VAL - 1), "NEXT_INT")
			
			local result_21i = fix:lg(RANDi)
			local result_21i_2 = math.log(RANDi / fix.RADIX_RHS_VAL, 2)
			local result_21i_err = math.abs(result_21i / fix.RADIX_RHS_VAL - result_21i_2)
			if result_21i_err > result_21_largest_error then
				result_21_largest_error = result_21i_err
				result_21_errormost_val = RANDi
			end
		end
		print(">>> the largest error is " .. result_21_largest_error)
		print(">>> the value that produced it is lg( " .. str(result_21_errormost_val) .. " ) = " .. str(fix:lg(result_21_errormost_val)))
		assert(result_21_largest_error < 1e-3)
		print("Good")
		
		print("Attempting: compare lg( x ) of 1024 random values where HALF < x < TWO with Lua math.log( x , 2 )")
		local result_22_largest_error = 0
		local result_22_errormost_val
		for i = 1,1024 do
			local RANDi = HALF + (1 + fix:genRand(randfn)) % (TWO - HALF - 1)
			
			local result_22i = fix:lg(RANDi)
			local result_22i_2 = math.log(RANDi / ONE, 2)
			local result_22i_err = math.abs(result_22i / ONE - result_22i_2)
			if result_22i_err > result_22_largest_error then
				result_22_largest_error = result_22i_err
				result_22_errormost_val = RANDi
			end
		end
		print(">>> the largest error is " .. result_22_largest_error)
		print(">>> the value that produced it is lg( " .. str(result_22_errormost_val) .. " ) = " .. str(fix:lg(result_22_errormost_val)))
		assert(result_22_largest_error < 1e-3)
		print("Good")
		
		print("Test: arbitrary exponentiation")
		
		print("Attempting: pow(1, x) where x is random")
		local r23RAND = math.fmod(fix:genRand(randfn), fix.OVERFLOW_VAL)
		local result_23 = fix:pow(ONE, r23RAND)
		print("pow( " .. str(ONE) .. " , " .. str(r23RAND) .. " ) = " .. str(result_23))
		assert(result_23 == ONE)
		print("Good")
		
		print("Attempting: pow(x, y) == x^y (where x^y is native Lua exponentiation), for random integers 2 <= abs(x) <= 8, 2 < abs(y) <= 8. (4 checks)")
		for i = 1, 4 do
			local r23RANDi_X = fix:round(TWO + (fix:genRand(randfn) % (THREE * 2))) * (randfn2(0, 1) == 1 and -1 or 1)
			local r23RANDi_Y = fix:round(TWO + (fix:genRand(randfn) % (THREE * 2))) * (randfn2(0, 1) == 1 and -1 or 1)
			local result_23i_1 = fix:pow(r23RANDi_X, r23RANDi_Y)
			
			local r23RiX_int = r23RANDi_X / ONE
			local r23RiY_int = r23RANDi_Y / ONE
			FixedPoint.assert_int("X_"..i, r23RiX_int)
			FixedPoint.assert_int("Y_"..i, r23RiY_int)
			local result_23i_2 = r23RiX_int ^ r23RiY_int
			
			print("i)  pow( " .. str(r23RANDi_X) .. " , " .. str(r23RANDi_Y) .. " ) = " .. str(result_23i_1))
			print("ii) " .. r23RiX_int .. " ^ " .. r23RiY_int .. " = " .. result_23i_2)
			assert(math.abs(result_23i_1 / ONE - result_23i_2) < 2e-6)
		end
		print("Good")
		
		print("Attempting: pow(x, y) is about x^y (native Lua exponentiation), for random fractions 1 <= x < 8, 1 <= y < 8. (1024 checks)")
		local result_24_largest_error = 0
		local result_24_errormost_val_X, result_24_errormost_val_Y
		for i = 1, 1024 do
			local r24RANDi_X = (ONE + (fix:genRand(randfn) % (THREE * 2 + ONE)))
			local r24RANDi_Y = (ONE + (fix:genRand(randfn) % (THREE * 2 + ONE)))
			local result_24i_1 = fix:pow(r24RANDi_X, r24RANDi_Y)
			
			local r24RiX_double = r24RANDi_X / ONE
			local r24RiY_double = r24RANDi_Y / ONE
			local result_24i_2 = r24RiX_double ^ r24RiY_double
			
			local result_24i_err = math.abs(result_24i_1 / ONE - result_24i_2)
			if result_24i_err > result_24_largest_error then
				result_24_largest_error = result_24i_err
				result_24_errormost_val_X = r24RANDi_X
				result_24_errormost_val_Y = r24RANDi_Y
			end
		end
		print(">>> the largest error is " .. result_24_largest_error)
		print(">>> the pair that produced it is pow( " .. str(result_24_errormost_val_X) .. " , " .. str(result_24_errormost_val_Y) .. " ) = "
		.. str(fix:pow(result_24_errormost_val_X, result_24_errormost_val_Y)))
		assert(math.abs(result_24_largest_error / ((result_24_errormost_val_X / ONE)^(result_24_errormost_val_Y / ONE))) < 1e-4)
		print("Good")
		
		print("Attempting: last test but with -1 >= y > -8")
		local result_25_largest_error = 0
		local result_25_errormost_val_X, result_25_errormost_val_Y
		for i = 1, 1024 do
			local r25RANDi_X = (ONE + (fix:genRand(randfn) % (THREE * 2 + ONE)))
			local r25RANDi_Y = -(ONE + (fix:genRand(randfn) % (THREE * 2 + ONE)))
			local result_25i_1 = fix:pow(r25RANDi_X, r25RANDi_Y)
			
			local r25RiX_double = r25RANDi_X / ONE
			local r25RiY_double = r25RANDi_Y / ONE
			local result_25i_2 = r25RiX_double ^ r25RiY_double
			
			local result_25i_err = math.abs(result_25i_1 / ONE - result_25i_2)
			if result_25i_err > result_25_largest_error then
				result_25_largest_error = result_25i_err
				result_25_errormost_val_X = r25RANDi_X
				result_25_errormost_val_Y = r25RANDi_Y
			end
		end
		print(">>> the largest error is " .. result_25_largest_error)
		print(">>> the pair that produced it is pow( " .. str(result_25_errormost_val_X) .. " , " .. str(result_25_errormost_val_Y) .. " ) = "
		.. str(fix:pow(result_25_errormost_val_X, result_25_errormost_val_Y)))
		assert(math.abs(result_25_largest_error / ((result_25_errormost_val_X / ONE)^(result_25_errormost_val_Y / ONE))) < 1e-4)
		print("Good")
		
		print("Test: hypotenuse")
		
		print("Attempting: hypotenuse of 1024 random fixed point value pairs, -" .. str(INV_SQRT2_SCALED) .. " < x, y < " .. str(INV_SQRT2_SCALED))
		local result_26_largest_error = 0
		local result_26_errscale = 0
		local result_26_errormost_val_X, result_26_errormost_val_Y
		for i = 1,1024 do
			local r26RANDi_X = math.fmod(fix:genRand(randfn), INV_SQRT2_SCALED)
			local r26RANDi_Y = math.fmod(fix:genRand(randfn), INV_SQRT2_SCALED)
			local result_26i_1 = fix:hypot(r26RANDi_X, r26RANDi_Y)
			
			local result26i_2 = 0
			local x = math.abs(r26RANDi_X / ONE)
			local y = math.abs(r26RANDi_Y / ONE)
			
			local yx = 0
			
			if x < y then
				local temp = y
				y = x
				x = temp
			end
			
			if x ~= 0 then
				yx = y / x
				result26i_2 = x * math.sqrt(1 + yx * yx)
			end
			
			local result26i_err = math.abs(result26i_2 - result_26i_1 / ONE)
			
			if result26i_err > result_26_largest_error then
				result_26_largest_error = result26i_err
				result_26_errormost_val_X = r26RANDi_X
				result_26_errormost_val_Y = r26RANDi_Y
				result_26_errscale = math.sqrt(result26i_2)
			end
		end
		print(">>> the largest error is " .. result_26_largest_error)
		print(">>> the expression producing the error is hypot( " .. str(result_26_errormost_val_X) .. " , " .. str(result_26_errormost_val_Y) .. " ) = "
			.. str(fix:hypot(result_26_errormost_val_X, result_26_errormost_val_Y))
		)
		assert(result_26_largest_error / result_26_errscale < 1)
		print("Good")
	end,
	Trigonometry = function()
		local fix2 = FixedPoint:new(test_radius, 2, drp)
		local fix6 = FixedPoint:new(test_radius, 6, drp)
		print("TWO Fixed point contexts, default radius but one has radix point 2 and the other 6. Default rounding policy.")
		
		local ZERO = 0
		
		local PI2 = fix2.CONSTANT.PI
		local HALFPI2 = fix2:div(PI2, fix2:convertInt(2))
		local HALF3PI2 = HALFPI2 * 3
		local TAU2 = fix2.CONSTANT.TAU
		local DEGR2 = fix2.CONSTANT.DEGR
		local DEGH2 = fix2.CONSTANT.DEGR / 2
		local RAND1_2 = fix2:genRand(randfn) % fix2.CONSTANT.TAU
		
		local PI6 = fix6.CONSTANT.PI
		local TAU6 = fix6.CONSTANT.TAU
		local HALFPI6 = fix6:div(TAU6, fix6:convertInt(4))
		local HALF3PI6 = fix6:mult(TAU6, 750000)
		local DEGR6 = fix6.CONSTANT.DEGR
		local DEGH6 = fix6.CONSTANT.DEGR / 2
		local RAND1_6 = fix6:genRand(randfn) % fix6.CONSTANT.TAU
		
		local function str2(v)
			return fix2:toString(v)
		end
		
		local function str6(v)
			return fix6:toString(v)
		end
		
		print("Test: convert TAU (2PI) rad to deg")
		
		print("Attempting: RADIX POINT 2")
		local result1 = fix2:deg(TAU2)
		print("deg( " .. str2(TAU2) .. " ) = " .. str2(result1))
		assert(result1 == 0)
		print("Good")
		
		print("Attempting: RADIX POINT 6")
		local result2 = fix6:deg(TAU6)
		print("deg( " .. str6(TAU6) .. " ) = " .. str6(result2))
		assert(result2 == 0)
		print("Good")
		
		print("Test: convert PI rad to deg")
		
		print("Attempting: RADIX POINT 2")
		local result3 = fix2:deg(PI2)
		print("deg( " .. str2(PI2) .. " ) = " .. str2(result3))
		assert(result3 == DEGH2)
		print("Good")
		
		print("Attempting: RADIX POINT 6")
		local result4 = fix6:deg(PI6)
		print("deg(  " .. str6(PI6) .. " ) = " .. str6(result4))
		assert(result4 == DEGH6)
		print("Good")
		
		print("Test: convert 360 deg to rad")
		
		print("Attempting: RADIX POINT 2")
		local result5 = fix2:rad(DEGR2)
		print("rad( " .. str2(DEGR2) .. " ) = " .. str2(result5))
		assert(result5 == 0)
		print("Good")
		
		print("Attempting: RADIX POINT 6")
		local result6 = fix6:rad(DEGR6)
		print("rad( " .. str6(DEGR6) .. " ) = " .. str6(result6))
		assert(result6 == 0)
		print("Good")
		
		print("Test: convert 180 deg to rad")
		
		print("Attempting: RADIX POINT 2")
		local result7 = fix2:rad(DEGH2)
		print("rad( " .. str2(DEGH2) .. " ) = " .. str2(result7))
		assert(result7 == PI2)
		print("Good")
		
		print("Attempting: RADIX POINT 6")
		local result8 = fix6:rad(DEGH6)
		print("rad( " .. str6(DEGH6) .. " ) = " .. str6(result8))
		assert(result8 == PI6)
		print("Good")
		
		print("Test: periodic trig correctness (cosine)")
		
		print("SECTION I: RADIX 2")
		
		print("Attempting: cosine of pi and zero")
		local result9_1 = fix2:cos(PI2)
		local result9_2 = fix2:cos(0)
		print("cos( " .. str2(PI2) .. " ) = " .. str2(result9_1))
		print("cos( " .. str2(0) .. " ) = " .. str2(result9_2))
		assert(result9_1 == -fix2.RADIX_RHS_VAL)
		assert(result9_2 == fix2.RADIX_RHS_VAL)
		print("Good")
		
		print("Attempting: cosine of half pi and three halves pi")
		local result10_1 = fix2:cos(HALFPI2)
		local result10_2 = fix2:cos(HALF3PI2)
		print("cos( " .. str2(HALFPI2) .. " ) = " .. str2(result10_1))
		print("cos( " .. str2(HALF3PI2) .. " ) = " .. str2(result10_2))
		assert(result10_1 == 0)
		assert(result10_2 == 0)
		print("OK")
		
		print("Attempting: cosine of random radian value equals cosine of same value plus tau")
		local result11_1 = fix2:cos(RAND1_2)
		local result11_2 = fix2:cos(RAND1_2 + fix2.CONSTANT.TAU)
		print("cos( " .. str2(RAND1_2) .. " ) = " .. str2(result11_1))
		print("cos( " .. str2(RAND1_2 + fix2.CONSTANT.TAU) .. " ) = " .. str2(result11_2))
		assert(result11_1 == result11_2)
		print("Good")
		
		print("Attempting: math.cos as control to determine and enforce precision of FixedPoint#cos")
		print("NOTE: math.cos argument will be a double! MAX displacement will be calculated with a sample of 1024 rands.")
		local result12_disp = 0
		for i = 1, 1024 do
			local r12RANDi_2 = fix2:genRand(randfn) % fix2.CONSTANT.TAU
			local result12_i = fix2:cos(r12RANDi_2)
			local result12b_i = math.cos(r12RANDi_2 / fix2.RADIX_RHS_VAL)
			
			local result12c_i = math.abs((result12_i / fix2.RADIX_RHS_VAL) - result12b_i)
			if result12_disp < result12c_i then
				print(result12c_i .. " at value " .. str2(r12RANDi_2))
				
				assert(math.abs(result12c_i) < 0.057)
				result12_disp = result12c_i
			end
		end
		print("Largest displacement is acceptable ( " .. result12_disp .. " < 0.057 )")
		print("Good")
		
		print("Attempting: sine of zero and pi")
		
		local result17_1 = fix2:sin(0)
		local result17_2 = fix2:sin(PI2)
		print("sin( " .. str2(0) .. " ) = " .. str2(result17_1))
		print("sin( " .. str2(PI2) .. " ) = " .. str2(result17_2))
		assert(result17_1 == 0)
		assert(result17_2 == 0)
		print("Good")
		
		print("Attempting: sine of half pi and three halves pi")
		
		local result18_1 = fix2:sin(HALFPI2)
		local result18_2 = fix2:sin(HALF3PI2)
		print("sin( " .. str2(HALFPI2) .. " ) = " .. str2(result18_1))
		print("sin( " .. str2(HALF3PI2) .. " ) = " .. str2(result18_2))
		assert(result18_1 == fix2.RADIX_RHS_VAL)
		assert(result18_2 == -fix2.RADIX_RHS_VAL)
		print("Good")
		
		print("SECTION II: RADIX 6")
		
		print("Attempting: cosine of pi and zero")
		local result13_1 = fix6:cos(PI6)
		local result13_2 = fix6:cos(ZERO)
		print("cos( " .. str6(PI6) .. " ) = " .. str6(result13_1))
		print("cos( " .. str6(ZERO) .. " ) = " .. str6(result13_2))
		assert(result13_1 == -fix6.RADIX_RHS_VAL)
		assert(result13_2 == fix6.RADIX_RHS_VAL)
		print("Good")
		
		print("Attempting: cosine of half pi and three halves pi")
		local result14_1 = fix6:cos(HALFPI6)
		local result14_2 = fix6:cos(HALF3PI6)
		print("cos( " .. str6(HALFPI6) .. " ) = " ..str6(result14_1))
		print("cos( " .. str6(HALF3PI6) .. " ) = " .. str6(result14_2))
		assert(result14_1 == 0)
		assert(result14_2 == 0)
		print("Good")
		
		print("Attempting: cosine of random radian value equals cosine of same value plus tau")
		local result15_1 = fix6:cos(RAND1_6)
		local result15_2 = fix6:cos(RAND1_6 + fix6.CONSTANT.TAU)
		print("cos ( " .. str6(RAND1_6) .. " ) = " .. str6(result15_1))
		print("cos ( " .. str6(RAND1_6 + fix6.CONSTANT.TAU) .. " ) = " .. str6(result15_2))
		assert(result15_1 == result15_2)
		print("Good")
		
		print("Attempting: math.cos as control to determine and enforce precision of FixedPoint#cos")
		print("NOTE: math.cos argument will be a double! MAX displacement will be calculated with a sample of 1024 rands.")
		local result16_disp = 0
		for i = 1, 1024 do
			local r16RANDi_6 = fix6:genRand(randfn) % fix6.CONSTANT.TAU
			local result16_i = fix6:cos(r16RANDi_6)
			local result16b_i = math.cos(r16RANDi_6 / fix6.RADIX_RHS_VAL)
			
			local result16c_i = math.abs((result16_i / fix6.RADIX_RHS_VAL) - result16b_i)
			if result16_disp < result16c_i then
				print(result16c_i .. " at value " .. str6(r16RANDi_6))
				
				assert(math.abs(result16c_i) < 0.057)
				result16_disp = result16c_i
			end
		end
		print("Largest displacement is acceptable ( " .. result16_disp .. " < 0.057 )")
		print("Good")
		
		print("Attempting: sine of zero and pi")
		local result19_1 = fix6:sin(0)
		local result19_2 = fix6:sin(PI6)
		print("sin( " .. str6(0) .. " ) = " .. str6(result19_1))
		print("sin( " .. str6(PI6) .. " ) = " .. str6(result19_2))
		assert(result19_1 == 0)
		assert(result19_2 == 0)
		print("Good")
		
		print("Attempting: sine of half pi and three halves pi")
		local result20_1 = fix6:sin(HALFPI6)
		local result20_2 = fix6:sin(HALF3PI6)
		print("sin( " .. str6(HALFPI6) .. " ) = " .. str6(result20_1))
		print("sin( " .. str6(HALF3PI6) .. " ) = " .. str6(result20_2))
		assert(result20_1 == fix6.RADIX_RHS_VAL)
		assert(result20_2 == -fix6.RADIX_RHS_VAL)
		print("Good")
		
		local fix = fix6
		local str = str6
		local PI = PI6
		local HALFPI = HALFPI6
		local HALF3PI = HALF3PI6
		local TAU = TAU6
		local DEGR = DEGR6
		local DEGH = DEGH6
		
		print("Test: trig identity using 1024 different random value pairs each test, HALF_TO_EVEN in mult (radix 6)")
		
		print("Attempting: sum identity cos(a + b) = cos(a)cos(b) - sin(a)sin(b)")
		
		local result21_disp = 0
		for i = 1, 1024 do
			local RAND1, RAND2 = fix:genRand(randfn) % TAU, fix:genRand(randfn) % TAU
			local COS_RAND1 = fix:cos(RAND1)
			local COS_RAND2 = fix:cos(RAND2)
			local SIN_RAND1 = fix:sin(RAND1)
			local SIN_RAND2 = fix:sin(RAND2)
			
			local result21_a = fix:cos(RAND1 + RAND2)
			local result21_b = fix:mult(COS_RAND1, COS_RAND2) - fix:mult(SIN_RAND1, SIN_RAND2)
			local result21_c = math.abs(result21_a - result21_b)
			
			-- print("cos( " .. str(RAND1 + RAND2) .. " ) = " .. str(result21_a))
			-- print("cos( " .. str(RAND1) .. " )cos( ".. str(RAND2) .. " ) - sin( " .. str(RAND1) .. " )sin( " .. str(RAND2) .. " ) = " .. str(result21_b))
			-- print(">>> the margin of error for this identity is " .. (result21_a - result21_b))
			if result21_disp < result21_c then
				result21_disp = result21_c
			end
		end
		print(">>> MAX margin of error for this identity is " .. str(result21_disp))
		assert(result21_disp < 100)
		print("Good")
		
		print("Test: inverse trig")
		
		print("SECTION I: RADIX 2")
		
		print("Attempting: arctangent of zero")
		local result22_1 = fix2:atan(0)
		local result22_2 = fix2:atan2(0, RAND1_2 + 1)
		print("atan( " .. str2(0) .. " ) = " .. str2(result22_1))
		print("atan2( " .. str2(0) .. ", " .. str2(RAND1_2 + 1) .. " ) = " .. str2(result22_2))
		assert(result22_1 == 0)
		assert(result22_2 == 0)
		print("Good")
		
		print("Attempting: arctangent of one and negative one")
		local result23_1 = fix2:atan(fix2.RADIX_RHS_VAL)
		local result23_2 = fix2:atan(-fix2.RADIX_RHS_VAL)
		print("atan( " .. str2(fix2.RADIX_RHS_VAL) .. " ) = " .. str2(result23_1))
		print("atan( " .. str2(-fix2.RADIX_RHS_VAL) .. " ) = " .. str2(result23_2))
		assert(math.abs(result23_1 - fix2.CONSTANT.FOURTHPI) < 4)
		assert(math.abs(result23_2 + fix2.CONSTANT.FOURTHPI) < 4)
		print("Good")
		
		print("Attempting: arctangent of max value and negative max value")
		local result24_1 = fix2:atan(fix2.OVERFLOW_VAL - 1)
		local result24_2 = fix2:atan(-fix2.OVERFLOW_VAL + 1)
		print("atan( " .. str2(fix2.OVERFLOW_VAL - 1) .. " ) = " .. str2(result24_1))
		print("atan( " .. str2(-fix2.OVERFLOW_VAL + 1) .. " ) = " .. str2(result24_2))
		assert(math.abs(result24_1 - fix2.CONSTANT.HALFPI) < 4)
		assert(math.abs(result24_2 + fix2.CONSTANT.HALFPI) < 4)
		print("Good")
		
		print("SECTION II: RADIX 6")
		
		print("Attempting: arctangent of zero")
		local result25_1 = fix:atan(0)
		local result25_2 = fix:atan2(0, RAND1_6 + 1)
		print("atan( " .. str(0) .. " ) = " .. str(result25_1))
		print("atan2( " .. str(0) .. ", " .. str2(RAND1_6 + 1) .. " ) = " .. str(result25_2))
		assert(result25_1 == 0)
		assert(result25_2 == 0)
		print("Good")
		
		print("Attempting: arctangent of one and negative one")
		local result26_1 = fix:atan(fix.RADIX_RHS_VAL)
		local result26_2 = fix:atan(-fix.RADIX_RHS_VAL)
		print("atan( " .. str(fix.RADIX_RHS_VAL) .. " ) = " .. str(result26_1))
		print("atan( " .. str(-fix.RADIX_RHS_VAL) .. " ) = " .. str(result26_2))
		assert(math.abs(result26_1 - fix.CONSTANT.FOURTHPI) < 400)
		assert(math.abs(result26_2 + fix.CONSTANT.FOURTHPI) < 400)
		print("Good")
		
		print("Attempting: arctangent of max value and negative max value")
		local result27_1 = fix:atan(fix.OVERFLOW_VAL - 1)
		local result27_2 = fix:atan(-fix.OVERFLOW_VAL + 1)
		print("atan( " .. str(fix.OVERFLOW_VAL - 1) .. " ) = " .. str(result27_1))
		print("atan( " .. str(-fix.OVERFLOW_VAL + 1) .. " ) = " .. str(result27_2))
		assert(math.abs(result27_1 - fix.CONSTANT.HALFPI) < 400)
		assert(math.abs(result27_2 + fix.CONSTANT.HALFPI) < 400)
		print("Good")
		
		print("Attempting: comparison of FixedPoint#atan2 and native math.atan2, using 1024 random input value pairs")
		local result28_largest_error = 0
		local result28_errormost_valY, result28_errormost_valX
		for i = 1,1024 do
			local r28RANDi_Y = (fix:genRand(randfn)) * (randfn2(0, 1) == 0 and 1 or -1)
			local r28RANDi_X = (fix:genRand(randfn)) * (randfn2(0, 1) == 0 and 1 or -1)
			
			local result28i_1 = fix:atan2(r28RANDi_Y, r28RANDi_X)
			local result28i_2 =  math.atan2(r28RANDi_Y, r28RANDi_X)
			
			local result28i_err = math.abs(result28i_1 / fix.RADIX_RHS_VAL - result28i_2)
			if result28i_err > result28_largest_error then
				result28_largest_error = result28i_err
				result28_errormost_valY = r28RANDi_Y
				result28_errormost_valX = r28RANDi_X
			end
		end
		print(">>> the largest error is " .. result28_largest_error)
		print(">>> the error was produced by the expression: atan2( " .. str(result28_errormost_valY) .. " , " .. str(result28_errormost_valX) .. " ) = "
			.. str(fix:atan2(result28_errormost_valY, result28_errormost_valX)))
		assert(result28_largest_error < 0.002)
		print("Good")
		
		print("Attempting: comparison of FixedPoint#acos with native math.acos, 1024 random input values")
		local result29_largest_error = 0
		local result29_errormost_val
		for i = 1,1024 do
			local r29RANDi = math.fmod(fix:genRand(randfn), fix.RADIX_RHS_VAL + 1)
			
			local result29i_1 = fix:acos(r29RANDi)
			local result29i_2 = math.acos(r29RANDi / fix.RADIX_RHS_VAL)
			
			local result29i_err = math.abs(result29i_1 / fix.RADIX_RHS_VAL - result29i_2)
			if result29i_err > result29_largest_error then
				result29_largest_error = result29i_err
				result29_errormost_val = r29RANDi
			end
		end
		print(">>> the largest error is " .. result29_largest_error)
		print(">>> the error was produced by the expression: acos( " .. str(result29_errormost_val) .. " ) = "
		.. str(fix:acos(result29_errormost_val)))
		assert(result29_largest_error < 0.002)
		print("Good")
		
		print("Attempting: comparison of FixedPoint#asin with native math.asin, 1024 random input values")
		local result30_largest_error = 0
		local result30_errormost_val
		for i = 1,1024 do
			local r30RANDi = math.fmod(fix:genRand(randfn), fix.RADIX_RHS_VAL + 1)
			
			local result30i_1 = fix:asin(r30RANDi)
			local result30i_2 = math.asin(r30RANDi / fix.RADIX_RHS_VAL)
			
			local result30i_err = math.abs(result30i_1 / fix.RADIX_RHS_VAL - result30i_2)
			if result30i_err > result30_largest_error then
				result30_largest_error = result30i_err
				result30_errormost_val = r30RANDi
			end
		end
		print(">>> the largest error is " .. result30_largest_error)
		print(">>> the error was produced by the expression: asin( " .. str(result30_errormost_val) .. " ) = "
		.. str(fix:asin(result30_errormost_val)))
		assert(result30_largest_error < 0.002)
		print("Good")
	end,
	Hyperbolic = function()
		local fix = FixedPoint:new(test_radius, 6, drp)
		fix:setRandFn(randfn)
	
		local ONE = fix.RADIX_RHS_VAL
		
		local function str(s)
			return fix:toString(s)
		end
		
		print("Test: hyperbolic function special cases")
		
		print("Attempting: sinh(0) == 0")
		local result1 = fix:sinh(0)
		print("sinh( " .. str(0) .. " ) = " .. str(result1))
		assert(result1 == 0)
		print("Good")
		
		print("Attempting: sinh(1) > 1")
		local result2 = fix:sinh(ONE)
		print("sinh( " .. str(ONE) .. " ) = " .. str(result2))
		assert(result2 > ONE)
		print("Good")
		
		print("Attempting: cosh(0) == 1")
		local result3 = fix:cosh(0)
		print("cosh( " .. str(0) .. " ) = " .. str(result3))
		assert(result3 == ONE)
		print("Good")
		
		print("Attempting: cosh(x) is (nearly) equal to cos(-x) for some -15 <= x <= 15 random")
		local r4RAND = math.fmod(fix:genRand(), 15 * ONE)
		local result4_1 = fix:cosh(r4RAND)
		local result4_2 = fix:cosh(-r4RAND)
		print("cosh( " .. str(r4RAND) .. " ) = " .. str(result4_1))
		print("cosh( " .. str(-r4RAND) .. " ) = " .. str(result4_2))
		assert(math.abs(result4_1 - result4_2) < 4)
		print("Good")
		
		print("Attempting: tanh(0) == 0")
		local result5 = fix:tanh(0)
		print("tanh( " .. str(0) .. " ) = " .. str(result5))
		assert(result5 == 0)
		print("Good")
		
		print("Attempting: tanh(10) is close to ONE, tanh(-10) is close to -ONE, tanh(-10) is almost -tanh(10)")
		local result6_1 = fix:tanh(10 * ONE)
		local result6_2 = fix:tanh(-10 * ONE)
		print("tanh( " .. str(10 * ONE) .. " ) = " .. str(result6_1))
		print("tanh( " .. str(-10 * ONE) .. " ) = " .. str(result6_2))
		assert(ONE - result6_1 < 10)
		assert(result6_2 + ONE < 10)
		assert(math.abs(result6_1 + result6_2) < 4)
		print("Good")
		
		print("Test: hyperbolic functions, Lua comparison")
		
		print("Attempting: sinh of 1024 random values")
		local result7_largest_error = 0
		local result7_errormost_val
		for i = 1, 1024 do
			local r7RANDi = math.fmod(fix:genRand(), 15 * ONE)
			
			local result7i_1 = fix:sinh(r7RANDi)
			local result7i_2 = math.sinh(r7RANDi / ONE)
			local result7i_err = math.abs((result7i_1 / ONE - result7i_2)) / math.sqrt(result7i_2)
			if result7i_err > result7_largest_error then
				result7_largest_error = result7i_err
				result7_errormost_val = r7RANDi
			end
		end
		print(">>> the largest error is " .. result7_largest_error)
		print(">>> the expression causing the error is: sinh( " .. str(result7_errormost_val) .. " ) = "
		.. str(fix:sinh(result7_errormost_val)))
		assert(result7_largest_error < 3e-3)
		print("Good")
		
		print("Attempting: cosh of 1024 random values")
		local result8_largest_error = 0
		local result8_errormost_val
		for i = 1, 1024 do
			local r8RANDi = math.fmod(fix:genRand(), 15 * ONE)
			
			local result8i_1 = fix:cosh(r8RANDi)
			local result8i_2 = math.cosh(r8RANDi / ONE)
			local result8i_err = math.abs((result8i_1 / ONE - result8i_2)) / math.sqrt(result8i_2)
			if result8i_err > result8_largest_error then
				result8_largest_error = result8i_err
				result8_errormost_val = r8RANDi
			end
		end
		print(">>> the largest error is " .. result8_largest_error)
		print(">>> the expression causing the error is: cosh( " .. str(result8_errormost_val) .. " ) = "
		.. str(fix:cosh(result8_errormost_val)))
		assert(result8_largest_error < 3e-3)
		print("Good")
		
		print("Attempting: tanh of 1024 random values")
		local result9_largest_error = 0
		local result9_errormost_val
		for i = 1, 1024 do
			local r9RANDi = math.fmod(fix:genRand(), 15 * ONE)
			
			local result9i_1 = fix:tanh(r9RANDi)
			local result9i_2 = math.tanh(r9RANDi / ONE)
			local result9i_err = math.abs((result9i_1 / ONE - result9i_2)) / math.sqrt(result9i_2)
			if result9i_err > result9_largest_error then
				result9_largest_error = result9i_err
				result9_errormost_val = r9RANDi
			end
		end
		print(">>> the largest error is " .. result9_largest_error)
		print(">>> the expression causing the error is: tanh( " .. str(result9_errormost_val) .. " ) = "
		.. str(fix:tanh(result9_errormost_val)))
		assert(result9_largest_error < 3e-3)
		print("Good")
	end
}

 FixedPointTest.Consistency()
 FixedPointTest.Addition()
 FixedPointTest.Subtraction()
FixedPointTest.Multiplication()
 FixedPointTest.Division()
 FixedPointTest.Exponential()
 FixedPointTest.Trigonometry()
 FixedPointTest.Hyperbolic()